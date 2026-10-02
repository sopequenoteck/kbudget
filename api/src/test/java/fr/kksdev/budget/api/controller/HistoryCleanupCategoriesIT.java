package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.enums.CategoryRuleOrigin;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.CategoryRule;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Categories missing from the history (KKS-387): proposals grouped by merchant, then the category
 * the user chooses applied to a group. Synthetic merchants and amounts reproducing the measured
 * case: many uncategorized transactions, most of them categorizable from the history.
 */
class HistoryCleanupCategoriesIT extends AbstractHistoryCleanupIT {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final LocalDate DAY = HistoryCleanupTestData.DAY;
    private static final String PROPOSALS = "/v1/history-cleanup/uncategorized";
    private static final String APPLY = "/v1/history-cleanup/uncategorized/apply";

    private Account account;
    private Category groceries;
    private Category software;
    private Category storage;

    @BeforeEach
    void setUp() {
        account = data.account(user, "0");
        groceries = data.category(user, "Courses");
        software = data.category(user, "Logiciels");
        storage = data.category(user, "Stockage");
    }

    // -------------------------------------------------------------------------
    // Reading
    // -------------------------------------------------------------------------

    @Test
    void should_group_by_merchant_and_propose_the_category_of_the_history() throws Exception {
        categorized("BOULANGERIE TEST", "4.10", groceries, DAY.minusMonths(1));
        Transaction first = data.manual(user, account, "Boulangerie Test", "4.10", DAY);
        Transaction second = data.manual(user, account, "BOULANGERIE TEST 14/09", "3.20", DAY.plusDays(1));
        List<String> before = data.snapshot(user.getId());

        read()
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.groups", hasSize(1)))
                .andExpect(jsonPath("$.groups[0].merchantKey").value("BOULANGERIE TEST"))
                .andExpect(jsonPath("$.groups[0].type").value("DEPENSE"))
                .andExpect(jsonPath("$.groups[0].amount").value(nullValue()))
                .andExpect(jsonPath("$.groups[0].count").value(2))
                .andExpect(jsonPath("$.groups[0].totalAmount").value(7.30))
                .andExpect(jsonPath("$.groups[0].suggestion.category.id").value(groceries.getId().toString()))
                .andExpect(jsonPath("$.groups[0].suggestion.source").value("HISTORY_AMOUNT"))
                .andExpect(jsonPath("$.groups[0].transactions[0].id").value(first.getId().toString()))
                .andExpect(jsonPath("$.groups[0].transactions[1].id").value(second.getId().toString()));
        assertThat(data.snapshot(user.getId())).isEqualTo(before);
    }

    @ParameterizedTest
    @CsvSource({"4.10,false,HISTORY_AMOUNT", "9.99,false,HISTORY_MERCHANT", "4.10,true,RULE"})
    void should_propose_the_rule_then_the_history_at_the_same_amount_then_the_merchant_majority(
            String amount, boolean withRule, String expectedSource) throws Exception {
        categorized("BOULANGERIE TEST", "4.10", groceries, DAY.minusMonths(1));
        if (withRule) {
            categoryRuleRepository.save(CategoryRule.builder().user(user).pattern("boulangerie").category(software).build());
        }
        data.manual(user, account, "Boulangerie Test", amount, DAY);

        read()
                .andExpect(jsonPath("$.groups[0].suggestion.category.id")
                        .value((withRule ? software : groceries).getId().toString()))
                .andExpect(jsonPath("$.groups[0].suggestion.source").value(expectedSource));
    }

