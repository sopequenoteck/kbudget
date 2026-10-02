package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import jakarta.persistence.EntityManager;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
class AccountRepositoryTest {

    @Autowired
    private AccountRepository accountRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EntityManager entityManager;

    private User user;
    private Account defaultAccount;
    private Account savingsAccount;
    private Account inactiveAccount;

    @BeforeEach
    void setUp() {
        user = userRepository.save(User.builder()
                .email("user@test.com")
                .password("encoded")
                .name("User")
                .build());

        defaultAccount = accountRepository.save(Account.builder()
                .nom("Compte Principal")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#3b82f6")
                .isDefault(true).actif(true)
                .user(user)
                .build());

        savingsAccount = accountRepository.save(Account.builder()
                .nom("Livret A")
                .type(AccountType.EPARGNE)
                .soldeInitial(new BigDecimal("5000.00"))
                .icone("🐷").couleur("#22c55e")
                .isDefault(false).actif(true)
                .user(user)
                .build());

        inactiveAccount = accountRepository.save(Account.builder()
                .nom("Ancien Compte")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#3b82f6")
                .isDefault(false).actif(false)
                .user(user)
                .build());

        entityManager.flush();
        entityManager.clear();
    }

    @Test
    void should_findActiveAccounts_when_mixedStatus() {
        List<Account> active = accountRepository.findByUserIdAndActifTrue(user.getId());

        assertThat(active).hasSize(2);
        assertThat(active).extracting(Account::getNom)
                .containsExactlyInAnyOrder("Compte Principal", "Livret A");
    }

    @Test
    void should_findAllAccounts_when_includingInactive() {
        List<Account> all = accountRepository.findByUserId(user.getId());

        assertThat(all).hasSize(3);
    }

    @Test
    void should_findDefaultAccount_when_exists() {
        Optional<Account> defaultOpt = accountRepository.findByUserIdAndIsDefaultTrue(user.getId());

        assertThat(defaultOpt).isPresent();
        assertThat(defaultOpt.get().getNom()).isEqualTo("Compte Principal");
    }

