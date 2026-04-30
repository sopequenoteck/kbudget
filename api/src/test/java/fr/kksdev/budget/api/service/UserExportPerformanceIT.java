package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.*;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertTimeout;
import static org.mockito.Mockito.when;

@Tag("performance")
@ExtendWith(MockitoExtension.class)
class UserExportPerformanceIT {

    @Mock
    private AccountRepository accountRepository;
    @Mock
    private CategoryRepository categoryRepository;
    @Mock
    private TransactionRepository transactionRepository;
    @Mock
    private BudgetRepository budgetRepository;
    @Mock
    private BudgetSnapshotRepository budgetSnapshotRepository;
    @Mock
    private SubscriptionRepository subscriptionRepository;
    @Mock
    private DebtRepository debtRepository;
    @Mock
    private CategoryRuleRepository categoryRuleRepository;
    @Mock
    private ImportProfileRepository importProfileRepository;
    @Mock
    private ImportHistoryRepository importHistoryRepository;
    @Mock
    private InvitationRepository invitationRepository;
    @Mock
    private UserPreferenceRepository userPreferenceRepository;

    @InjectMocks
    private UserExportService userExportService;

    @Test
    void should_export_10000_transactions_under_5_seconds() {
        UUID userId = UUID.randomUUID();
        User user = User.builder()
                .id(userId)
                .email("perf@mail.com")
                .name("Perf User")
                .isAdmin(false)
                .passwordResetRequired(false)
                .createdAt(LocalDateTime.now())
                .build();

        Account account = Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte test")
                .currency(Currency.EUR)
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("💳")
                .couleur("#000000")
                .user(user)
                .build();

        List<Transaction> transactions = new ArrayList<>(10_000);
        for (int i = 0; i < 10_000; i++) {
            transactions.add(Transaction.builder()
                    .id(UUID.randomUUID())
                    .montant(new BigDecimal("" + (i + 1) + ".00"))
                    .libelle("Transaction " + i)
                    .type(TransactionType.DEPENSE)
                    .date(LocalDate.of(2026, 1, 1).plusDays(i % 365))
                    .account(account)
                    .isRecurring(false)
                    .recurringActive(true)
                    .build());
        }

        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(transactions);

        assertTimeout(Duration.ofSeconds(5), () -> {
            OutputStream out = new ByteArrayOutputStream();
            userExportService.exportCsv(user, out);
        });

        assertThat(transactions).hasSize(10_000);
    }
}
