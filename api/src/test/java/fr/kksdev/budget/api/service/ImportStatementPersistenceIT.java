package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Month;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Migration V41 and the statement balance (KKS-384) on a real PostgreSQL: Flyway
 * creates the columns, Hibernate validates the mapping against them, and the
 * queries added for the balance run on the production engine. H2 (profile test)
 * generates its schema from the entities and proves none of it.
 */
@SpringBootTest
@Testcontainers
class ImportStatementPersistenceIT {

    private static final LocalDate BALANCE_DATE = LocalDate.of(2026, Month.OCTOBER, 1);

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

    @Autowired private UserRepository userRepository;
    @Autowired private AccountRepository accountRepository;
    @Autowired private ImportDraftRepository importDraftRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private EntityManager entityManager;

    @MockitoBean
    private BootstrapSeedRunner bootstrapSeedRunner;

    private Account saveAccount(User user) {
        Account account = Account.builder()
                .nom("Compte principal")
                .type(AccountType.COURANT)
                .soldeInitial(new BigDecimal("100.00"))
                .icone("🏦")
                .couleur("#000000")
                .bankCode("SG")
                .user(user)
                .build();
        account.setStatementProfileKey("REGISTRY:SG");
        account.setStatementAccountSuffix("1596");
        return accountRepository.saveAndFlush(account);
    }

    @Test
    void should_persist_and_read_back_the_statement_columns_of_an_account_and_a_draft() {
        User user = userRepository.saveAndFlush(User.builder()
                .email("statement-persistence-it@example.com").password("encoded").name("Statement IT").build());
        Account account = saveAccount(user);
        ImportDraft draft = importDraftRepository.saveAndFlush(ImportDraft.builder()
                .user(user)
                .account(account)
                .expiresAt(LocalDateTime.of(2026, Month.OCTOBER, 8, 12, 0))
                .statementProfileKey("REGISTRY:SG")
                .statementAccountSuffix("1596")
                .statementBalance(new BigDecimal("1842.37"))
                .statementBalanceDate(BALANCE_DATE)
                .build());
        entityManager.clear();

        Account reloadedAccount = accountRepository.findById(account.getId()).orElseThrow();
        ImportDraft reloadedDraft = importDraftRepository.findById(draft.getId()).orElseThrow();

        assertThat(reloadedAccount.getStatementProfileKey()).isEqualTo("REGISTRY:SG");
        assertThat(reloadedAccount.getStatementAccountSuffix()).isEqualTo("1596");
        assertThat(reloadedDraft.getStatementProfileKey()).isEqualTo("REGISTRY:SG");
        assertThat(reloadedDraft.getStatementAccountSuffix()).isEqualTo("1596");
        assertThat(reloadedDraft.getStatementBalance()).isEqualByComparingTo("1842.37");
        assertThat(reloadedDraft.getStatementBalanceDate()).isEqualTo(BALANCE_DATE);
    }

    @Test
    void should_leave_the_statement_columns_null_when_nothing_was_recorded() {
        User user = userRepository.saveAndFlush(User.builder()
                .email("statement-persistence-null-it@example.com").password("encoded").name("Statement IT").build());
        Account account = accountRepository.saveAndFlush(Account.builder()
                .nom("Compte sans releve").type(AccountType.COURANT).soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#000000").user(user).build());
        entityManager.clear();

        Account reloaded = accountRepository.findById(account.getId()).orElseThrow();

        assertThat(reloaded.getStatementProfileKey()).isNull();
        assertThat(reloaded.getStatementAccountSuffix()).isNull();
    }

    @Test
    void should_sum_signed_transactions_up_to_the_date_and_find_the_account_by_association_on_postgres() {
        User user = userRepository.saveAndFlush(User.builder()
                .email("statement-balance-it@example.com").password("encoded").name("Statement IT").build());
        Account account = saveAccount(user);
        save(account, user, TransactionType.RECETTE, "1500.00", BALANCE_DATE);
        save(account, user, TransactionType.DEPENSE, "600.00", BALANCE_DATE);
        save(account, user, TransactionType.AJUSTEMENT, "-50.00", BALANCE_DATE.minusDays(5));
        save(account, user, TransactionType.RECETTE, "999.00", BALANCE_DATE.plusDays(1));
        transactionRepository.flush();

        BigDecimal until = transactionRepository.calculateBalanceByAccountIdUntil(account.getId(), BALANCE_DATE);
        List<Account> found = accountRepository.findByUserIdAndActifTrueAndStatementProfileKeyAndStatementAccountSuffix(
                user.getId(), "REGISTRY:SG", "1596");

        assertThat(until).isEqualByComparingTo("850.00");
        assertThat(found).extracting(Account::getId).containsExactly(account.getId());
    }

    private void save(Account account, User user, TransactionType type, String amount, LocalDate date) {
        transactionRepository.save(Transaction.builder()
                .libelle("Test").montant(new BigDecimal(amount)).type(type).date(date)
                .account(account).user(user).build());
    }
}