    @Test
    void should_calculateBalance_when_transactionsExist() {
        // Recharger le compte pour avoir la ref managée
        Account account = accountRepository.findById(defaultAccount.getId()).orElseThrow();

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("2000.00"))
                .libelle("Salaire")
                .type(TransactionType.RECETTE)
                .date(LocalDate.of(2026, 2, 1))
                .account(account)
                .user(user)
                .build());

        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal("150.00"))
                .libelle("Courses")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 5))
                .account(account)
                .user(user)
                .build());

        entityManager.flush();

        BigDecimal balance = transactionRepository.calculateBalanceByAccountId(account.getId());

        assertThat(balance).isEqualByComparingTo("1850.00");
    }

    @Test
    void should_calculateBalanceUntilDate_when_transactionsAreDatedAroundIt() {
        Account account = accountRepository.findById(defaultAccount.getId()).orElseThrow();
        saveTransaction(account, TransactionType.RECETTE, "2000.00", LocalDate.of(2026, Month.FEBRUARY, 1));
        saveTransaction(account, TransactionType.DEPENSE, "150.00", LocalDate.of(2026, Month.FEBRUARY, 5));
        saveTransaction(account, TransactionType.AJUSTEMENT, "-10.00", LocalDate.of(2026, Month.FEBRUARY, 5));
        saveTransaction(account, TransactionType.DEPENSE, "40.00", LocalDate.of(2026, Month.FEBRUARY, 6));
        entityManager.flush();

        BigDecimal untilBoundary = transactionRepository.calculateBalanceByAccountIdUntil(
                account.getId(), LocalDate.of(2026, Month.FEBRUARY, 5));
        BigDecimal untilBefore = transactionRepository.calculateBalanceByAccountIdUntil(
                account.getId(), LocalDate.of(2026, Month.JANUARY, 31));
        BigDecimal untilAfter = transactionRepository.calculateBalanceByAccountIdUntil(
                account.getId(), LocalDate.of(2026, Month.FEBRUARY, 6));

        assertThat(untilBoundary).isEqualByComparingTo("1840.00");
        assertThat(untilBefore).isEqualByComparingTo("0");
        assertThat(untilAfter)
                .isEqualByComparingTo("1800.00")
                .isEqualByComparingTo(transactionRepository.calculateBalanceByAccountId(account.getId()));
    }

    @Test
    void should_ignoreOtherAccounts_when_calculatingBalanceUntilDate() {
        Account other = accountRepository.findById(savingsAccount.getId()).orElseThrow();
        saveTransaction(other, TransactionType.RECETTE, "999.00", LocalDate.of(2026, Month.FEBRUARY, 1));
        entityManager.flush();

        BigDecimal balance = transactionRepository.calculateBalanceByAccountIdUntil(
                defaultAccount.getId(), LocalDate.of(2026, Month.DECEMBER, 31));

        assertThat(balance).isEqualByComparingTo("0");
    }

    @Test
    void should_findOnlyActiveAccountsOfUser_when_profileKeyAndSuffixMatch() {
        User otherUser = userRepository.save(User.builder()
                .email("other@test.com").password("encoded").name("Other").build());
        Account sameAssociationOfOtherUser = Account.builder()
                .nom("Compte Principal").type(AccountType.COURANT).soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#3b82f6").user(otherUser).build();
        sameAssociationOfOtherUser.setStatementProfileKey("REGISTRY:SG");
        sameAssociationOfOtherUser.setStatementAccountSuffix("1596");
        accountRepository.save(sameAssociationOfOtherUser);
        associate(defaultAccount, "REGISTRY:SG", "1596");
        associate(savingsAccount, "REGISTRY:SG", "9999");
        associate(inactiveAccount, "REGISTRY:SG", "1596");
        entityManager.flush();
        entityManager.clear();

        List<Account> found = accountRepository.findByUserIdAndActifTrueAndStatementProfileKeyAndStatementAccountSuffix(
                user.getId(), "REGISTRY:SG", "1596");

        assertThat(found).extracting(Account::getId).containsExactly(defaultAccount.getId());
    }

    @Test
    void should_findNothing_when_profileKeyDiffers() {
        associate(defaultAccount, "REGISTRY:SG", "1596");
        entityManager.flush();

        List<Account> found = accountRepository.findByUserIdAndActifTrueAndStatementProfileKeyAndStatementAccountSuffix(
                user.getId(), "CUSTOM:" + defaultAccount.getId(), "1596");

        assertThat(found).isEmpty();
    }

    private void associate(Account account, String profileKey, String suffix) {
        Account managed = accountRepository.findById(account.getId()).orElseThrow();
        managed.setStatementProfileKey(profileKey);
        managed.setStatementAccountSuffix(suffix);
        accountRepository.save(managed);
    }

    private void saveTransaction(Account account, TransactionType type, String amount, LocalDate date) {
        transactionRepository.save(Transaction.builder()
                .montant(new BigDecimal(amount))
                .libelle("Test")
                .type(type)
                .date(date)
                .account(account)
                .user(user)
                .build());
    }

    @Test
    void should_returnZeroBalance_when_noTransactions() {
        BigDecimal balance = transactionRepository.calculateBalanceByAccountId(savingsAccount.getId());

        assertThat(balance).isEqualByComparingTo("0");
    }

    @Test
    void should_detectDuplicateName_when_activeAccountExists() {
        boolean exists = accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrue(
                "compte principal", user.getId());

        assertThat(exists).isTrue();
    }

    @Test
    void should_notDetectDuplicate_when_accountInactive() {
        boolean exists = accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrue(
                "ancien compte", user.getId());

        assertThat(exists).isFalse();
    }

    @Test
    void should_countActiveAccounts_when_mixedStatus() {
        long count = accountRepository.countByUserIdAndActifTrue(user.getId());

        assertThat(count).isEqualTo(2);
    }
}
