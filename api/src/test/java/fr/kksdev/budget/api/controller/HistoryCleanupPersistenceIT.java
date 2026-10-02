package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRuleRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.ApplicationContext;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDate;
import java.time.Month;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * The history cleanup (KKS-387) on a real PostgreSQL: Flyway builds the schema, Hibernate validates
 * it, and the three reads and the three writes run their queries on the production engine. H2
 * (profile test) generates its schema from the entities and proves none of it.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class HistoryCleanupPersistenceIT {

    private static final String BASE = "/v1/history-cleanup";
    private static final LocalDate DAY = LocalDate.of(2026, Month.SEPTEMBER, 15);

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

    @Autowired private MockMvc mockMvc;
    @Autowired private ApplicationContext context;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private DebtRepository debtRepository;
    @Autowired private CategoryRuleRepository categoryRuleRepository;

    @MockitoBean
    private BootstrapSeedRunner bootstrapSeedRunner;

    @Test
    void should_read_and_apply_every_proposal_of_the_cleanup_on_postgres() throws Exception {
        HistoryCleanupTestData data = new HistoryCleanupTestData(context);
        User user = data.user();
        String bearer = data.bearer(user);
        Account account = data.account(user, "100.00");
        Category groceries = data.category(user, "Courses");
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        Debt debt = data.debt(user, "15.00", true);

        // An imported repayment met again in the statement, both on the same debt.
        Transaction imported = data.save(data.base(user, account, "VIR ALEX", "10.00", DAY)
                .type(TransactionType.RECETTE).debt(debt).importFingerprint("fingerprint-1"));
        Transaction manual = data.save(data.base(user, account, "Alex repays", "10.00", DAY)
                .type(TransactionType.RECETTE).debt(debt).category(groceries));
        // A double click on a subscription.
        Transaction kept = data.save(data.base(user, account, "Streaming", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 11))
                .subscription(subscription));
        Transaction doubled = data.save(data.base(user, account, "Streaming", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12))
                .subscription(subscription));
        // Uncategorized, with a history for the merchant.
        data.save(data.base(user, account, "BOULANGERIE TEST", "4.10", DAY.minusMonths(1)).category(groceries));
        Transaction uncategorized = data.manual(user, account, "Boulangerie Test", "4.10", DAY);
        // An adjustment that the bank balance shows to be unnecessary.
        data.adjustment(user, account, "5.00", DAY);
        // 100 + 20 - 19.98 - 8.20 = 91.82 without the adjustment.
        data.bankBalance(user, account, "91.82", DAY);

        mockMvc.perform(get(BASE + "/duplicates").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.importedDuplicates", hasSize(1)))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].id").value(manual.getId().toString()))
                .andExpect(jsonPath("$.subscriptionDuplicates", hasSize(1)))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].suggestedKeepTransactionId").value(kept.getId().toString()));
        mockMvc.perform(get(BASE + "/uncategorized").header("Authorization", bearer))
                .andExpect(status().isOk())
                // Three merchants without category: the bakery has a proposal, the others have none.
                .andExpect(jsonPath("$.groups", hasSize(3)))
                .andExpect(jsonPath("$.groups[0].merchantKey").value("BOULANGERIE TEST"))
                .andExpect(jsonPath("$.groups[0].suggestion.source").value("HISTORY_AMOUNT"));
        mockMvc.perform(get(BASE + "/adjustments").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accounts[0].adjustments[0].probablyUnnecessary").value(true));

        mockMvc.perform(post(BASE + "/duplicates/merge").header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"importedTransactionId\":\"" + imported.getId()
                                + "\",\"keptTransactionId\":\"" + manual.getId() + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.kept.imported").value(true));
        mockMvc.perform(post(BASE + "/subscription-duplicates/merge").header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"keptTransactionId\":\"" + kept.getId()
                                + "\",\"removedTransactionIds\":[\"" + doubled.getId() + "\"]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.removedIds", hasSize(1)));
        mockMvc.perform(post(BASE + "/uncategorized/apply").header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"categoryId\":\"" + groceries.getId()
                                + "\",\"transactionIds\":[\"" + uncategorized.getId() + "\"]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categorizedCount").value(1));

        assertThat(transactionRepository.findById(imported.getId())).isEmpty();
        assertThat(transactionRepository.findById(doubled.getId())).isEmpty();
        assertThat(transactionRepository.findById(uncategorized.getId()).orElseThrow().getCategory().getId())
                .isEqualTo(groceries.getId());
        assertThat(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(user.getId())).hasSize(1);
        // 15 owed, 10 repaid once the duplicate repayment is gone: the debt is open again.
        assertThat(debtRepository.findById(debt.getId()).orElseThrow().getRembourse()).isFalse();
    }
}
