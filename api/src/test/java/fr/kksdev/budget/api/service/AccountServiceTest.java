package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.AccountRequest;
import fr.kksdev.budget.api.dto.response.AccountResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.dto.response.TotalBalanceResponse;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.model.UserPreference;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AccountServiceTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CategoryService categoryService;

    @Mock
    private PreferenceService preferenceService;

    @Mock
    private DebtRepository debtRepository;

    @Mock
    private BankService bankService;

    @InjectMocks
    private AccountService accountService;

    private final UUID userId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var prefs = UserPreference.builder()
                .shopAccountId(null)
                .includeShopInBalance(false)
                .build();
        lenient().when(preferenceService.getOrCreatePreference(any(UUID.class))).thenReturn(prefs);
        lenient().when(bankService.resolveBank(any(Account.class))).thenReturn(
                new BankService.BankResolvedInfo("OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null));
    }

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
                .user(user)
                .build();
    }

    @Test
    void should_createAccount_when_validRequest() {
        var user = buildUser();
        var request = new AccountRequest("Livret A", AccountType.EPARGNE, new BigDecimal("5000.00"), null, null, null, null, null, null, null);
        var saved = Account.builder()
                .id(UUID.randomUUID())
                .nom("Livret A")
                .type(AccountType.EPARGNE)
                .soldeInitial(new BigDecimal("5000.00"))
                .icone("🐷")
                .couleur("#22c55e")
                .isDefault(false)
                .actif(true)
                .user(user)
                .build();

        when(accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrue("Livret A", userId)).thenReturn(false);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(accountRepository.save(any(Account.class))).thenReturn(saved);
        when(transactionRepository.calculateBalanceByAccountId(saved.getId())).thenReturn(BigDecimal.ZERO);

        AccountResponse response = accountService.createAccount(request, userId);

        assertThat(response.nom()).isEqualTo("Livret A");
        assertThat(response.type()).isEqualTo(AccountType.EPARGNE);
        assertThat(response.soldeInitial()).isEqualByComparingTo("5000.00");
        assertThat(response.solde()).isEqualByComparingTo("5000.00");
        assertThat(response.icone()).isEqualTo("🐷");
        assertThat(response.couleur()).isEqualTo("#22c55e");
        verify(accountRepository).save(any(Account.class));
    }

    @Test
    void should_applyDefaultIconAndColor_when_notProvided() {
        var user = buildUser();
        var request = new AccountRequest("Espèces", AccountType.ESPECES, null, null, null, null, null, null, null, null);
        var saved = Account.builder()
                .id(UUID.randomUUID())
                .nom("Espèces")
                .type(AccountType.ESPECES)
                .soldeInitial(BigDecimal.ZERO)
                .icone("💵")
                .couleur("#f59e0b")
                .isDefault(false)
                .actif(true)
                .user(user)
                .build();

        when(accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrue("Espèces", userId)).thenReturn(false);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(accountRepository.save(any(Account.class))).thenReturn(saved);
        when(transactionRepository.calculateBalanceByAccountId(saved.getId())).thenReturn(BigDecimal.ZERO);

        AccountResponse response = accountService.createAccount(request, userId);

        assertThat(response.icone()).isEqualTo("💵");
        assertThat(response.couleur()).isEqualTo("#f59e0b");
    }

    @Test
    void should_setDefault_when_requested() {
        var user = buildUser();
        var currentDefault = buildAccount(user);
        var newDefault = Account.builder()
                .id(UUID.randomUUID())
                .nom("Livret A")
                .type(AccountType.EPARGNE)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🐷")
                .couleur("#22c55e")
                .isDefault(false)
                .actif(true)
                .user(user)
                .build();

        when(accountRepository.findById(newDefault.getId())).thenReturn(Optional.of(newDefault));
        when(accountRepository.findByUserIdAndIsDefaultTrue(userId)).thenReturn(Optional.of(currentDefault));
        when(accountRepository.save(any(Account.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(transactionRepository.calculateBalanceByAccountId(newDefault.getId())).thenReturn(BigDecimal.ZERO);

        AccountResponse response = accountService.setDefault(newDefault.getId(), userId);

        assertThat(response.isDefault()).isTrue();
        assertThat(currentDefault.getIsDefault()).isFalse();
        verify(accountRepository, times(2)).save(any(Account.class));
    }

    @Test
    void should_preventDelete_when_transactionsExist() {
        var user = buildUser();
        var account = Account.builder()
                .id(accountId)
                .nom("Test")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#3b82f6")
                .isDefault(false)
                .actif(true)
                .user(user)
                .build();

        when(accountRepository.findById(accountId)).thenReturn(Optional.of(account));
        when(transactionRepository.existsByAccountId(accountId)).thenReturn(true);

        assertThatThrownBy(() -> accountService.deleteAccount(accountId, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Impossible de supprimer un compte avec des transactions rattachées");
    }

    @Test
    void should_preventDeactivation_when_isDefault() {
        var user = buildUser();
        var account = buildAccount(user);
        var request = new AccountRequest("Compte Principal", AccountType.COURANT, null, null, null, false, null, null, null, null);

        when(accountRepository.findById(accountId)).thenReturn(Optional.of(account));
        when(accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrueAndIdNot("Compte Principal", userId, accountId)).thenReturn(false);

        assertThatThrownBy(() -> accountService.updateAccount(accountId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Impossible de désactiver le compte par défaut");
    }

    @Test
    void should_deletePhysically_when_noDataAttached() {
        var user = buildUser();
        var account = Account.builder()
                .id(accountId)
                .nom("Vide")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#3b82f6")
                .isDefault(false)
                .actif(true)
                .user(user)
                .build();

        when(accountRepository.findById(accountId)).thenReturn(Optional.of(account));
        when(transactionRepository.existsByAccountId(accountId)).thenReturn(false);
        when(subscriptionRepository.existsByAccountId(accountId)).thenReturn(false);

        accountService.deleteAccount(accountId, userId);

        verify(accountRepository).delete(account);
    }

    @Test
    void should_createDefaultAccount_when_userRegisters() {
        var user = buildUser();
        when(accountRepository.save(any(Account.class))).thenAnswer(invocation -> invocation.getArgument(0));

        accountService.createDefaultAccount(user);

        verify(accountRepository).save(any(Account.class));
    }

    @Test
    void should_calculateBalance_when_accountHasTransactions() {
        var user = buildUser();
        var account = buildAccount(user);

        when(accountRepository.findById(accountId)).thenReturn(Optional.of(account));
        when(transactionRepository.calculateBalanceByAccountId(accountId)).thenReturn(new BigDecimal("150.00"));

        AccountResponse response = accountService.getAccountById(accountId, userId);

        assertThat(response.solde()).isEqualByComparingTo("150.00");
    }

    @Test
    void should_throw_when_accountNotFound() {
        when(accountRepository.findById(accountId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> accountService.getAccountById(accountId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Compte non trouvé");
    }

    @Test
    void should_throw_when_duplicateName() {
        var request = new AccountRequest("Existant", AccountType.COURANT, null, null, null, null, null, null, null, null);

        when(accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrue("Existant", userId)).thenReturn(true);

        assertThatThrownBy(() -> accountService.createAccount(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Un compte avec ce nom existe déjà");
    }

    @Test
    void should_returnActiveAccounts_when_includeInactiveFalse() {
        var user = buildUser();
        var account = buildAccount(user);

        when(accountRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(account));
        when(transactionRepository.calculateBalanceByAccountId(accountId)).thenReturn(BigDecimal.ZERO);

        List<AccountResponse> result = accountService.getAccounts(userId, false);

        assertThat(result).hasSize(1);
        verify(accountRepository).findByUserIdAndActifTrue(userId);
    }

    // --- Currency tests (T014b) ---

    @Test
    void should_useExplicitCurrency_when_providedInRequest() {
        var user = buildUser();
        var request = new AccountRequest("Compte XOF", AccountType.COURANT, null, null, null, null, Currency.XOF, null, null, null);
        var saved = Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte XOF")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#3b82f6")
                .currency(Currency.XOF)
                .isDefault(false)
                .actif(true)
                .user(user)
                .build();

        when(accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrue("Compte XOF", userId)).thenReturn(false);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(accountRepository.save(any(Account.class))).thenReturn(saved);
        when(transactionRepository.calculateBalanceByAccountId(saved.getId())).thenReturn(BigDecimal.ZERO);

        AccountResponse response = accountService.createAccount(request, userId);

        assertThat(response.currency()).isEqualTo("XOF");
    }

    @Test
    void should_useUserPrimaryCurrency_when_noCurrencyInRequest() {
        var user = User.builder().id(userId).email("test@mail.com").build();
        var preference = UserPreference.builder().currencies(List.of(Currency.XOF)).build();
        var request = new AccountRequest("Compte défaut", AccountType.COURANT, null, null, null, null, null, null, null, null);
        var saved = Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte défaut")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#3b82f6")
                .currency(Currency.XOF)
                .isDefault(false)
                .actif(true)
                .user(user)
                .build();

        when(accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrue("Compte défaut", userId)).thenReturn(false);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(preference);
        when(accountRepository.save(any(Account.class))).thenReturn(saved);
        when(transactionRepository.calculateBalanceByAccountId(saved.getId())).thenReturn(BigDecimal.ZERO);

        AccountResponse response = accountService.createAccount(request, userId);

        assertThat(response.currency()).isEqualTo("XOF");
    }

    @Test
    void should_rejectCurrencyChange_when_updatingAccount() {
        var user = buildUser();
        var account = buildAccount(user); // has EUR by default
        var request = new AccountRequest("Compte Principal", AccountType.COURANT, null, null, null, null, Currency.XOF, null, null, null);

        when(accountRepository.findById(accountId)).thenReturn(Optional.of(account));
        when(accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrueAndIdNot("Compte Principal", userId, accountId)).thenReturn(false);

        assertThatThrownBy(() -> accountService.updateAccount(accountId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("La devise d'un compte ne peut pas être modifiée");
    }

    @Test
    void should_rejectTransfer_when_differentCurrencies() {
        var user = buildUser();
        var fromAccount = Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte EUR")
                .type(AccountType.COURANT)
                .currency(Currency.EUR)
                .actif(true)
                .user(user)
                .build();
        var toAccount = Account.builder()
                .id(UUID.randomUUID())
                .nom("Compte XOF")
                .type(AccountType.COURANT)
                .currency(Currency.XOF)
                .actif(true)
                .user(user)
                .build();

        when(accountRepository.findById(fromAccount.getId())).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccount.getId())).thenReturn(Optional.of(toAccount));

        var transferRequest = new fr.kksdev.budget.api.dto.request.TransferRequest(
                fromAccount.getId(), toAccount.getId(), new BigDecimal("100.00"), null);

        assertThatThrownBy(() -> accountService.transfer(transferRequest, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Le virement entre comptes de devises différentes n'est pas autorisé");
    }

    // -------------------------------------------------------------------------
    // T026 — US3: getTotalBalance
    // -------------------------------------------------------------------------

    @Test
    void should_sumAccountBalances_when_noDebts() {
        var user = buildUser();
        var account = buildAccount(user);
        account.setSoldeInitial(new BigDecimal("1000.00"));
        var prefs = UserPreference.builder().currencies(List.of(Currency.EUR)).build();

        when(accountRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(account));
        when(transactionRepository.calculateBalanceByAccountId(accountId)).thenReturn(new BigDecimal("500.00"));
        when(debtRepository.findByUserIdAndRembourseFalse(userId)).thenReturn(List.of());
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);

        TotalBalanceResponse result = accountService.getTotalBalance(userId);

        assertThat(result.balances()).hasSize(1);
        assertThat(result.balances().getFirst().amount()).isEqualByComparingTo(new BigDecimal("1500.00"));
    }

    @Test
    void should_subtractEmprunt_when_debtWithAccount() {
        var user = buildUser();
        var account = buildAccount(user);
        account.setSoldeInitial(new BigDecimal("1000.00"));
        var debt = Debt.builder()
                .id(UUID.randomUUID()).personne("Alice").montant(new BigDecimal("200.00"))
                .sens(DebtType.EMPRUNT).currency(Currency.EUR).rembourse(false)
                .account(account).includeInBalance(false).user(user).build();
        var prefs = UserPreference.builder().currencies(List.of(Currency.EUR)).build();

        when(accountRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(account));
        when(transactionRepository.calculateBalanceByAccountId(accountId)).thenReturn(BigDecimal.ZERO);
        when(debtRepository.findByUserIdAndRembourseFalse(userId)).thenReturn(List.of(debt));
        when(transactionRepository.sumByDebtIds(any())).thenReturn(List.of());
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);

        TotalBalanceResponse result = accountService.getTotalBalance(userId);

        assertThat(result.balances().getFirst().amount()).isEqualByComparingTo(new BigDecimal("800.00"));
    }

    @Test
    void should_addPret_when_debtWithAccount() {
        var user = buildUser();
        var account = buildAccount(user);
        account.setSoldeInitial(new BigDecimal("1000.00"));
        var debt = Debt.builder()
                .id(UUID.randomUUID()).personne("Bob").montant(new BigDecimal("300.00"))
                .sens(DebtType.PRET).currency(Currency.EUR).rembourse(false)
                .account(account).includeInBalance(false).user(user).build();
        var prefs = UserPreference.builder().currencies(List.of(Currency.EUR)).build();

        when(accountRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(account));
        when(transactionRepository.calculateBalanceByAccountId(accountId)).thenReturn(BigDecimal.ZERO);
        when(debtRepository.findByUserIdAndRembourseFalse(userId)).thenReturn(List.of(debt));
        when(transactionRepository.sumByDebtIds(any())).thenReturn(List.of());
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);

        TotalBalanceResponse result = accountService.getTotalBalance(userId);

        assertThat(result.balances().getFirst().amount()).isEqualByComparingTo(new BigDecimal("1300.00"));
    }

    @Test
    void should_subtractEmprunt_when_includeInBalanceTrue() {
        var user = buildUser();
        var account = buildAccount(user);
        account.setSoldeInitial(new BigDecimal("1000.00"));
        var debt = Debt.builder()
                .id(UUID.randomUUID()).personne("Alice").montant(new BigDecimal("150.00"))
                .sens(DebtType.EMPRUNT).currency(Currency.EUR).rembourse(false)
                .account(null).includeInBalance(true).user(user).build();
        var prefs = UserPreference.builder().currencies(List.of(Currency.EUR)).build();

        when(accountRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(account));
        when(transactionRepository.calculateBalanceByAccountId(accountId)).thenReturn(BigDecimal.ZERO);
        when(debtRepository.findByUserIdAndRembourseFalse(userId)).thenReturn(List.of(debt));
        when(transactionRepository.sumByDebtIds(any())).thenReturn(List.of());
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);

        TotalBalanceResponse result = accountService.getTotalBalance(userId);

        assertThat(result.balances().getFirst().amount()).isEqualByComparingTo(new BigDecimal("850.00"));
    }

    @Test
    void should_ignoreDebt_when_noAccountAndIncludeInBalanceFalse() {
        var user = buildUser();
        var account = buildAccount(user);
        account.setSoldeInitial(new BigDecimal("1000.00"));
        var debt = Debt.builder()
                .id(UUID.randomUUID()).personne("Alice").montant(new BigDecimal("150.00"))
                .sens(DebtType.EMPRUNT).currency(Currency.EUR).rembourse(false)
                .account(null).includeInBalance(false).user(user).build();
        var prefs = UserPreference.builder().currencies(List.of(Currency.EUR)).build();

        when(accountRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(account));
        when(transactionRepository.calculateBalanceByAccountId(accountId)).thenReturn(BigDecimal.ZERO);
        when(debtRepository.findByUserIdAndRembourseFalse(userId)).thenReturn(List.of(debt));
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);

        TotalBalanceResponse result = accountService.getTotalBalance(userId);

        assertThat(result.balances().getFirst().amount()).isEqualByComparingTo(new BigDecimal("1000.00"));
    }

    @Test
    void should_groupByCurrency_when_multiCurrency() {
        var user = buildUser();
        var eurAccount = buildAccount(user);
        eurAccount.setSoldeInitial(new BigDecimal("1000.00"));
        var usdAccountId = UUID.randomUUID();
        var usdAccount = Account.builder()
                .id(usdAccountId).nom("USD Account").type(AccountType.COURANT)
                .soldeInitial(new BigDecimal("500.00")).icone("💵").couleur("#22c55e")
                .currency(Currency.USD).actif(true).user(user).build();
        var prefs = UserPreference.builder().currencies(List.of(Currency.EUR, Currency.USD)).build();

        when(accountRepository.findByUserIdAndActifTrue(userId)).thenReturn(List.of(eurAccount, usdAccount));
        when(transactionRepository.calculateBalanceByAccountId(accountId)).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.calculateBalanceByAccountId(usdAccountId)).thenReturn(BigDecimal.ZERO);
        when(debtRepository.findByUserIdAndRembourseFalse(userId)).thenReturn(List.of());
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);

        TotalBalanceResponse result = accountService.getTotalBalance(userId);

        assertThat(result.balances()).hasSize(2);
        assertThat(result.balances().get(0).currency()).isEqualTo(Currency.EUR);
        assertThat(result.balances().get(1).currency()).isEqualTo(Currency.USD);
    }
}
