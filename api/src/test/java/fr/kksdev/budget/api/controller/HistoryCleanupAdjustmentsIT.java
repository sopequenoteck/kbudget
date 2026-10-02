package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.test.web.servlet.ResultActions;

import java.time.LocalDate;
import java.time.Month;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Balance adjustments (KKS-387): listed by account, flagged when the bank balance of the latest
 * statement shows they compensate nothing. Read only. Synthetic accounts and amounts.
 */
class HistoryCleanupAdjustmentsIT extends AbstractHistoryCleanupIT {

    private static final String ADJUSTMENTS = "/v1/history-cleanup/adjustments";
    private static final LocalDate EXPENSE_DAY = LocalDate.of(2026, Month.SEPTEMBER, 10);
    private static final LocalDate ADJUSTMENT_DAY = LocalDate.of(2026, Month.SEPTEMBER, 12);
    private static final LocalDate BALANCE_DAY = LocalDate.of(2026, Month.SEPTEMBER, 30);
    private static final LocalDate COUNTER_DAY = LocalDate.of(2026, Month.OCTOBER, 2);

    private Account account;
    private Transaction adjustment;

    @BeforeEach
    void setUp() {
        // Opening balance 100, an expense of 20, an adjustment of +5: the application shows 85.
        account = data.account(user, "100.00");
        data.manual(user, account, "Expense", "20.00", EXPENSE_DAY);
        adjustment = data.adjustment(user, account, "5.00", ADJUSTMENT_DAY);
    }

    @ParameterizedTest
    @CsvSource({"80.00,true", "85.00,false", "80.01,false", "79.99,false"})
    void should_flag_the_adjustment_when_without_it_the_balance_equals_the_bank_balance_to_the_cent(
            String bankBalance, boolean unnecessary) throws Exception {
        data.bankBalance(user, account, bankBalance, BALANCE_DAY);
        List<String> before = data.snapshot(user.getId());

        read()
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accounts", hasSize(1)))
                .andExpect(jsonPath("$.accounts[0].account.id").value(account.getId().toString()))
                .andExpect(jsonPath("$.accounts[0].bankBalance").value(Double.parseDouble(bankBalance)))
                .andExpect(jsonPath("$.accounts[0].bankBalanceDate").value("2026-09-30"))
                .andExpect(jsonPath("$.accounts[0].computedBalance").value(85.0))
                .andExpect(jsonPath("$.accounts[0].adjustments", hasSize(1)))
                .andExpect(jsonPath("$.accounts[0].adjustments[0].id").value(adjustment.getId().toString()))
                .andExpect(jsonPath("$.accounts[0].adjustments[0].montant").value(5.0))
                .andExpect(jsonPath("$.accounts[0].adjustments[0].date").value("2026-09-12"))
                .andExpect(jsonPath("$.accounts[0].adjustments[0].probablyUnnecessary").value(unnecessary));
        assertThat(data.snapshot(user.getId())).isEqualTo(before);
    }

    @Test
    void should_flag_a_negative_adjustment_the_same_way() throws Exception {
        Account other = data.account(user, "100.00");
        data.manual(user, other, "Expense", "20.00", EXPENSE_DAY);
        Transaction negative = data.adjustment(user, other, "-5.00", ADJUSTMENT_DAY);
        data.bankBalance(user, other, "80.00", BALANCE_DAY);

        read()
                .andExpect(jsonPath("$.accounts[?(@.account.id=='" + other.getId() + "')].adjustments[0].id")
                        .value(negative.getId().toString()))
                .andExpect(jsonPath("$.accounts[?(@.account.id=='" + other.getId() + "')].adjustments[0].probablyUnnecessary")
                        .value(true));
    }

    @ParameterizedTest
    @CsvSource({"-1,false", "0,true", "1,true"})
    void should_flag_only_an_adjustment_dated_up_to_the_bank_balance_date(int balanceOffset, boolean unnecessary)
            throws Exception {
        data.bankBalance(user, account, "80.00", ADJUSTMENT_DAY.plusDays(balanceOffset));

        read().andExpect(jsonPath("$.accounts[0].adjustments[0].probablyUnnecessary").value(unnecessary));
    }

    @ParameterizedTest
    @CsvSource({"20,80.00,false", "0,75.00,false", "-1,75.00,true"})
    void should_not_flag_an_adjustment_compensated_by_an_opposite_adjustment_dated_the_same_day_or_after(
            int counterOffset, String bankBalance, boolean unnecessary) throws Exception {
        data.adjustment(user, account, "-5.00", ADJUSTMENT_DAY.plusDays(counterOffset));
        data.bankBalance(user, account, bankBalance, BALANCE_DAY);

        read().andExpect(jsonPath(adjustmentFlag(adjustment)).value(unnecessary));
    }

    @ParameterizedTest
    @CsvSource({"-5.00,false", "-5.000,false", "-4.99,true", "5.00,true"})
    void should_compensate_only_an_adjustment_of_exactly_the_opposite_amount_whatever_its_scale(
            String counterAmount, boolean unnecessary) throws Exception {
        data.adjustment(user, account, counterAmount, COUNTER_DAY);
        data.bankBalance(user, account, "80.00", BALANCE_DAY);

        read().andExpect(jsonPath(adjustmentFlag(adjustment)).value(unnecessary));
    }

