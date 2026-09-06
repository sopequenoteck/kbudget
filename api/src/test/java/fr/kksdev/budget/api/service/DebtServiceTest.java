package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.DebtRepayRequest;
import fr.kksdev.budget.api.dto.request.DebtRequest;
import fr.kksdev.budget.api.dto.request.DebtSnoozeRequest;
import fr.kksdev.budget.api.dto.response.DebtPaymentResponse;
import fr.kksdev.budget.api.dto.response.DebtResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.ExchangeRate;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.model.UserPreference;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.ExchangeRateRepository;
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
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DebtServiceTest {

    @Mock
    private DebtRepository debtRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private CategoryService categoryService;

    @Mock
    private PreferenceService preferenceService;

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private ExchangeRateRepository exchangeRateRepository;

    @InjectMocks
    private DebtService debtService;

    private final UUID userId = UUID.randomUUID();
    private final UUID debtId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Debt buildDebt(User user) {
        return Debt.builder()
                .id(debtId)
                .personne("Alice")
                .montant(new BigDecimal("100.00"))
                .sens(DebtType.EMPRUNT)
                .date(LocalDate.of(2026, 2, 1))
                .currency(Currency.EUR)
                .rembourse(false)
                .includeInBalance(false)
                .category(null)
                .user(user)
                .build();
    }

    private Account buildAccount(User user) {
        return Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte Principal")
                .currency(Currency.EUR)
                .actif(true)
                .user(user)
                .build();
    }

    // -------------------------------------------------------------------------
    // Existing tests — updated for new DebtRequest (11 args) + sumByDebtId mock
    // -------------------------------------------------------------------------

    @Test
    void should_create_debt_when_valid_request() {
        var user = buildUser();
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1), null, null, null, null,
                null, null, null, null);
        var saved = buildDebt(user);

        var preference = UserPreference.builder().currencies(List.of(Currency.EUR)).build();
        when(categoryService.findSystemCategoryByNom("Dette", userId)).thenReturn(null);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(preference);
        when(debtRepository.save(any(Debt.class))).thenReturn(saved);
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        DebtResponse response = debtService.create(request, userId);

        assertThat(response.id()).isEqualTo(debtId);
        assertThat(response.personne()).isEqualTo("Alice");
        assertThat(response.rembourse()).isFalse();
        verify(debtRepository).save(any(Debt.class));
    }

    @Test
    void should_assignSystemCategory_when_noCategoryProvided() {
        var user = buildUser();
        var systemCat = Category.builder()
                .id(UUID.randomUUID())
                .nom("Dette")
                .icone("\uD83D\uDCB0")
                .couleur("#ef4444")
                .isSystem(true)
                .user(user)
                .build();
        var saved = Debt.builder()
                .id(debtId)
                .personne("Alice")
                .montant(new BigDecimal("100.00"))
                .sens(DebtType.EMPRUNT)
                .date(LocalDate.of(2026, 2, 1))
                .currency(Currency.EUR)
                .rembourse(false)
                .category(systemCat)
                .user(user)
                .build();
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1), null, null, null,
                null, null, null, null, null);

        var preference = UserPreference.builder().currencies(List.of(Currency.EUR)).build();
        when(categoryService.findSystemCategoryByNom("Dette", userId)).thenReturn(systemCat);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(preference);
        when(debtRepository.save(any(Debt.class))).thenReturn(saved);
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        DebtResponse response = debtService.create(request, userId);

        assertThat(response.category()).isNotNull();
        assertThat(response.category().nom()).isEqualTo("Dette");
        assertThat(response.category().isSystem()).isTrue();
    }

    @Test
    void should_return_all_debts_when_user_has_debts() {
        var user = buildUser();
        when(debtRepository.findByUserIdOrderByDateDesc(userId))
                .thenReturn(List.of(buildDebt(user)));
        when(transactionRepository.sumByDebtIds(any(List.class))).thenReturn(List.of());

        List<DebtResponse> result = debtService.getAllByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().personne()).isEqualTo("Alice");
    }

    @Test
    void should_return_only_unpaid_debts() {
        var user = buildUser();
        when(debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId))
                .thenReturn(List.of(buildDebt(user)));
        when(transactionRepository.sumByDebtIds(any(List.class))).thenReturn(List.of());

        List<DebtResponse> result = debtService.getUnpaidByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().rembourse()).isFalse();
    }

    @Test
    void should_return_debt_when_found_and_owned() {
        var user = buildUser();
        when(debtRepository.findById(debtId)).thenReturn(Optional.of(buildDebt(user)));
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        DebtResponse response = debtService.getById(debtId, userId);

        assertThat(response.id()).isEqualTo(debtId);
    }

    @Test
    void should_throw_when_debt_not_found() {
        when(debtRepository.findById(debtId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> debtService.getById(debtId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Debt not found");
    }

    @Test
    void should_throw_when_debt_belongs_to_other_user() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        when(debtRepository.findById(debtId)).thenReturn(Optional.of(buildDebt(otherUser)));

        assertThatThrownBy(() -> debtService.getById(debtId, userId))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void should_update_debt_when_valid() {
        var user = buildUser();
        var existing = buildDebt(user);
        var request = new DebtRequest("Bob", new BigDecimal("200.00"),
                DebtType.PRET, LocalDate.of(2026, 2, 5), null, true, null,
                null, null, null, null, null);

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(existing));
        when(debtRepository.save(any(Debt.class))).thenReturn(existing);
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        DebtResponse response = debtService.update(debtId, request, userId);

        assertThat(response).isNotNull();
        verify(debtRepository).save(existing);
    }

    @Test
    void should_delete_debt_when_found_and_owned() {
        var user = buildUser();
        var debt = buildDebt(user);

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.findByDebtIdOrderByDateDesc(debtId)).thenReturn(List.of());

        debtService.delete(debtId, userId);

        verify(debtRepository).delete(debt);
    }

    // -------------------------------------------------------------------------
    // T016 — US1: remboursements partiels, complet, recalcul
    // -------------------------------------------------------------------------

    @Test
    void should_createTransaction_when_partialRepay() {
        var user = buildUser();
        var debt = buildDebt(user);
        var account = buildAccount(user);
        var request = new DebtRepayRequest(account.getId(), new BigDecimal("50.00"));

        when(debtRepository.findByIdForUpdate(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.sumByDebtId(debtId)).thenReturn(BigDecimal.ZERO);
        when(accountRepository.findById(account.getId())).thenReturn(Optional.of(account));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));

        DebtResponse response = debtService.repay(debtId, request, userId);

        assertThat(response.rembourse()).isFalse();
        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void should_markAsRepaid_when_fullRepay() {
        var user = buildUser();
        var debt = buildDebt(user);
        var account = buildAccount(user);
        var request = new DebtRepayRequest(account.getId(), null);

        when(debtRepository.findByIdForUpdate(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.sumByDebtId(debtId)).thenReturn(BigDecimal.ZERO);
        when(accountRepository.findById(account.getId())).thenReturn(Optional.of(account));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));
        when(debtRepository.save(any(Debt.class))).thenReturn(debt);

        debtService.repay(debtId, request, userId);

        assertThat(debt.getRembourse()).isTrue();
        verify(debtRepository).save(debt);
    }

    @Test
    void should_useRemainingAmount_when_noAmountProvided() {
        var user = buildUser();
        var debt = buildDebt(user);
        var account = buildAccount(user);
        var request = new DebtRepayRequest(account.getId(), null);

        when(debtRepository.findByIdForUpdate(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.sumByDebtId(debtId)).thenReturn(new BigDecimal("30.00"));
        when(accountRepository.findById(account.getId())).thenReturn(Optional.of(account));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction tx = inv.getArgument(0);
            assertThat(tx.getMontant()).isEqualByComparingTo(new BigDecimal("70.00"));
            return tx;
        });
        when(debtRepository.save(any(Debt.class))).thenReturn(debt);

        debtService.repay(debtId, request, userId);

        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void should_reject_when_amountExceedsRemaining() {
        var user = buildUser();
        var debt = buildDebt(user);
        var request = new DebtRepayRequest(UUID.randomUUID(), new BigDecimal("200.00"));

        when(debtRepository.findByIdForUpdate(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.sumByDebtId(debtId)).thenReturn(BigDecimal.ZERO);

        assertThatThrownBy(() -> debtService.repay(debtId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("amount exceeds");
    }

    @Test
    void should_reject_when_debtAlreadyRepaid() {
        var user = buildUser();
        var debt = buildDebt(user);
        debt.setRembourse(true);
        var request = new DebtRepayRequest(UUID.randomUUID(), new BigDecimal("50.00"));

        when(debtRepository.findByIdForUpdate(debtId)).thenReturn(Optional.of(debt));

        assertThatThrownBy(() -> debtService.repay(debtId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("already repaid");
    }

    @Test
    void should_reject_when_accountInactive() {
        var user = buildUser();
        var debt = buildDebt(user);
        var account = buildAccount(user);
        account.setActif(false);
        var request = new DebtRepayRequest(account.getId(), new BigDecimal("50.00"));

        when(debtRepository.findByIdForUpdate(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.sumByDebtId(debtId)).thenReturn(BigDecimal.ZERO);
        when(accountRepository.findById(account.getId())).thenReturn(Optional.of(account));

        assertThatThrownBy(() -> debtService.repay(debtId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("inactive");
    }

    @Test
    void should_returnPayments_when_paymentsExist() {
        var user = buildUser();
        var debt = buildDebt(user);
        var account = buildAccount(user);
        var tx = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("50.00"))
                .date(LocalDate.now())
                .account(account)
                .build();

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.findByDebtIdOrderByDateDesc(debtId)).thenReturn(List.of(tx));

        var payments = debtService.getPayments(debtId, userId);

        assertThat(payments).hasSize(1);
        assertThat(payments.getFirst().amount()).isEqualByComparingTo(new BigDecimal("50.00"));
    }

    // -------------------------------------------------------------------------
    // T019 — US2: association compte, devise, conversion
    // -------------------------------------------------------------------------

    @Test
    void should_forceCurrency_when_accountProvided() {
        var user = buildUser();
        var account = buildAccount(user);
        account.setCurrency(Currency.USD);
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.now(), null, null, null, Currency.EUR,
                account.getId(), null, null, null);

        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(accountRepository.findById(account.getId())).thenReturn(Optional.of(account));
        when(categoryService.findSystemCategoryByNom("Dette", userId)).thenReturn(null);
        when(debtRepository.save(any(Debt.class))).thenAnswer(inv -> {
            Debt d = inv.getArgument(0);
            d.setId(debtId);
            assertThat(d.getCurrency()).isEqualTo(Currency.USD);
            return d;
        });
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        debtService.create(request, userId);

        verify(debtRepository).save(any(Debt.class));
    }

    @Test
    void should_useUserCurrency_when_noAccount() {
        var user = buildUser();
        var preference = UserPreference.builder().currencies(List.of(Currency.XOF)).build();
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.now(), null, null, null,
                null, null, null, null, null);

        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(preference);
        when(categoryService.findSystemCategoryByNom("Dette", userId)).thenReturn(null);
        when(debtRepository.save(any(Debt.class))).thenAnswer(inv -> {
            Debt d = inv.getArgument(0);
            d.setId(debtId);
            assertThat(d.getCurrency()).isEqualTo(Currency.XOF);
            return d;
        });
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        debtService.create(request, userId);

        verify(debtRepository).save(any(Debt.class));
    }

    @Test
    void should_convertAmount_when_accountCurrencyChanges() {
        var user = buildUser();
        var debt = buildDebt(user); // EUR
        var usdAccount = buildAccount(user);
        usdAccount.setCurrency(Currency.USD);
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.now(), null, null, null,
                null, usdAccount.getId(), null, null, null);

        var rate = ExchangeRate.builder()
                .baseCurrency(Currency.EUR).targetCurrency(Currency.USD)
                .rate(new BigDecimal("1.10")).build();

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(accountRepository.findById(usdAccount.getId())).thenReturn(Optional.of(usdAccount));
        when(exchangeRateRepository.findAllByUserId(userId)).thenReturn(List.of(rate));
        when(debtRepository.save(any(Debt.class))).thenReturn(debt);
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        debtService.update(debtId, request, userId);

        verify(debtRepository).save(any(Debt.class));
    }

    @Test
    void should_convertAmount_when_currencyChanges() {
        var user = buildUser();
        var debt = buildDebt(user); // EUR, montant=100
        var usdAccount = buildAccount(user);
        usdAccount.setCurrency(Currency.USD);
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.now(), null, null, null,
                null, usdAccount.getId(), null, null, null);

        var rate = ExchangeRate.builder()
                .baseCurrency(Currency.EUR).targetCurrency(Currency.USD)
                .rate(new BigDecimal("1.10")).build();

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(accountRepository.findById(usdAccount.getId())).thenReturn(Optional.of(usdAccount));
        when(exchangeRateRepository.findAllByUserId(userId)).thenReturn(List.of(rate));
        when(transactionRepository.findByDebtIdOrderByDateDesc(debt.getId())).thenReturn(List.of());
        when(debtRepository.save(any(Debt.class))).thenReturn(debt);
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        debtService.update(debtId, request, userId);

        // 100 * 1.10 = 110.00 USD
        assertThat(debt.getMontant()).isEqualByComparingTo(new BigDecimal("110.00"));
        assertThat(debt.getCurrency()).isEqualTo(Currency.USD);
    }

    @Test
    void should_reject_when_exchangeRateUnavailable() {
        var user = buildUser();
        var debt = buildDebt(user); // EUR
        var usdAccount = buildAccount(user);
        usdAccount.setCurrency(Currency.USD);
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.now(), null, null, null,
                null, usdAccount.getId(), null, null, null);

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(accountRepository.findById(usdAccount.getId())).thenReturn(Optional.of(usdAccount));
        when(exchangeRateRepository.findAllByUserId(userId)).thenReturn(List.of());

        assertThatThrownBy(() -> debtService.update(debtId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Exchange rate unavailable");
    }

    @Test
    void should_keepCurrency_when_accountDissociated() {
        var user = buildUser();
        var debt = buildDebt(user);
        debt.setCurrency(Currency.USD);
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.now(), null, null, null,
                null, null, null, null, null);

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(debtRepository.save(any(Debt.class))).thenAnswer(inv -> {
            Debt d = inv.getArgument(0);
            assertThat(d.getCurrency()).isEqualTo(Currency.USD);
            return d;
        });
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        debtService.update(debtId, request, userId);

        verify(debtRepository).save(any(Debt.class));
    }

    // -------------------------------------------------------------------------
    // T035 — US5: snooze rappel
    // -------------------------------------------------------------------------

    @Test
    void should_updateReminder_when_snooze() {
        var user = buildUser();
        var debt = buildDebt(user);
        debt.setReminderDate(LocalDate.of(2026, 3, 10));
        debt.setReminderTime(LocalTime.of(14, 0));
        var request = new DebtSnoozeRequest(LocalDate.of(2026, 3, 15), LocalTime.of(10, 0));

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(debtRepository.save(any(Debt.class))).thenReturn(debt);
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        DebtResponse response = debtService.snooze(debtId, request, userId);

        assertThat(response).isNotNull();
        verify(debtRepository).save(debt);
    }

    @Test
    void should_reject_when_noExistingReminder() {
        var user = buildUser();
        var debt = buildDebt(user);
        // No reminder set
        var request = new DebtSnoozeRequest(LocalDate.of(2026, 3, 15), LocalTime.of(10, 0));

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));

        assertThatThrownBy(() -> debtService.snooze(debtId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("no reminder configured");
    }

    // -------------------------------------------------------------------------
    // Post-audit FIX-1, FIX-4, FIX-6
    // -------------------------------------------------------------------------

    @Test
    void should_convertPayments_when_currencyChanges() {
        var user = buildUser();
        var debt = buildDebt(user); // EUR
        var usdAccount = buildAccount(user);
        usdAccount.setCurrency(Currency.USD);
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.now(), null, null, null,
                null, usdAccount.getId(), null, null, null);

        var rate = ExchangeRate.builder()
                .baseCurrency(Currency.EUR).targetCurrency(Currency.USD)
                .rate(new BigDecimal("1.10")).build();

        var payment = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("50.00"))
                .libelle("Remboursement - Alice")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .debt(debt)
                .user(user)
                .build();

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(accountRepository.findById(usdAccount.getId())).thenReturn(Optional.of(usdAccount));
        when(exchangeRateRepository.findAllByUserId(userId)).thenReturn(List.of(rate));
        when(transactionRepository.findByDebtIdOrderByDateDesc(debt.getId())).thenReturn(List.of(payment));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));
        when(debtRepository.save(any(Debt.class))).thenReturn(debt);
        when(transactionRepository.sumByDebtId(any(UUID.class))).thenReturn(BigDecimal.ZERO);

        debtService.update(debtId, request, userId);

        assertThat(payment.getMontant()).isEqualByComparingTo(new BigDecimal("55.00"));
    }

    @Test
    void should_detachAndAnnotatePayments_when_deleteDebt() {
        var user = buildUser();
        var debt = buildDebt(user);
        var payment = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("50.00"))
                .libelle("Remboursement - Alice")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .debt(debt)
                .user(user)
                .build();

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.findByDebtIdOrderByDateDesc(debtId)).thenReturn(List.of(payment));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));

        debtService.delete(debtId, userId);

        assertThat(payment.getDebt()).isNull();
        assertThat(payment.getLibelle()).contains("dette supprimée").contains("Alice");
        verify(transactionRepository).save(payment);
        verify(debtRepository).delete(debt);
    }

    @Test
    void should_reject_when_zeroAmount() {
        var user = buildUser();
        var debt = buildDebt(user);
        var request = new DebtRepayRequest(UUID.randomUUID(), BigDecimal.ZERO);

        when(debtRepository.findByIdForUpdate(debtId)).thenReturn(Optional.of(debt));
        when(transactionRepository.sumByDebtId(debtId)).thenReturn(BigDecimal.ZERO);

        assertThatThrownBy(() -> debtService.repay(debtId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("repayment amount must be positive");
    }
}
