package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.RecurringTransactionRequest;
import fr.kksdev.budget.api.dto.response.RecurringTransactionResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
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
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RecurringTransactionServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private BudgetService budgetService;

    @InjectMocks
    private RecurringTransactionService recurringTransactionService;

    private final UUID userId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();
    private final UUID recurringId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Account buildAccount(User user) {
        return Account.builder()
                .id(accountId)
                .nom("Compte Principal")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#3b82f6")
                .isDefault(true)
                .actif(true)
                .currency(Currency.EUR)
                .user(user)
                .build();
    }

    private Transaction buildRecurringTransaction(User user, Account account, Frequency frequency, LocalDate nextOccurrence) {
        return Transaction.builder()
                .id(recurringId)
                .montant(new BigDecimal("50.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(nextOccurrence)
                .account(account)
                .user(user)
                .isRecurring(true)
                .frequency(frequency)
                .nextOccurrence(nextOccurrence)
                .recurringActive(true)
                .build();
    }

    @Test
    void should_createRecurringTransaction_when_validRequest() {
        var user = buildUser();
        var account = buildAccount(user);
        var nextOccurrence = LocalDate.of(2026, 3, 15);
        var request = new RecurringTransactionRequest(
                new BigDecimal("50.00"), "Loyer", TransactionType.DEPENSE,
                Frequency.MENSUEL, nextOccurrence, null, accountId, null);
        var saved = buildRecurringTransaction(user, account, Frequency.MENSUEL, nextOccurrence);

        when(accountRepository.findById(accountId)).thenReturn(Optional.of(account));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        RecurringTransactionResponse response = recurringTransactionService.create(request, userId);

        assertThat(response.id()).isEqualTo(recurringId);
        assertThat(response.montant()).isEqualByComparingTo("50.00");
        assertThat(response.libelle()).isEqualTo("Loyer");
        assertThat(response.frequency()).isEqualTo(Frequency.MENSUEL);
        assertThat(response.nextOccurrence()).isEqualTo(nextOccurrence);
        assertThat(response.recurringActive()).isTrue();
        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void should_listActiveRecurrences_when_userHasRecurrences() {
        var user = buildUser();
        var account = buildAccount(user);
        var nextOccurrence = LocalDate.of(2026, 3, 15);
        var recurring = buildRecurringTransaction(user, account, Frequency.MENSUEL, nextOccurrence);

        when(transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueOrderByNextOccurrenceAsc(userId))
                .thenReturn(List.of(recurring));

        List<RecurringTransactionResponse> result = recurringTransactionService.listActive(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().libelle()).isEqualTo("Loyer");
        assertThat(result.getFirst().frequency()).isEqualTo(Frequency.MENSUEL);
    }

    @Test
    void should_returnEmptyList_when_noActiveRecurrences() {
        when(transactionRepository.findByUserIdAndIsRecurringTrueAndRecurringActiveTrueOrderByNextOccurrenceAsc(userId))
                .thenReturn(List.of());

        List<RecurringTransactionResponse> result = recurringTransactionService.listActive(userId);

        assertThat(result).isEmpty();
    }

    @Test
    void should_createTransactionAndAdvanceDate_when_validateMonthly() {
        var user = buildUser();
        var account = buildAccount(user);
        var nextOccurrence = LocalDate.of(2026, 3, 15);
        var recurring = buildRecurringTransaction(user, account, Frequency.MENSUEL, nextOccurrence);
        var newTransactionId = UUID.randomUUID();
        var newTransaction = Transaction.builder()
                .id(newTransactionId)
                .montant(new BigDecimal("50.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .account(account)
                .user(user)
                .build();

        when(transactionRepository.findById(recurringId)).thenReturn(Optional.of(recurring));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(newTransaction);

        TransactionResponse response = recurringTransactionService.validate(recurringId, userId);

        assertThat(response.id()).isEqualTo(newTransactionId);
        assertThat(recurring.getNextOccurrence()).isEqualTo(LocalDate.of(2026, 4, 15));
    }

    @Test
    void should_createTransactionAndAdvanceDate_when_validateWeekly() {
        var user = buildUser();
        var account = buildAccount(user);
        var nextOccurrence = LocalDate.of(2026, 3, 10);
        var recurring = buildRecurringTransaction(user, account, Frequency.HEBDOMADAIRE, nextOccurrence);
        var newTransactionId = UUID.randomUUID();
        var newTransaction = Transaction.builder()
                .id(newTransactionId)
                .montant(new BigDecimal("50.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .account(account)
                .user(user)
                .build();

        when(transactionRepository.findById(recurringId)).thenReturn(Optional.of(recurring));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(newTransaction);

        recurringTransactionService.validate(recurringId, userId);

        assertThat(recurring.getNextOccurrence()).isEqualTo(LocalDate.of(2026, 3, 17));
    }

    @Test
    void should_createTransactionAndAdvanceDate_when_validateYearly() {
        var user = buildUser();
        var account = buildAccount(user);
        var nextOccurrence = LocalDate.of(2026, 3, 10);
        var recurring = buildRecurringTransaction(user, account, Frequency.ANNUEL, nextOccurrence);
        var newTransactionId = UUID.randomUUID();
        var newTransaction = Transaction.builder()
                .id(newTransactionId)
                .montant(new BigDecimal("50.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .account(account)
                .user(user)
                .build();

        when(transactionRepository.findById(recurringId)).thenReturn(Optional.of(recurring));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(newTransaction);

        recurringTransactionService.validate(recurringId, userId);

        assertThat(recurring.getNextOccurrence()).isEqualTo(LocalDate.of(2027, 3, 10));
    }

    @Test
    void should_throwException_when_validateInactiveRecurrence() {
        var user = buildUser();
        var account = buildAccount(user);
        var recurring = Transaction.builder()
                .id(recurringId)
                .montant(new BigDecimal("50.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 3, 15))
                .account(account)
                .user(user)
                .isRecurring(true)
                .frequency(Frequency.MENSUEL)
                .nextOccurrence(LocalDate.of(2026, 3, 15))
                .recurringActive(false)
                .build();

        when(transactionRepository.findById(recurringId)).thenReturn(Optional.of(recurring));

        assertThatThrownBy(() -> recurringTransactionService.validate(recurringId, userId))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("The recurring transaction is disabled");
    }

    @Test
    void should_useDefaultAccount_when_accountIsNull() {
        var user = buildUser();
        var account = buildAccount(user);
        var nextOccurrence = LocalDate.of(2026, 3, 15);
        var request = new RecurringTransactionRequest(
                new BigDecimal("50.00"), "Loyer", TransactionType.DEPENSE,
                Frequency.MENSUEL, nextOccurrence, null, null, null);
        var saved = buildRecurringTransaction(user, account, Frequency.MENSUEL, nextOccurrence);

        when(accountRepository.findByUserIdAndIsDefaultTrue(userId)).thenReturn(Optional.of(account));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        RecurringTransactionResponse response = recurringTransactionService.create(request, userId);

        assertThat(response.account().id()).isEqualTo(accountId);
        verify(accountRepository).findByUserIdAndIsDefaultTrue(userId);
    }

    @Test
    void should_handleEndOfMonth_when_validateMonthlyOn31st() {
        var nextOccurrence = LocalDate.of(2026, 1, 31);
        var expectedNext = LocalDate.of(2026, 2, 28);

        LocalDate result = recurringTransactionService.advanceDate(nextOccurrence, Frequency.MENSUEL);

        assertThat(result).isEqualTo(expectedNext);
    }

    @Test
    void should_advanceDateWithoutTransaction_when_skip() {
        var user = buildUser();
        var account = buildAccount(user);
        var nextOccurrence = LocalDate.of(2026, 3, 15);
        var recurring = buildRecurringTransaction(user, account, Frequency.MENSUEL, nextOccurrence);

        when(transactionRepository.findById(recurringId)).thenReturn(Optional.of(recurring));
        when(transactionRepository.save(any(Transaction.class))).thenReturn(recurring);

        RecurringTransactionResponse response = recurringTransactionService.skip(recurringId, userId);

        assertThat(recurring.getNextOccurrence()).isEqualTo(LocalDate.of(2026, 4, 15));
        verify(transactionRepository, times(1)).save(any(Transaction.class));
    }

    @Test
    void should_throwException_when_skipInactiveRecurrence() {
        var user = buildUser();
        var account = buildAccount(user);
        var recurring = Transaction.builder()
                .id(recurringId)
                .montant(new BigDecimal("50.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 3, 15))
                .account(account)
                .user(user)
                .isRecurring(true)
                .frequency(Frequency.MENSUEL)
                .nextOccurrence(LocalDate.of(2026, 3, 15))
                .recurringActive(false)
                .build();

        when(transactionRepository.findById(recurringId)).thenReturn(Optional.of(recurring));

        assertThatThrownBy(() -> recurringTransactionService.skip(recurringId, userId))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("The recurring transaction is disabled");
    }

    @Test
    void should_setRecurringActiveFalse_when_deactivate() {
        var user = buildUser();
        var account = buildAccount(user);
        var nextOccurrence = LocalDate.of(2026, 3, 15);
        var recurring = buildRecurringTransaction(user, account, Frequency.MENSUEL, nextOccurrence);

        when(transactionRepository.findById(recurringId)).thenReturn(Optional.of(recurring));
        when(transactionRepository.save(any(Transaction.class))).thenReturn(recurring);

        recurringTransactionService.deactivate(recurringId, userId);

        assertThat(recurring.getRecurringActive()).isFalse();
        verify(transactionRepository).save(recurring);
    }

    @Test
    void should_throwException_when_deactivateAlreadyInactive() {
        var user = buildUser();
        var account = buildAccount(user);
        var recurring = Transaction.builder()
                .id(recurringId)
                .montant(new BigDecimal("50.00"))
                .libelle("Loyer")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 3, 15))
                .account(account)
                .user(user)
                .isRecurring(true)
                .frequency(Frequency.MENSUEL)
                .nextOccurrence(LocalDate.of(2026, 3, 15))
                .recurringActive(false)
                .build();

        when(transactionRepository.findById(recurringId)).thenReturn(Optional.of(recurring));

        assertThatThrownBy(() -> recurringTransactionService.deactivate(recurringId, userId))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("The recurring transaction is already disabled");
    }
}