    @Test
    void should_list_the_groups_without_proposal_after_the_others_and_the_biggest_first() throws Exception {
        categorized("BOULANGERIE TEST", "4.10", groceries, DAY.minusMonths(1));
        data.manual(user, account, "Unknown shop", "5.00", DAY);
        data.manual(user, account, "Unknown shop", "6.00", DAY);
        data.manual(user, account, "Boulangerie Test", "4.10", DAY);
        data.manual(user, account, "Other shop", "2.00", DAY);

        read()
                .andExpect(jsonPath("$.groups", hasSize(3)))
                .andExpect(jsonPath("$.groups[0].merchantKey").value("BOULANGERIE TEST"))
                .andExpect(jsonPath("$.groups[1].merchantKey").value("UNKNOWN SHOP"))
                .andExpect(jsonPath("$.groups[1].suggestion").value(nullValue()))
                .andExpect(jsonPath("$.groups[1].count").value(2))
                .andExpect(jsonPath("$.groups[2].merchantKey").value("OTHER SHOP"));
    }

    @Test
    void should_split_a_merchant_by_amount_when_its_amounts_get_different_proposals() throws Exception {
        categorized("APPLE.COM/BILL", "10.00", software, DAY.minusMonths(1));
        categorized("APPLE", "2.99", storage, DAY.minusMonths(1));
        data.manual(user, account, "APPLE", "10.00", DAY);
        data.manual(user, account, "APPLE", "10.00", DAY.plusDays(1));
        data.manual(user, account, "APPLE", "2.99", DAY);

        read()
                .andExpect(jsonPath("$.groups", hasSize(2)))
                .andExpect(jsonPath("$.groups[0].merchantKey").value("APPLE"))
                .andExpect(jsonPath("$.groups[0].amount").value(10.0))
                .andExpect(jsonPath("$.groups[0].count").value(2))
                .andExpect(jsonPath("$.groups[0].suggestion.category.id").value(software.getId().toString()))
                .andExpect(jsonPath("$.groups[1].amount").value(2.99))
                .andExpect(jsonPath("$.groups[1].count").value(1))
                .andExpect(jsonPath("$.groups[1].suggestion.category.id").value(storage.getId().toString()));
    }

    @Test
    void should_keep_expenses_and_income_of_one_merchant_apart() throws Exception {
        categorized("BOULANGERIE TEST", "4.10", groceries, DAY.minusMonths(1));
        data.manual(user, account, "Boulangerie Test", "4.10", DAY);
        data.save(data.base(user, account, "Boulangerie Test", "4.10", DAY).type(TransactionType.RECETTE));

        read()
                .andExpect(jsonPath("$.groups", hasSize(2)))
                .andExpect(jsonPath("$.groups[0].type").value("DEPENSE"))
                .andExpect(jsonPath("$.groups[0].suggestion.category.id").value(groceries.getId().toString()))
                .andExpect(jsonPath("$.groups[1].type").value("RECETTE"))
                .andExpect(jsonPath("$.groups[1].suggestion").value(nullValue()));
    }

    @Test
    void should_group_labels_without_merchant_under_an_empty_key() throws Exception {
        data.manual(user, account, "12345", "5.00", DAY);
        data.manual(user, account, "67890", "6.00", DAY);

        read()
                .andExpect(jsonPath("$.groups", hasSize(1)))
                .andExpect(jsonPath("$.groups[0].merchantKey").value(""))
                .andExpect(jsonPath("$.groups[0].count").value(2))
                .andExpect(jsonPath("$.groups[0].suggestion").value(nullValue()));
    }

    @Test
    void should_leave_out_categorized_transactions_adjustments_recurring_templates_and_other_users() throws Exception {
        data.save(data.base(user, account, "Categorized", "1.00", DAY).category(groceries));
        data.save(data.base(user, account, "Adjustment", "1.00", DAY).type(TransactionType.AJUSTEMENT));
        data.save(data.base(user, account, "Template", "1.00", DAY).isRecurring(true));
        User other = data.user();
        data.manual(other, data.account(other, "0"), "Someone else", "1.00", DAY);

        read().andExpect(jsonPath("$.groups", hasSize(0)));
    }