    @Test
    void should_let_one_opposite_adjustment_compensate_only_one_of_two_identical_adjustments() throws Exception {
        // 100 - 20 + 5 + 5 = 90 and bank balance 85: leaving out either +5 matches the bank.
        Transaction second = data.adjustment(user, account, "5.00", ADJUSTMENT_DAY.plusDays(1));
        data.adjustment(user, account, "-5.00", COUNTER_DAY);
        data.bankBalance(user, account, "85.00", BALANCE_DAY);

        read()
                .andExpect(jsonPath(adjustmentFlag(adjustment)).value(false))
                .andExpect(jsonPath(adjustmentFlag(second)).value(true));
    }

    @Test
    void should_never_let_an_adjustment_compensate_and_be_compensated_when_opposite_adjustments_alternate()
            throws Exception {
        // +5, -5, +5, -5: two disjoint pairs, only the earlier member of each is compensated.
        // 100 - 20 = 80 and bank balance 85: leaving out either -5 matches the bank.
        Transaction counter = data.adjustment(user, account, "-5.00", ADJUSTMENT_DAY.plusDays(1));
        Transaction third = data.adjustment(user, account, "5.00", ADJUSTMENT_DAY.plusDays(2));
        Transaction last = data.adjustment(user, account, "-5.00", ADJUSTMENT_DAY.plusDays(3));
        data.bankBalance(user, account, "85.00", BALANCE_DAY);

        read()
                .andExpect(jsonPath(adjustmentFlag(adjustment)).value(false))
                .andExpect(jsonPath(adjustmentFlag(counter)).value(true))
                .andExpect(jsonPath(adjustmentFlag(third)).value(false))
                .andExpect(jsonPath(adjustmentFlag(last)).value(true));
    }

    @Test
    void should_not_compensate_an_adjustment_by_an_opposite_adjustment_of_another_account() throws Exception {
        Account other = data.account(user, "0");
        data.adjustment(user, other, "-5.00", COUNTER_DAY);
        data.bankBalance(user, account, "80.00", BALANCE_DAY);

        read().andExpect(jsonPath("$.accounts[?(@.account.id=='" + account.getId() + "')].adjustments[0].probablyUnnecessary")
                .value(true));
    }

    @Test
    void should_list_the_adjustments_without_judgment_when_no_statement_gave_a_bank_balance() throws Exception {
        read()
                .andExpect(jsonPath("$.accounts", hasSize(1)))
                .andExpect(jsonPath("$.accounts[0].bankBalance").value(nullValue()))
                .andExpect(jsonPath("$.accounts[0].bankBalanceDate").value(nullValue()))
                .andExpect(jsonPath("$.accounts[0].computedBalance").value(nullValue()))
                .andExpect(jsonPath("$.accounts[0].adjustments[0].probablyUnnecessary").value(false));
    }

    @Test
    void should_use_the_latest_balance_date_and_ignore_a_draft_not_completed() throws Exception {
        data.bankBalance(user, account, "999.00", BALANCE_DAY.plusDays(5), ImportDraftStatus.PENDING);
        data.bankBalance(user, account, "70.00", BALANCE_DAY.minusDays(10));
        data.bankBalance(user, account, "80.00", BALANCE_DAY);

        read()
                .andExpect(jsonPath("$.accounts[0].bankBalance").value(80.0))
                .andExpect(jsonPath("$.accounts[0].adjustments[0].probablyUnnecessary").value(true));
    }

    @Test
    void should_group_the_adjustments_by_account_and_leave_out_the_accounts_without_any() throws Exception {
        data.account(user, "0");
        Account second = data.account(user, "0");
        data.adjustment(user, second, "1.00", ADJUSTMENT_DAY);
        data.adjustment(user, second, "2.00", ADJUSTMENT_DAY.plusDays(1));

        read()
                .andExpect(jsonPath("$.accounts", hasSize(2)))
                .andExpect(jsonPath("$.accounts[?(@.account.id=='" + second.getId() + "')].adjustments.length()").value(2));
    }

    @Test
    void should_return_an_empty_list_when_the_user_has_no_adjustment() throws Exception {
        User other = data.user();

        mockMvc.perform(get(ADJUSTMENTS).header("Authorization", data.bearer(other)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accounts", hasSize(0)));
    }

    @Test
    void should_show_nothing_of_another_user_and_take_no_bank_balance_from_another_user() throws Exception {
        User other = data.user();
        Account othersAccount = data.account(other, "0");
        data.adjustment(other, othersAccount, "7.00", ADJUSTMENT_DAY);
        data.bankBalance(other, othersAccount, "0.00", BALANCE_DAY);

        read()
                .andExpect(jsonPath("$.accounts", hasSize(1)))
                .andExpect(jsonPath("$.accounts[0].account.id").value(account.getId().toString()))
                .andExpect(jsonPath("$.accounts[0].bankBalance").value(nullValue()));
    }

    @Test
    void should_offer_no_way_to_delete_an_adjustment() throws Exception {
        mockMvc.perform(delete(ADJUSTMENTS + "/" + adjustment.getId()).header("Authorization", data.bearer(user)))
                .andExpect(status().is4xxClientError());

        assertThat(transactionRepository.findById(adjustment.getId())).isPresent();
    }

    @Test
    void should_require_authentication() throws Exception {
        mockMvc.perform(get(ADJUSTMENTS)).andExpect(status().isUnauthorized());
    }

    private static String adjustmentFlag(Transaction target) {
        return "$.accounts[0].adjustments[?(@.id=='" + target.getId() + "')].probablyUnnecessary";
    }

    private ResultActions read() throws Exception {
        return read(ADJUSTMENTS);
    }
}
