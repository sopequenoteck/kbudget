package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ImportLineUpdateRequest;
import fr.kksdev.budget.api.dto.response.ImportConfirmResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftLineResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.ImportDraftLineRepository;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Migration V42 and the reconciliation of statement lines (KKS-385) on a real PostgreSQL:
 * Flyway creates the columns, Hibernate validates the mapping against them, the list of
 * candidates survives its text column, and a match runs end to end on the production engine.
 * H2 (profile test) generates its schema from the entities and proves none of it.
 */
@SpringBootTest
@Testcontainers
class ImportReconciliationPersistenceIT {

    private static final LocalDate PURCHASE = LocalDate.of(2026, Month.AUGUST, 21);
    private static final LocalDate BOOKING = LocalDate.of(2026, Month.AUGUST, 24);

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
    @Autowired private ImportDraftLineRepository importDraftLineRepository;
    @Autowired private SubscriptionRepository subscriptionRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private ImportService importService;
    @Autowired private EntityManager entityManager;

    @MockitoBean
    private BootstrapSeedRunner bootstrapSeedRunner;

    private User saveUser(String email) {
        return userRepository.saveAndFlush(User.builder().email(email).password("encoded").name("Reconciliation IT").build());
    }

    private Account saveAccount(User user) {
        return accountRepository.saveAndFlush(Account.builder()
                .nom("Compte principal").type(AccountType.COURANT).soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#000000").bankCode("SG").user(user).build());
    }

    private Transaction saveManual(Account account, User user, String libelle, LocalDate date) {
        return transactionRepository.saveAndFlush(Transaction.builder()
                .libelle(libelle).montant(new BigDecimal("12.50")).type(TransactionType.DEPENSE).date(date)
                .account(account).user(user).build());
    }

    @Test
    void should_persist_and_read_back_the_reconciliation_columns_of_a_line_a_draft_and_a_subscription() {
        User user = saveUser("reconciliation-persistence-it@example.com");
        Account account = saveAccount(user);
        UUID matched = UUID.randomUUID();
        UUID firstCandidate = UUID.randomUUID();
        UUID secondCandidate = UUID.randomUUID();
        UUID subscriptionId = UUID.randomUUID();
        ImportDraft draft = importDraftRepository.saveAndFlush(ImportDraft.builder()
                .user(user).account(account).matchedCount(1)
                .expiresAt(LocalDateTime.of(2026, Month.OCTOBER, 8, 12, 0)).build());
        ImportDraftLine matchedLine = line(draft, 1);
        matchedLine.setMatchedTransactionId(matched);
        matchedLine.setSubscriptionId(subscriptionId);
        ImportDraftLine ambiguousLine = line(draft, 2);
        ambiguousLine.setStatus(ImportLineStatus.DUPLICATE);
        ambiguousLine.setMatchCandidateIds(List.of(firstCandidate, secondCandidate));
        importDraftLineRepository.saveAllAndFlush(List.of(matchedLine, ambiguousLine));
        Subscription subscription = subscriptionRepository.saveAndFlush(Subscription.builder()
                .nom("Streaming").montant(new BigDecimal("13.99")).frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2026, Month.JANUARY, 5)).actif(true).statementMerchantKey("STREAMING TEST")
                .user(user).build());
        entityManager.clear();

        ImportDraft reloadedDraft = importDraftRepository.findById(draft.getId()).orElseThrow();
        List<ImportDraftLine> reloadedLines = importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draft.getId());
        Subscription reloadedSubscription = subscriptionRepository.findById(subscription.getId()).orElseThrow();

        assertThat(reloadedDraft.getMatchedCount()).isEqualTo(1);
        assertThat(reloadedLines.get(0).getPurchaseDate()).isEqualTo(PURCHASE);
        assertThat(reloadedLines.get(0).getMatchedTransactionId()).isEqualTo(matched);
        assertThat(reloadedLines.get(0).getSubscriptionId()).isEqualTo(subscriptionId);
        assertThat(reloadedLines.get(0).getMatchCandidateIds()).isEmpty();
        assertThat(reloadedLines.get(1).getMatchedTransactionId()).isNull();
        assertThat(reloadedLines.get(1).getMatchCandidateIds()).containsExactly(firstCandidate, secondCandidate);
        assertThat(reloadedSubscription.getStatementMerchantKey()).isEqualTo("STREAMING TEST");
    }

    @Test
    void should_default_the_new_columns_when_nothing_was_recorded() {
        User user = saveUser("reconciliation-persistence-defaults-it@example.com");
        Subscription subscription = subscriptionRepository.saveAndFlush(Subscription.builder()
                .nom("Streaming").montant(new BigDecimal("13.99")).frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2026, Month.JANUARY, 5)).actif(true).user(user).build());
        ImportDraft draft = importDraftRepository.saveAndFlush(ImportDraft.builder()
                .user(user).account(saveAccount(user))
                .expiresAt(LocalDateTime.of(2026, Month.OCTOBER, 8, 12, 0)).build());
        entityManager.clear();

        assertThat(importDraftRepository.findById(draft.getId()).orElseThrow().getMatchedCount()).isZero();
        assertThat(subscriptionRepository.findById(subscription.getId()).orElseThrow().getStatementMerchantKey()).isNull();
    }

    @Test
    void should_match_settle_and_confirm_a_statement_line_on_postgres() {
        User user = saveUser("reconciliation-flow-it@example.com");
        Account account = saveAccount(user);
        Transaction first = saveManual(account, user, "Cafe 1", PURCHASE.minusDays(1));
        Transaction second = saveManual(account, user, "Cafe 2", PURCHASE);
        MockMultipartFile file = new MockMultipartFile("file", "releve.csv", "text/csv", ImportTestFiles.sgStatementOf(
                ImportTestFiles.sgBankHeader("00000000001596", "01/10/2026", "0.00 EUR"),
                "24/08/2026;CARTE X1596 21/08 ;CARTE X1596 21/08 CAFE DE LA PLACE 110600000000101IOPD ;-12,50;EUR"));

        ImportDraftResponse draft = importService.upload(file, account.getId(), user.getId());
        ImportDraftLineResponse ambiguous = draft.lines().getFirst();

        assertThat(ambiguous.status()).isEqualTo("DUPLICATE");
        assertThat(ambiguous.purchaseDate()).isEqualTo(PURCHASE);
        assertThat(ambiguous.matchCandidateIds()).containsExactly(first.getId(), second.getId());

        importService.updateLine(draft.id(), ambiguous.id(),
                new ImportLineUpdateRequest(null, null, second.getId(), null), user.getId());
        ImportConfirmResponse confirmed = importService.confirm(draft.id(), false, user.getId());

        assertThat(importService.getDraft(draft.id(), user.getId()).matchedCount()).isEqualTo(1);
        assertThat(confirmed.importedCount()).isZero();
        assertThat(confirmed.matchedCount()).isEqualTo(1);
        assertThat(transactionRepository.findById(second.getId()).orElseThrow().getImportFingerprint()).isNotNull();
        assertThat(transactionRepository.findById(first.getId()).orElseThrow().getImportFingerprint()).isNull();
    }

    private static ImportDraftLine line(ImportDraft draft, int number) {
        return ImportDraftLine.builder()
                .draft(draft).lineNumber(number).rawLabel("RAW").cleanLabel("Clean")
                .amount(new BigDecimal("12.50")).date(BOOKING).purchaseDate(PURCHASE)
                .transactionType(TransactionType.DEPENSE).build();
    }
}