    @Test
    void should_never_use_the_history_of_another_user() throws Exception {
        User other = data.user();
        Category othersCategory = data.category(other, "Courses");
        data.save(data.base(other, data.account(other, "0"), "BOULANGERIE TEST", "4.10", DAY).category(othersCategory));
        data.manual(user, account, "Boulangerie Test", "4.10", DAY);

        read().andExpect(jsonPath("$.groups[0].suggestion").value(nullValue()));
    }

    // -------------------------------------------------------------------------
    // Applying a category
    // -------------------------------------------------------------------------

    @Test
    void should_categorize_every_transaction_of_the_group_and_create_an_automatic_rule() throws Exception {
        Transaction first = data.manual(user, account, "Boulangerie Test", "4.10", DAY);
        Transaction second = data.manual(user, account, "BOULANGERIE TEST 14/09", "3.20", DAY);

        apply(groceries.getId(), first, second)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categorizedCount").value(2))
                .andExpect(jsonPath("$.skippedCount").value(0));

        assertThat(transactionRepository.findById(first.getId()).orElseThrow().getCategory().getId()).isEqualTo(groceries.getId());
        assertThat(transactionRepository.findById(second.getId()).orElseThrow().getCategory().getId()).isEqualTo(groceries.getId());
        assertThat(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(user.getId()))
                .singleElement()
                .satisfies(rule -> {
                    assertThat(rule.getPattern()).isEqualTo("BOULANGERIE TEST");
                    assertThat(rule.getOrigin()).isEqualTo(CategoryRuleOrigin.AUTO);
                    assertThat(rule.getCategory().getId()).isEqualTo(groceries.getId());
                });
        read().andExpect(jsonPath("$.groups", hasSize(0)));
    }

    @Test
    void should_create_the_rule_when_the_request_asks_for_it_explicitly() throws Exception {
        Transaction transaction = data.manual(user, account, "Boulangerie Test", "4.10", DAY);

        postJson(APPLY, body(groceries.getId(), Boolean.TRUE, transaction)).andExpect(status().isOk());

        assertThat(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(user.getId())).hasSize(1);
    }

    @Test
    void should_accept_a_category_of_the_system() throws Exception {
        Category adjustment = data.adjustmentCategory(user);
        Transaction transaction = data.manual(user, account, "Boulangerie Test", "4.10", DAY);

        apply(adjustment.getId(), transaction).andExpect(status().isOk()).andExpect(jsonPath("$.categorizedCount").value(1));
    }

    @Test
    void should_leave_alone_the_transactions_that_already_have_a_category_and_count_them() throws Exception {
        Transaction free = data.manual(user, account, "Boulangerie Test", "4.10", DAY);
        Transaction taken = data.save(data.base(user, account, "Boulangerie Test", "3.20", DAY).category(software));
        Transaction adjustment = data.save(data.base(user, account, "Adjustment", "3.20", DAY).type(TransactionType.AJUSTEMENT));
        Transaction template = data.save(data.base(user, account, "Template", "3.20", DAY).isRecurring(true));

        apply(groceries.getId(), free, taken, adjustment, template)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categorizedCount").value(1))
                .andExpect(jsonPath("$.skippedCount").value(3));

        assertThat(transactionRepository.findById(taken.getId()).orElseThrow().getCategory().getId()).isEqualTo(software.getId());
        assertThat(transactionRepository.findById(adjustment.getId()).orElseThrow().getCategory()).isNull();
        assertThat(transactionRepository.findById(template.getId()).orElseThrow().getCategory()).isNull();
    }

