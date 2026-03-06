package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.TransactionRequest;
import fr.kksdev.budget.api.dto.response.MonthlySummaryResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.model.UserPreference;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransactionServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private PreferenceService preferenceService;

    @InjectMocks
    private TransactionService transactionService;

    private final UUID userId = UUID.randomUUID();
    private final UUID transactionId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Account buildDefaultAccount(User user) {
        return Account.builder()
                .id(accountId)
                .nom("Compte Principal")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#3b82f6")
                .isDefault(true)
                .actif(true)
                .user(user)
                .build();
    }

    private Transaction buildTransaction(User user, Account account) {
        return Transaction.builder()
                .id(transactionId)
                .montant(new BigDecimal("50.00"))
                .libelle("Courses")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 7))
                .category(null)
                .note("Supermarché")
                .account(account)
                .user(user)
                .build();
    }

    @Test
    void should_create_transaction_when_valid_request() {
        var user = buildUser();
        var account = buildDefaultAccount(user);
        var request = new TransactionRequest(
                new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), null, "Supermarché", null);
        var saved = buildTransaction(user, account);

        when(accountRepository.findByUserIdAndIsDefaultTrue(userId)).thenReturn(Optional.of(account));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        TransactionResponse response = transactionService.create(request, userId);

        assertThat(response.id()).isEqualTo(transactionId);
        assertThat(response.montant()).isEqualByComparingTo("50.00");
        assertThat(response.libelle()).isEqualTo("Courses");
        assertThat(response.type()).isEqualTo(TransactionType.DEPENSE);
        assertThat(response.category()).isNull();
        assertThat(response.account()).isNotNull();
        assertThat(response.account().nom()).isEqualTo("Compte Principal");
        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void should_createTransactionOnDefaultAccount_when_noAccountId() {
        var user = buildUser();
        var account = buildDefaultAccount(user);
        var request = new TransactionRequest(
                new BigDecimal("30.00"), "Café", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), null, null, null);
        var saved = buildTransaction(user, account);

        when(accountRepository.findByUserIdAndIsDefaultTrue(userId)).thenReturn(Optional.of(account));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        TransactionResponse response = transactionService.create(request, userId);

        assertThat(response.account().id()).isEqualTo(accountId);
    }

    @Test
    void should_createTransactionOnSpecifiedAccount_when_accountIdProvided() {
        var user = buildUser();
        var account = buildDefaultAccount(user);
        var request = new TransactionRequest(
                new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), null, null, accountId);
        var saved = buildTransaction(user, account);

        when(accountRepository.findById(accountId)).thenReturn(Optional.of(account));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        TransactionResponse response = transactionService.create(request, userId);

        assertThat(response.account().id()).isEqualTo(accountId);
    }

    @Test
    void should_return_all_transactions_when_user_has_transactions() {
        var user = buildUser();
        var account = buildDefaultAccount(user);
        var transactions = List.of(buildTransaction(user, account));

        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(transactions);

        List<TransactionResponse> result = transactionService.getAllByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().libelle()).isEqualTo("Courses");
        assertThat(result.getFirst().account()).isNotNull();
    }

    @Test
    void should_return_empty_list_when_user_has_no_transactions() {
        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(List.of());

        List<TransactionResponse> result = transactionService.getAllByUser(userId);

        assertThat(result).isEmpty();
    }

    @Test
    void should_return_transaction_when_found_and_owned() {
        var user = buildUser();
        var account = buildDefaultAccount(user);
        var transaction = buildTransaction(user, account);

        when(transactionRepository.findById(transactionId)).thenReturn(Optional.of(transaction));

        TransactionResponse response = transactionService.getById(transactionId, userId);

        assertThat(response.id()).isEqualTo(transactionId);
        assertThat(response.libelle()).isEqualTo("Courses");
    }

    @Test
    void should_throw_when_transaction_not_found() {
        when(transactionRepository.findById(transactionId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> transactionService.getById(transactionId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Transaction non trouvée");
    }

    @Test
    void should_throw_when_transaction_belongs_to_other_user() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        var account = buildDefaultAccount(otherUser);
        var transaction = buildTransaction(otherUser, account);

        when(transactionRepository.findById(transactionId)).thenReturn(Optional.of(transaction));

        assertThatThrownBy(() -> transactionService.getById(transactionId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Transaction non trouvée");
    }

    @Test
    void should_update_transaction_when_valid() {
        var user = buildUser();
        var account = buildDefaultAccount(user);
        var existing = buildTransaction(user, account);
        var request = new TransactionRequest(
                new BigDecimal("75.00"), "Courses modifiées", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 8), null, "Autre magasin", null);

        when(transactionRepository.findById(transactionId)).thenReturn(Optional.of(existing));
        when(transactionRepository.save(any(Transaction.class))).thenReturn(existing);

        TransactionResponse response = transactionService.update(transactionId, request, userId);

        assertThat(response).isNotNull();
        verify(transactionRepository).save(existing);
    }

    @Test
    void should_return_monthly_summary_grouped_by_currency() {
        var user = buildUser();
        var account = buildDefaultAccount(user);
        var depense = Transaction.builder()
                .id(UUID.randomUUID()).montant(new BigDecimal("50.00"))
                .type(TransactionType.DEPENSE).date(LocalDate.of(2026, 2, 10))
                .libelle("Courses").account(account).user(user).build();
        var recette = Transaction.builder()
                .id(UUID.randomUUID()).montant(new BigDecimal("2000.00"))
                .type(TransactionType.RECETTE).date(LocalDate.of(2026, 2, 1))
                .libelle("Salaire").account(account).user(user).build();

        var preference = UserPreference.builder().currencies(List.of(Currency.EUR)).build();
        when(transactionRepository.findByUserIdAndDateBetweenOrderByDateDesc(
                userId, LocalDate.of(2026, 2, 1), LocalDate.of(2026, 2, 28)))
                .thenReturn(List.of(depense, recette));
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(preference);

        List<MonthlySummaryResponse> summaries = transactionService.getMonthlySummary(2, 2026, userId);

        assertThat(summaries).hasSize(1);
        var summary = summaries.getFirst();
        assertThat(summary.month()).isEqualTo(2);
        assertThat(summary.year()).isEqualTo(2026);
        assertThat(summary.totalRecettes()).isEqualByComparingTo("2000.00");
        assertThat(summary.totalDepenses()).isEqualByComparingTo("50.00");
        assertThat(summary.solde()).isEqualByComparingTo("1950.00");
        assertThat(summary.currency()).isEqualTo("EUR");
    }

    @Test
    void should_return_empty_list_when_no_transactions() {
        var preference = UserPreference.builder().currencies(List.of(Currency.EUR)).build();
        when(transactionRepository.findByUserIdAndDateBetweenOrderByDateDesc(
                userId, LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31)))
                .thenReturn(List.of());
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(preference);

        List<MonthlySummaryResponse> summaries = transactionService.getMonthlySummary(3, 2026, userId);

        assertThat(summaries).isEmpty();
    }

    @Test
    void should_delete_transaction_when_found_and_owned() {
        var user = buildUser();
        var account = buildDefaultAccount(user);
        var transaction = buildTransaction(user, account);

        when(transactionRepository.findById(transactionId)).thenReturn(Optional.of(transaction));

        transactionService.delete(transactionId, userId);

        verify(transactionRepository).delete(transaction);
    }

    @Test
    void should_return404_when_accountNotFound() {
        var request = new TransactionRequest(
                new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), null, null, UUID.randomUUID());

        when(accountRepository.findById(any(UUID.class))).thenReturn(Optional.empty());

        assertThatThrownBy(() -> transactionService.create(request, userId))
                .isInstanceOf(EntityNotFoundException.class);
    }
}
