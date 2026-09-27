package fr.kksdev.budget.api.runner;

import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;
import java.time.LocalDate;
import java.time.Month;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DevCurrentMonthSeedRunnerTest {

    private static final String DEV_EMAIL = "dev@local.test";
    private static final String DEMO_EMAIL = "demo@local.test";

    @Mock
    private UserRepository userRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private AccountRepository accountRepository;

    /**
     * Horloge fixe : le test verifie un comportement date sans dependre du jour
     * ou il s'execute. Le 12 mars 2026 laisse onze jours ecoules, assez pour que
     * les dix ecritures tombent a leur jour prevu sans etre ramenees a today.
     */
    private static final LocalDate REFERENCE_DAY = LocalDate.of(2026, Month.MARCH, 12);
    private static final Clock FIXED_CLOCK =
            Clock.fixed(REFERENCE_DAY.atStartOfDay(ZoneOffset.UTC).toInstant(), ZoneOffset.UTC);

    @Spy
    private final Clock clock = FIXED_CLOCK;

    @InjectMocks
    private DevCurrentMonthSeedRunner devCurrentMonthSeedRunner;

    private final DefaultApplicationArguments noArgs = new DefaultApplicationArguments();

    /** Les deux emails seedes par le runner (dev@local.test et son miroir demo@local.test — KKS-394). */
    private static Stream<Arguments> seededEmails() {
        return Stream.of(
                Arguments.of(DEV_EMAIL, "Dev User", buildFrenchCategories()),
                Arguments.of(DEMO_EMAIL, "Alex Morgan", buildEnglishCategories()));
    }

    private User buildUser(String email, String name) {
        return User.builder()
                .id(UUID.randomUUID())
                .email(email)
                .password("encoded")
                .name(name)
                .isAdmin(false)
                .passwordResetRequired(false)
                .build();
    }

    private Account buildDefaultAccount() {
        return Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte Courant")
                .isDefault(true)
                .build();
    }

    private static List<Category> buildFrenchCategories() {
        return List.of(
                Category.builder().id(UUID.randomUUID()).nom("Salaire").icone("💼").couleur("#10b981").build(),
                Category.builder().id(UUID.randomUUID()).nom("Logement").icone("🏠").couleur("#f97316").build(),
                Category.builder().id(UUID.randomUUID()).nom("Alimentation").icone("🛒").couleur("#22c55e").build(),
                Category.builder().id(UUID.randomUUID()).nom("Transport").icone("🚗").couleur("#3b82f6").build(),
                Category.builder().id(UUID.randomUUID()).nom("Restaurant").icone("🍽️").couleur("#f59e0b").build(),
                Category.builder().id(UUID.randomUUID()).nom("Courses").icone("🧺").couleur("#14b8a6").build(),
                Category.builder().id(UUID.randomUUID()).nom("Loisirs").icone("🎮").couleur("#a855f7").build()
        );
    }

    private static List<Category> buildEnglishCategories() {
        return List.of(
                Category.builder().id(UUID.randomUUID()).nom("Salary").icone("💼").couleur("#10b981").build(),
                Category.builder().id(UUID.randomUUID()).nom("Housing").icone("🏠").couleur("#f97316").build(),
                Category.builder().id(UUID.randomUUID()).nom("Food").icone("🛒").couleur("#22c55e").build(),
                Category.builder().id(UUID.randomUUID()).nom("Transport").icone("🚗").couleur("#3b82f6").build(),
                Category.builder().id(UUID.randomUUID()).nom("Restaurant").icone("🍽️").couleur("#f59e0b").build(),
                Category.builder().id(UUID.randomUUID()).nom("Groceries").icone("🧺").couleur("#14b8a6").build(),
                Category.builder().id(UUID.randomUUID()).nom("Leisure").icone("🎮").couleur("#a855f7").build()
        );
    }

    /** Les autres emails seedes doivent rester introuvables, sans quoi le scenario teste n'est plus isole. */
    private void stubOtherEmailsAbsent() {
        when(userRepository.findByEmail(any())).thenReturn(Optional.empty());
    }

    @Test
    void should_do_nothing_when_no_seeded_user_exists() {
        stubOtherEmailsAbsent();

        devCurrentMonthSeedRunner.run(noArgs);

        verifyNoInteractions(transactionRepository, categoryRepository, accountRepository);
    }

    @ParameterizedTest(name = "should skip seeding when current month already has transactions for {0}")
    @MethodSource("seededEmails")
    void should_skip_seeding_when_current_month_already_has_transactions(String email, String name, List<Category> categories) {
        stubOtherEmailsAbsent();
        User user = buildUser(email, name);
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(user));
        when(transactionRepository.existsByUserIdAndDateBetween(user.getId(), REFERENCE_DAY.withDayOfMonth(1), REFERENCE_DAY))
                .thenReturn(true);

        devCurrentMonthSeedRunner.run(noArgs);

        verifyNoInteractions(categoryRepository, accountRepository);
        verify(transactionRepository, never()).saveAll(any());
    }

    @ParameterizedTest(name = "should skip seeding when no default account is found for {0}")
    @MethodSource("seededEmails")
    void should_skip_seeding_when_no_default_account_found(String email, String name, List<Category> categories) {
        stubOtherEmailsAbsent();
        User user = buildUser(email, name);
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(user));
        when(transactionRepository.existsByUserIdAndDateBetween(user.getId(), REFERENCE_DAY.withDayOfMonth(1), REFERENCE_DAY))
                .thenReturn(false);
        when(accountRepository.findByUserIdAndIsDefaultTrue(user.getId())).thenReturn(Optional.empty());

        devCurrentMonthSeedRunner.run(noArgs);

        verifyNoInteractions(categoryRepository);
        verify(transactionRepository, never()).saveAll(any());
    }

    @ParameterizedTest(name = "should generate current-month transactions with no future date for {0}")
    @MethodSource("seededEmails")
    void should_generate_current_month_transactions_when_month_is_empty(String email, String name, List<Category> categories) {
        stubOtherEmailsAbsent();
        User user = buildUser(email, name);
        Account account = buildDefaultAccount();
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(user));
        when(transactionRepository.existsByUserIdAndDateBetween(user.getId(), REFERENCE_DAY.withDayOfMonth(1), REFERENCE_DAY))
                .thenReturn(false);
        when(accountRepository.findByUserIdAndIsDefaultTrue(user.getId())).thenReturn(Optional.of(account));
        when(categoryRepository.findByUserIdOrderByNomAsc(user.getId())).thenReturn(categories);

        devCurrentMonthSeedRunner.run(noArgs);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Transaction>> captor = ArgumentCaptor.forClass(List.class);
        verify(transactionRepository, times(1)).saveAll(captor.capture());

        List<Transaction> generated = captor.getValue();
        LocalDate today = LocalDate.now(clock);
        LocalDate firstDayOfMonth = today.withDayOfMonth(1);

        assertThat(generated)
                .hasSizeGreaterThanOrEqualTo(8)
                .allSatisfy(transaction -> assertThat(transaction)
                        .extracting(Transaction::getUser, Transaction::getAccount)
                        .containsExactly(user, account))
                .extracting(Transaction::getDate)
                .allSatisfy(date -> assertThat(date).isBetween(firstDayOfMonth, today));
    }

    @ParameterizedTest(name = "should not create duplicate transactions when run twice for {0}")
    @MethodSource("seededEmails")
    void should_not_create_duplicate_transactions_when_run_twice(String email, String name, List<Category> categories) {
        stubOtherEmailsAbsent();
        User user = buildUser(email, name);
        Account account = buildDefaultAccount();
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(user));
        // Premier run : mois vide. Second run : la garde d'idempotence doit court-circuiter.
        when(transactionRepository.existsByUserIdAndDateBetween(user.getId(), REFERENCE_DAY.withDayOfMonth(1), REFERENCE_DAY))
                .thenReturn(false)
                .thenReturn(true);
        when(accountRepository.findByUserIdAndIsDefaultTrue(user.getId())).thenReturn(Optional.of(account));
        when(categoryRepository.findByUserIdOrderByNomAsc(user.getId())).thenReturn(categories);

        devCurrentMonthSeedRunner.run(noArgs);
        devCurrentMonthSeedRunner.run(noArgs);

        verify(transactionRepository, times(1)).saveAll(any());
    }

    @ParameterizedTest(name = "should skip seeding when no seed category matches for {0}")
    @MethodSource("seededEmails")
    void should_skip_seeding_when_no_matching_category_found(String email, String name, List<Category> categories) {
        stubOtherEmailsAbsent();
        User user = buildUser(email, name);
        Account account = buildDefaultAccount();
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(user));
        when(transactionRepository.existsByUserIdAndDateBetween(user.getId(), REFERENCE_DAY.withDayOfMonth(1), REFERENCE_DAY))
                .thenReturn(false);
        when(accountRepository.findByUserIdAndIsDefaultTrue(user.getId())).thenReturn(Optional.of(account));
        // Aucune categorie du seed ne correspond : buildTransactions ne doit rien produire.
        when(categoryRepository.findByUserIdOrderByNomAsc(user.getId())).thenReturn(List.of());

        devCurrentMonthSeedRunner.run(noArgs);

        verify(transactionRepository, never()).saveAll(any());
    }

    // Point le plus important : un runner mal garde injecterait de fausses donnees en prod.
    @Configuration
    static class ProfileGuardTestConfig {

        @Bean
        Clock clock() {
            return FIXED_CLOCK;
        }

        @Bean
        UserRepository userRepository() {
            return mock(UserRepository.class);
        }

        @Bean
        TransactionRepository transactionRepository() {
            return mock(TransactionRepository.class);
        }

        @Bean
        CategoryRepository categoryRepository() {
            return mock(CategoryRepository.class);
        }

        @Bean
        AccountRepository accountRepository() {
            return mock(AccountRepository.class);
        }
    }

    @Test
    void should_not_register_bean_when_dev_profile_is_not_active() {
        try (AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().setActiveProfiles("test");
            context.register(ProfileGuardTestConfig.class, DevCurrentMonthSeedRunner.class);
            context.refresh();

            assertThat(context.getBeanNamesForType(DevCurrentMonthSeedRunner.class)).isEmpty();
        }
    }

    @Test
    void should_register_bean_when_dev_profile_is_active() {
        try (AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().setActiveProfiles("dev");
            context.register(ProfileGuardTestConfig.class, DevCurrentMonthSeedRunner.class);
            context.refresh();

            assertThat(context.getBeanNamesForType(DevCurrentMonthSeedRunner.class)).hasSize(1);
        }
    }
}
