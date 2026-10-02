package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.SubscriptionPaymentResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.Month;
import java.time.ZoneOffset;
import java.util.UUID;
import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Two simultaneous payments of the same subscription on a real PostgreSQL (KKS-444): the row of
 * the subscription is locked, so the second request waits for the first and returns its payment.
 * H2 does not reproduce row locks the same way, hence the container.
 */
@SpringBootTest
@Testcontainers
class SubscriptionPaymentConcurrencyIT {

    /** Fixed day: a test must not depend on the day it runs (KKS-355). */
    private static final LocalDate TODAY = LocalDate.of(2026, Month.OCTOBER, 2);

    /** Upper bound of the whole scenario and of each wait on a thread. */
    private static final long TIMEOUT_SECONDS = 30;

    /** How long the first reader of the period waits for a second one to have read too. */
    private static final long RENDEZVOUS_SECONDS = 2;

    /** Both requests that have read the payment of the period; see {@link TestBeans#widenTheRaceWindowAfterTheLookup}. */
    private static final CyclicBarrier bothHaveRead = new CyclicBarrier(2);

    /** Lookups intercepted: proves the race was really widened (a renamed lookup would make the test vacuous). */
    private static final AtomicInteger interceptedLookups = new AtomicInteger();

    @TestConfiguration
    static class TestBeans {
        @Bean
        @Primary
        Clock fixedClock() {
            return Clock.fixed(TODAY.atStartOfDay().toInstant(ZoneOffset.UTC), ZoneOffset.UTC);
        }

        /**
         * Makes the race deterministic. Right after each lookup of the payment of the period, the request waits,
         * for a bounded time, for another request to have read too: without a lock both read "no payment"
         * together and both create one. With the lock the second request is parked on the subscription row,
         * never shows up, and the wait of the first expires.
         */
        @Bean
        static BeanPostProcessor widenTheRaceWindowAfterTheLookup() {
            return new BeanPostProcessor() {
                @Override
                public Object postProcessAfterInitialization(Object bean, String beanName) {
                    if (!(bean instanceof TransactionRepository)) {
                        return bean;
                    }
                    return Proxy.newProxyInstance(
                            TransactionRepository.class.getClassLoader(),
                            new Class<?>[] {TransactionRepository.class},
                            (proxy, method, args) -> {
                                Object result = invoke(bean, method, args);
                                if (method.getName().equals("findBySubscriptionIdAndUserIdAndDateBetweenOrderByDateAscIdAsc")) {
                                    interceptedLookups.incrementAndGet();
                                    awaitTheOtherRequest();
                                }
                                return result;
                            });
                }
            };
        }

        private static Object invoke(Object target, Method method, Object[] args) throws Throwable {
            try {
                return method.invoke(target, args);
            } catch (InvocationTargetException e) {
                throw e.getCause();
            }
        }

        private static void awaitTheOtherRequest() throws InterruptedException {
            try {
                bothHaveRead.await(RENDEZVOUS_SECONDS, TimeUnit.SECONDS);
            } catch (TimeoutException | BrokenBarrierException e) {
                // The other request is blocked on the lock: the expected case once the lock exists.
            }
        }
    }

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("app.admin-emails", () -> "");
        // Without the "test" profile here: the property must be set by hand.
        registry.add("app.scheduling.enabled", () -> "false");
        registry.add("app.jwt.secret", () -> "test-secret-key-budget-app-min-256-bits-long-enough-for-hmac-sha");
    }

    @Autowired private SubscriptionPaymentService subscriptionPaymentService;
    @Autowired private UserRepository userRepository;
    @Autowired private AccountRepository accountRepository;
    @Autowired private SubscriptionRepository subscriptionRepository;
    @Autowired private TransactionRepository transactionRepository;

    @MockitoBean
    private BootstrapSeedRunner bootstrapSeedRunner;

    private User saveUser(String email) {
        return userRepository.saveAndFlush(User.builder().email(email).password("encoded").name("Payment IT").build());
    }

    private Subscription saveSubscription(User user) {
        Account account = accountRepository.saveAndFlush(Account.builder()
                .nom("Compte principal").type(AccountType.COURANT).soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#000000").actif(true).user(user).build());
        return subscriptionRepository.saveAndFlush(Subscription.builder()
                .nom("Streaming").montant(new BigDecimal("13.99")).frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2026, Month.JANUARY, 1)).actif(true).account(account).user(user).build());
    }

    @BeforeEach
    void resetTheRendezvous() {
        bothHaveRead.reset();
        interceptedLookups.set(0);
    }

    @Test
    void should_create_one_payment_and_return_it_twice_when_two_requests_pay_at_the_same_time() throws Exception {
        User user = saveUser("payment-concurrency-it@example.com");
        Subscription subscription = saveSubscription(user);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch go = new CountDownLatch(1);
        Callable<SubscriptionPaymentResponse> pay = () -> {
            ready.countDown();
            if (!go.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
                throw new TimeoutException("The start signal never came");
            }
            return subscriptionPaymentService.pay(subscription.getId(), user.getId());
        };

        SubscriptionPaymentResponse first;
        SubscriptionPaymentResponse second;
        try (var executor = Executors.newFixedThreadPool(2)) {
            Future<SubscriptionPaymentResponse> firstCall = executor.submit(pay);
            Future<SubscriptionPaymentResponse> secondCall = executor.submit(pay);
            assertThat(ready.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)).isTrue();
            go.countDown();
            first = firstCall.get(TIMEOUT_SECONDS, TimeUnit.SECONDS);
            second = secondCall.get(TIMEOUT_SECONDS, TimeUnit.SECONDS);
        }

        assertThat(interceptedLookups.get()).isEqualTo(2);
        assertThat(second.id()).isEqualTo(first.id());
        assertThat(transactionRepository.findBySubscriptionIdAndUserIdOrderByDateDesc(subscription.getId(), user.getId()))
                .extracting(Transaction::getId)
                .containsExactly(first.id());
    }

    @Test
    void should_not_find_the_subscription_of_another_user_when_paying() {
        User owner = saveUser("payment-owner-it@example.com");
        User other = saveUser("payment-other-it@example.com");
        UUID subscriptionId = saveSubscription(owner).getId();
        UUID otherId = other.getId();

        assertThatThrownBy(() -> subscriptionPaymentService.pay(subscriptionId, otherId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Subscription not found");

        assertThat(transactionRepository.findBySubscriptionIdAndUserIdOrderByDateDesc(subscriptionId, owner.getId()))
                .isEmpty();
    }
}