    @Test
    void should_redirect_an_automatic_rule_and_never_touch_a_rule_typed_by_the_user() throws Exception {
        categoryRuleRepository.save(CategoryRule.builder().user(user).pattern("BOULANGERIE TEST").category(software)
                .origin(CategoryRuleOrigin.AUTO).build());
        categoryRuleRepository.save(CategoryRule.builder().user(user).pattern("EPICERIE TEST").category(software).build());
        Transaction bakery = data.manual(user, account, "Boulangerie Test", "4.10", DAY);
        Transaction grocery = data.manual(user, account, "Epicerie Test", "4.10", DAY);

        apply(groceries.getId(), bakery).andExpect(status().isOk());
        apply(groceries.getId(), grocery).andExpect(status().isOk());

        assertThat(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(user.getId()))
                .extracting(rule -> rule.getPattern() + ":" + rule.getCategory().getId())
                .containsExactly("BOULANGERIE TEST:" + groceries.getId(), "EPICERIE TEST:" + software.getId());
    }

    @ParameterizedTest
    @CsvSource({
            "Boulangerie Test, BOULANGERIE TEST 2, false",
            "Boulangerie Test, Epicerie Test, true",
            "12345, 67890, true"})
    void should_create_no_rule_when_the_user_declines_or_the_group_has_no_single_merchant(
            String firstLabel, String secondLabel, boolean createRule) throws Exception {
        Transaction first = data.manual(user, account, firstLabel, "4.10", DAY);
        Transaction second = data.manual(user, account, secondLabel, "4.10", DAY);

        postJson(APPLY, body(groceries.getId(), createRule, first, second))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categorizedCount").value(2));

        assertThat(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(user.getId())).isEmpty();
    }

    @Test
    void should_answer_not_found_and_change_nothing_when_a_transaction_belongs_to_another_user() throws Exception {
        User other = data.user();
        Transaction others = data.manual(other, data.account(other, "0"), "Boulangerie Test", "4.10", DAY);
        Transaction own = data.manual(user, account, "Boulangerie Test", "4.10", DAY);
        List<String> before = data.snapshot(other.getId());

        apply(groceries.getId(), own, others).andExpect(status().isNotFound()).andExpect(jsonPath("$.error").value("NOT_FOUND"));

        assertThat(transactionRepository.findById(own.getId()).orElseThrow().getCategory()).isNull();
        assertThat(data.snapshot(other.getId())).isEqualTo(before);
        assertThat(categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(user.getId())).isEmpty();
    }

    @Test
    void should_answer_not_found_and_change_nothing_when_the_category_belongs_to_another_user() throws Exception {
        Category othersCategory = data.category(data.user(), "Courses");
        Transaction own = data.manual(user, account, "Boulangerie Test", "4.10", DAY);

        apply(othersCategory.getId(), own).andExpect(status().isNotFound());
        apply(UUID.randomUUID(), own).andExpect(status().isNotFound());

        assertThat(transactionRepository.findById(own.getId()).orElseThrow().getCategory()).isNull();
    }

    @Test
    void should_answer_a_validation_error_when_the_request_is_incomplete() throws Exception {
        postJson(APPLY, "{\"transactionIds\":[]}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.details", hasSize(2)));
    }

    @Test
    void should_require_authentication() throws Exception {
        mockMvc.perform(get(PROPOSALS)).andExpect(status().isUnauthorized());
        mockMvc.perform(post(APPLY).contentType(MediaType.APPLICATION_JSON).content("{}")).andExpect(status().isUnauthorized());
    }

    // -------------------------------------------------------------------------

    private Transaction categorized(String label, String amount, Category category, LocalDate date) {
        return data.save(data.base(user, account, label, amount, date).category(category));
    }

    private ResultActions read() throws Exception {
        return read(PROPOSALS);
    }

    private ResultActions apply(UUID categoryId, Transaction... transactions) throws Exception {
        return postJson(APPLY, body(categoryId, null, transactions));
    }

    private static String body(UUID categoryId, Object createRule, Transaction... transactions) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("categoryId", categoryId);
        body.put("transactionIds", Arrays.stream(transactions).map(Transaction::getId).toList());
        if (createRule != null) {
            body.put("createRule", createRule);
        }
        return OBJECT_MAPPER.writeValueAsString(body);
    }
}
