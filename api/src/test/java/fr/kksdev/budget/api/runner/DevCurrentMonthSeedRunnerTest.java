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
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DevCurrentMonthSeedRunnerTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private AccountRepository accountRepository;

    @InjectMocks
    private DevCurrentMonthSeedRunner devCurrentMonthSeedRunner;

    private final DefaultApplicationArguments noArgs = new DefaultApplicationArguments();

    private User buildDevUser() {
        return User.builder()
                .id(UUID.randomUUID())
                .email("dev@local.test")
                .password("encoded")
                .name("Dev User")
                .isAdmin(false)
                .passwordResetRequired(false)
                .build();
    }

    private Account buildDefaultAccount(UUID userId) {
        return Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte Courant")
                .isDefault(true)
                .build();
    }

    private List<Category> buildCategories() {
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

    @Test
    void should_do_nothing_when_dev_user_does_not_exist() {
        when(userRepository.findByEmail("dev@local.test")).thenReturn(Optional.empty());

        devCurrentMonthSeedRunner.run(noArgs);

        verifyNoInteractions(transactionRepository, categoryRepository, accountRepository);
    }

    @Test
    void should_skip_seeding_when_current_month_already_has_transactions() {
        User devUser = buildDevUser();
        when(userRepository.findByEmail("dev@local.test")).thenReturn(Optional.of(devUser));
        when(transactionRepository.existsByUserIdAndDateBetween(any(), any(), any())).thenReturn(true);

        devCurrentMonthSeedRunner.run(noArgs);

        verifyNoInteractions(categoryRepository, accountRepository);
        verify(transactionRepository, never()).saveAll(any());
    }

    @Test
    void should_skip_seeding_when_no_default_account_found() {
        User devUser = buildDevUser();
        when(userRepository.findByEmail("dev@local.test")).thenReturn(Optional.of(devUser));
        when(transactionRepository.existsByUserIdAndDateBetween(any(), any(), any())).thenReturn(false);
        when(accountRepository.findByUserIdAndIsDefaultTrue(devUser.getId())).thenReturn(Optional.empty());

        devCurrentMonthSeedRunner.run(noArgs);

        verifyNoInteractions(categoryRepository);
        verify(transactionRepository, never()).saveAll(any());
    }

    @Test
    void should_generate_about_ten_transactions_with_no_future_date_when_month_is_empty() {
        User devUser = buildDevUser();
        Account account = buildDefaultAccount(devUser.getId());
        when(userRepository.findByEmail("dev@local.test")).thenReturn(Optional.of(devUser));
        when(transactionRepository.existsByUserIdAndDateBetween(any(), any(), any())).thenReturn(false);
        when(accountRepository.findByUserIdAndIsDefaultTrue(devUser.getId())).thenReturn(Optional.of(account));
        when(categoryRepository.findByUserIdOrderByNomAsc(devUser.getId())).thenReturn(buildCategories());

        devCurrentMonthSeedRunner.run(noArgs);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Transaction>> captor = ArgumentCaptor.forClass(List.class);
        verify(transactionRepository).saveAll(captor.capture());

        List<Transaction> generated = captor.getValue();
        LocalDate today = LocalDate.now();
        LocalDate firstDayOfMonth = today.withDayOfMonth(1);

        assertThat(generated).hasSizeGreaterThanOrEqualTo(8);
        assertThat(generated).allSatisfy(transaction -> {
            assertThat(transaction.getDate()).isAfterOrEqualTo(firstDayOfMonth);
            assertThat(transaction.getDate()).isBeforeOrEqualTo(today);
            assertThat(transaction.getUser()).isEqualTo(devUser);
            assertThat(transaction.getAccount()).isEqualTo(account);
        });
    }

    @Test
    void should_not_create_duplicate_transactions_when_run_twice() {
        User devUser = buildDevUser();
        Account account = buildDefaultAccount(devUser.getId());
        when(userRepository.findByEmail("dev@local.test")).thenReturn(Optional.of(devUser));
        // Premier run : mois vide. Second run : la garde d'idempotence doit court-circuiter.
        when(transactionRepository.existsByUserIdAndDateBetween(any(), any(), any()))
                .thenReturn(false)
                .thenReturn(true);
        when(accountRepository.findByUserIdAndIsDefaultTrue(devUser.getId())).thenReturn(Optional.of(account));
        when(categoryRepository.findByUserIdOrderByNomAsc(devUser.getId())).thenReturn(buildCategories());

        devCurrentMonthSeedRunner.run(noArgs);
        devCurrentMonthSeedRunner.run(noArgs);

        verify(transactionRepository, org.mockito.Mockito.times(1)).saveAll(any());
    }

    // Point le plus important : un runner mal garde injecterait de fausses donnees en prod.
    @Configuration
    static class ProfileGuardTestConfig {

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
