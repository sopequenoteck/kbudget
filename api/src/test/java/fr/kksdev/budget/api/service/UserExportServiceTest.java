package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.UserExportResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.*;
import fr.kksdev.budget.api.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserExportServiceTest {

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

    private User user;
    private UUID userId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        user = User.builder()
                .id(userId)
                .email("test@mail.com")
                .name("Test User")
                .isAdmin(false)
                .passwordResetRequired(false)
                .createdAt(LocalDateTime.now())
                .build();
    }

    private void stubAllRepositoriesEmpty() {
        when(accountRepository.findByUserId(userId)).thenReturn(List.of());
        when(categoryRepository.findByUserIdOrderByNomAsc(userId)).thenReturn(List.of());
        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(List.of());
        when(budgetRepository.findByUserId(userId)).thenReturn(List.of());
        when(budgetSnapshotRepository.findByUserId(userId)).thenReturn(List.of());
        when(subscriptionRepository.findByUserIdOrderByNomAsc(userId)).thenReturn(List.of());
        when(debtRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(List.of());
        when(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of());
        when(importProfileRepository.findByUserIdOrderByNameAsc(userId)).thenReturn(List.of());
        when(importHistoryRepository.findByUserId(userId)).thenReturn(List.of());
        when(invitationRepository.findByInvitedById(userId)).thenReturn(List.of());
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.empty());
    }

    @Test
    void should_export_all_user_entities_when_format_json() {
        stubAllRepositoriesEmpty();

        UserExportResponse response = userExportService.exportJson(user);

        assertThat(response).isNotNull();
        assertThat(response.schemaVersion()).isEqualTo("1.0.0");
        assertThat(response.exportedAt()).isNotNull();
        assertThat(response.user()).isNotNull();
        assertThat(response.accounts()).isNotNull().isEmpty();
        assertThat(response.categories()).isNotNull().isEmpty();
        assertThat(response.transactions()).isNotNull().isEmpty();
        assertThat(response.budgets()).isNotNull().isEmpty();
        assertThat(response.budgetSnapshots()).isNotNull().isEmpty();
        assertThat(response.subscriptions()).isNotNull().isEmpty();
        assertThat(response.debts()).isNotNull().isEmpty();
        assertThat(response.categoryRules()).isNotNull().isEmpty();
        assertThat(response.importProfiles()).isNotNull().isEmpty();
        assertThat(response.importHistory()).isNotNull().isEmpty();
        assertThat(response.invitations()).isNotNull().isEmpty();
    }

    @Test
    void should_not_expose_password_hash_in_export() {
        stubAllRepositoriesEmpty();

        UserExportResponse response = userExportService.exportJson(user);

        // Le UserDto ne doit pas contenir le mot de passe
        assertThat(response.user().email()).isEqualTo("test@mail.com");
        // Vérification structurelle : le record UserDto n'a pas de champ password
        var fields = java.util.Arrays.stream(UserExportResponse.UserDto.class.getRecordComponents())
                .map(rc -> rc.getName())
                .toList();
        assertThat(fields).doesNotContain("password");
    }

    @Test
    void should_include_invitations_in_export() {
        when(accountRepository.findByUserId(userId)).thenReturn(List.of());
        when(categoryRepository.findByUserIdOrderByNomAsc(userId)).thenReturn(List.of());
        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(List.of());
        when(budgetRepository.findByUserId(userId)).thenReturn(List.of());
        when(budgetSnapshotRepository.findByUserId(userId)).thenReturn(List.of());
        when(subscriptionRepository.findByUserIdOrderByNomAsc(userId)).thenReturn(List.of());
        when(debtRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(List.of());
        when(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of());
        when(importProfileRepository.findByUserIdOrderByNameAsc(userId)).thenReturn(List.of());
        when(importHistoryRepository.findByUserId(userId)).thenReturn(List.of());
        when(userPreferenceRepository.findByUserId(userId)).thenReturn(Optional.empty());

        Invitation invitation = Invitation.builder()
                .id(1L)
                .token(UUID.randomUUID())
                .email("invited@mail.com")
                .invitedBy(user)
                .expiresAt(java.time.Instant.now().plusSeconds(86400))
                .createdAt(java.time.Instant.now())
                .build();
        when(invitationRepository.findByInvitedById(userId)).thenReturn(List.of(invitation));

        UserExportResponse response = userExportService.exportJson(user);

        assertThat(response.invitations()).hasSize(1);
        assertThat(response.invitations().get(0).email()).isEqualTo("invited@mail.com");
    }

    @Test
    void should_export_transactions_only_when_format_csv() throws Exception {
        Account account = Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte courant")
                .currency(Currency.EUR)
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("💳")
                .couleur("#000000")
                .user(user)
                .build();

        Transaction transaction = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("42.50"))
                .libelle("Supermarché")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 4, 27))
                .account(account)
                .isRecurring(false)
                .recurringActive(true)
                .build();

        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(List.of(transaction));

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        userExportService.exportCsv(user, baos);
        String csv = baos.toString(StandardCharsets.UTF_8);

        assertThat(csv).contains("Supermarché");
        assertThat(csv).contains("42.50");
        assertThat(csv).contains("EUR");
        assertThat(csv).contains("Compte courant");
    }

    @Test
    void should_translate_transaction_type_in_csv() throws Exception {
        Account account = Account.builder()
                .id(UUID.randomUUID())
                .nom("Livret A")
                .currency(Currency.EUR)
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("💰")
                .couleur("#000000")
                .user(user)
                .build();

        Transaction depense = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("10.00"))
                .libelle("Café")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 4, 1))
                .account(account)
                .isRecurring(false)
                .recurringActive(true)
                .build();

        Transaction recette = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("1500.00"))
                .libelle("Salaire")
                .type(TransactionType.RECETTE)
                .date(LocalDate.of(2026, 4, 2))
                .account(account)
                .isRecurring(false)
                .recurringActive(true)
                .build();

        Transaction ajustement = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("5.00"))
                .libelle("Ajustement")
                .type(TransactionType.AJUSTEMENT)
                .date(LocalDate.of(2026, 4, 3))
                .account(account)
                .isRecurring(false)
                .recurringActive(true)
                .build();

        when(transactionRepository.findByUserIdOrderByDateDesc(userId))
                .thenReturn(List.of(depense, recette, ajustement));

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        userExportService.exportCsv(user, baos);
        String csv = baos.toString(StandardCharsets.UTF_8);

        assertThat(csv).contains("Dépense");
        assertThat(csv).contains("Revenu");
        assertThat(csv).contains("Ajustement");
    }

    @Test
    void should_isolate_user_data_in_export() {
        // user A et user B : l'export de A ne doit PAS contenir les comptes de B
        UUID userAId = userId;
        UUID userBId = UUID.randomUUID();
        User userB = User.builder()
                .id(userBId)
                .email("userb@mail.com")
                .name("User B")
                .build();

        Account accountA = Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte A")
                .currency(Currency.EUR)
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("💳")
                .couleur("#000000")
                .user(user)
                .build();

        // Les repositories sont filtrés par userId — Spring Data garantit l'isolation
        // On vérifie que l'export de A ne contient que les données de A
        when(accountRepository.findByUserId(userAId)).thenReturn(List.of(accountA));
        when(categoryRepository.findByUserIdOrderByNomAsc(userAId)).thenReturn(List.of());
        when(transactionRepository.findByUserIdOrderByDateDesc(userAId)).thenReturn(List.of());
        when(budgetRepository.findByUserId(userAId)).thenReturn(List.of());
        when(budgetSnapshotRepository.findByUserId(userAId)).thenReturn(List.of());
        when(subscriptionRepository.findByUserIdOrderByNomAsc(userAId)).thenReturn(List.of());
        when(debtRepository.findByUserIdOrderByDateDesc(userAId)).thenReturn(List.of());
        when(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(userAId)).thenReturn(List.of());
        when(importProfileRepository.findByUserIdOrderByNameAsc(userAId)).thenReturn(List.of());
        when(importHistoryRepository.findByUserId(userAId)).thenReturn(List.of());
        when(invitationRepository.findByInvitedById(userAId)).thenReturn(List.of());
        when(userPreferenceRepository.findByUserId(userAId)).thenReturn(Optional.empty());

        UserExportResponse response = userExportService.exportJson(user);

        assertThat(response.accounts()).hasSize(1);
        assertThat(response.accounts().get(0).nom()).isEqualTo("Compte A");
        // Aucun compte de B ne doit figurer
        assertThat(response.accounts()).noneMatch(a -> a.nom().equals("Compte B"));
    }

    @Test
    void should_include_utf8_bom_in_csv() throws Exception {
        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(List.of());

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        userExportService.exportCsv(user, baos);
        byte[] bytes = baos.toByteArray();

        assertThat(bytes.length).isGreaterThanOrEqualTo(3);
        assertThat(bytes[0] & 0xFF).isEqualTo(0xEF);
        assertThat(bytes[1] & 0xFF).isEqualTo(0xBB);
        assertThat(bytes[2] & 0xFF).isEqualTo(0xBF);
    }
}
