package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.service.ImportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.Month;
import java.util.Arrays;
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
 * Duplicates already stored (KKS-387): reading the proposals, merging an imported transaction into the
 * one entered by hand, keeping one payment of a subscription. Synthetic fixtures reproducing the cases
 * measured on a real account: manual entries met again in a statement, subscription payments created
 * next to the real debit, double clicks.
 */
class HistoryCleanupDuplicatesIT extends AbstractHistoryCleanupIT {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final LocalDate DAY = HistoryCleanupTestData.DAY;
    private static final String DUPLICATES = "/v1/history-cleanup/duplicates";
    private static final String MERGE = "/v1/history-cleanup/duplicates/merge";
    private static final String MERGE_PAYMENTS = "/v1/history-cleanup/subscription-duplicates/merge";
    private static final String STALE = "CLEANUP_PROPOSAL_STALE";
    private static final String DEBT_LINK_MISSING = "CLEANUP_DEBT_LINK_MISSING";

    private static final String HEADER = """
            00000000000000;01/03/2026;12/03/2026;0;12/03/2026;0.00 EUR

            Date de l'opération;Libellé;Détail de l'écriture;Montant de l'opération;Devise
            """;
    private static final String BAKERY = "02/03/2026;CARTE X0000 01/03 ;CARTE X0000 01/03 BOULANGERIE TEST 110600000000001IOPD ;-3,20;EUR";

    @Autowired ImportService importService;
    @Autowired DebtRepository debtRepository;

    private Account account;

    @BeforeEach
    void setUp() {
        account = data.account(user, "0");
    }

    // -------------------------------------------------------------------------
    // Reading: imported duplicates
    // -------------------------------------------------------------------------

    @Test
    void should_pair_an_imported_transaction_with_the_manual_one_when_account_type_and_amount_agree() throws Exception {
        Category groceries = data.category(user, "Courses");
        Transaction imported = data.imported(user, account, "CARTE BOULANGERIE TEST", "3.20", DAY);
        Transaction manual = data.save(data.base(user, account, "Pain", "3.20", DAY.plusDays(1)).category(groceries));
        List<String> before = data.snapshot(user.getId());

        read(DUPLICATES)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.importedDuplicates", hasSize(1)))
                .andExpect(jsonPath("$.importedDuplicates[0].imported.id").value(imported.getId().toString()))
                .andExpect(jsonPath("$.importedDuplicates[0].imported.imported").value(true))
                .andExpect(jsonPath("$.importedDuplicates[0].imported.libelle").value("CARTE BOULANGERIE TEST"))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates", hasSize(1)))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].id").value(manual.getId().toString()))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].imported").value(false))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].libelle").value("Pain"))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].category.nom").value("Courses"))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].account.id").value(account.getId().toString()))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].debtId").value(nullValue()))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].subscriptionId").value(nullValue()))
                .andExpect(jsonPath("$.subscriptionDuplicates", hasSize(0)));
        assertThat(data.snapshot(user.getId())).isEqualTo(before);
    }

    @ParameterizedTest
    @CsvSource({"-5,1", "-6,0", "0,1", "2,1", "3,0"})
    void should_apply_the_window_of_the_import_matching_to_a_manual_transaction_without_subscription(
            int offset, int expectedProposals) throws Exception {
        data.imported(user, account, "CARTE TEST", "8.00", DAY);
        data.manual(user, account, "Manual", "8.00", DAY.plusDays(offset));

        read(DUPLICATES).andExpect(jsonPath("$.importedDuplicates", hasSize(expectedProposals)));
    }

    @ParameterizedTest
    @CsvSource({"-8,1", "-9,0", "8,1", "9,0"})
    void should_apply_the_wider_window_of_a_subscription_payment(int offset, int expectedProposals) throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", DAY.minusMonths(6));
        data.imported(user, account, "PRLV STREAMING", "9.99", DAY);
        data.save(data.base(user, account, "Streaming", "9.99", DAY.plusDays(offset)).subscription(subscription));

        read(DUPLICATES).andExpect(jsonPath("$.importedDuplicates", hasSize(expectedProposals)));
    }

    @Test
    void should_not_pair_transactions_that_differ_by_amount_type_or_account() throws Exception {
        data.imported(user, account, "CARTE TEST", "8.00", DAY);
        data.manual(user, account, "Other amount", "8.01", DAY);
        data.save(data.base(user, account, "Income", "8.00", DAY).type(TransactionType.RECETTE));
        data.manual(user, data.account(user, "0"), "Other account", "8.00", DAY);

        read(DUPLICATES).andExpect(jsonPath("$.importedDuplicates", hasSize(0)));
    }

    @Test
    void should_compare_amounts_whatever_their_scale() throws Exception {
        data.imported(user, account, "CARTE TEST", "8.50", DAY);
        data.manual(user, account, "Manual", "8.5", DAY);

        read(DUPLICATES).andExpect(jsonPath("$.importedDuplicates", hasSize(1)));
    }

    @Test
    void should_list_every_candidate_closest_date_first_when_an_imported_transaction_has_several() throws Exception {
        Transaction imported = data.imported(user, account, "CARTE TEST", "8.00", DAY);
        Transaction far = data.manual(user, account, "Far", "8.00", DAY.minusDays(3));
        Transaction near = data.manual(user, account, "Near", "8.00", DAY.plusDays(1));

        read(DUPLICATES)
                .andExpect(jsonPath("$.importedDuplicates", hasSize(1)))
                .andExpect(jsonPath("$.importedDuplicates[0].imported.id").value(imported.getId().toString()))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates", hasSize(2)))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].id").value(near.getId().toString()))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[1].id").value(far.getId().toString()));
    }

    @Test
    void should_put_a_manual_transaction_in_one_proposal_only_and_give_it_to_the_import_with_the_fewest_candidates()
            throws Exception {
        // Two identical coffees: the first import fits one entry, the second fits both.
        Transaction first = data.imported(user, account, "CARTE CAFE", "2.00", DAY);
        Transaction second = data.imported(user, account, "CARTE CAFE", "2.00", DAY.plusDays(4));
        Transaction early = data.manual(user, account, "Coffee 1", "2.00", DAY.minusDays(1));
        Transaction late = data.manual(user, account, "Coffee 2", "2.00", DAY.plusDays(3));

        read(DUPLICATES)
                .andExpect(jsonPath("$.importedDuplicates", hasSize(2)))
                .andExpect(jsonPath("$.importedDuplicates[0].imported.id").value(first.getId().toString()))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates", hasSize(1)))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates[0].id").value(early.getId().toString()))
                .andExpect(jsonPath("$.importedDuplicates[1].imported.id").value(second.getId().toString()))
                .andExpect(jsonPath("$.importedDuplicates[1].candidates[0].id").value(late.getId().toString()));
    }

    @Test
    void should_leave_an_import_without_proposal_when_its_only_candidate_is_taken_by_another() throws Exception {
        Transaction first = data.imported(user, account, "CARTE CAFE", "2.00", DAY);
        data.imported(user, account, "CARTE CAFE", "2.00", DAY.plusDays(1));
        data.manual(user, account, "Coffee", "2.00", DAY);

        read(DUPLICATES)
                .andExpect(jsonPath("$.importedDuplicates", hasSize(1)))
                .andExpect(jsonPath("$.importedDuplicates[0].imported.id").value(first.getId().toString()));
    }

    @Test
    void should_never_propose_adjustments_transfers_recurring_templates_or_other_users_transactions() throws Exception {
        data.imported(user, account, "CARTE TEST", "8.00", DAY);
        data.adjustment(user, account, "8.00", DAY);
        data.save(data.base(user, account, "Transfer leg", "8.00", DAY).transferId(UUID.randomUUID()));
        data.save(data.base(user, account, "Template", "8.00", DAY).isRecurring(true));
        User other = data.user();
        Account otherAccount = data.account(other, "0");
        data.imported(other, otherAccount, "CARTE TEST", "8.00", DAY);
        data.manual(other, otherAccount, "Manual", "8.00", DAY);

        read(DUPLICATES)
                .andExpect(jsonPath("$.importedDuplicates", hasSize(0)))
                .andExpect(jsonPath("$.subscriptionDuplicates", hasSize(0)));
    }

    @Test
    void should_show_nothing_of_one_user_to_another() throws Exception {
        User other = data.user();
        Account otherAccount = data.account(other, "0");
        data.imported(other, otherAccount, "CARTE TEST", "8.00", DAY);
        data.manual(other, otherAccount, "Manual", "8.00", DAY);

        read(DUPLICATES).andExpect(jsonPath("$.importedDuplicates", hasSize(0)));
        mockMvc.perform(get(DUPLICATES).header("Authorization", data.bearer(other)))
                .andExpect(jsonPath("$.importedDuplicates", hasSize(1)));
    }

    @Test
    void should_require_authentication() throws Exception {
        mockMvc.perform(get(DUPLICATES)).andExpect(status().isUnauthorized());
        mockMvc.perform(post(MERGE).contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isUnauthorized());
    }

    // -------------------------------------------------------------------------
    // Reading: subscription payments
    // -------------------------------------------------------------------------

    @Test
    void should_group_payments_of_one_subscription_in_one_period_and_suggest_the_oldest() throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        Transaction first = payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 11));
        payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 12));
        payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 20));
        payment(subscription, LocalDate.of(2026, Month.OCTOBER, 12));
        List<String> before = data.snapshot(user.getId());

        read(DUPLICATES)
                .andExpect(jsonPath("$.subscriptionDuplicates", hasSize(1)))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].subscriptionId").value(subscription.getId().toString()))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].subscriptionName").value("Streaming"))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].periodStart").value("2026-09-10"))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].periodEnd").value("2026-10-09"))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].suggestedKeepTransactionId").value(first.getId().toString()))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].transactions", hasSize(3)))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].transactions[0].subscriptionId")
                        .value(subscription.getId().toString()));
        assertThat(data.snapshot(user.getId())).isEqualTo(before);
    }

    @Test
    void should_suggest_the_imported_payment_when_the_period_holds_one() throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 11));
        Transaction imported = data.save(data.base(user, account, "PRLV STREAMING", "10.49", LocalDate.of(2026, Month.SEPTEMBER, 25))
                .subscription(subscription).importFingerprint("fingerprint-1"));

        read(DUPLICATES)
                .andExpect(jsonPath("$.subscriptionDuplicates", hasSize(1)))
                .andExpect(jsonPath("$.subscriptionDuplicates[0].suggestedKeepTransactionId").value(imported.getId().toString()));
    }

    @Test
    void should_not_propose_a_period_with_two_imported_payments() throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        for (String fingerprint : List.of("fingerprint-1", "fingerprint-2")) {
            data.save(data.base(user, account, "PRLV STREAMING", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12))
                    .subscription(subscription).importFingerprint(fingerprint));
        }

        read(DUPLICATES).andExpect(jsonPath("$.subscriptionDuplicates", hasSize(0)));
    }

    @Test
    void should_not_offer_in_a_group_a_payment_already_proposed_with_an_imported_transaction() throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        data.imported(user, account, "PRLV STREAMING", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12));
        payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 11));
        payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 11));

        read(DUPLICATES)
                .andExpect(jsonPath("$.importedDuplicates", hasSize(1)))
                .andExpect(jsonPath("$.importedDuplicates[0].candidates", hasSize(2)))
                .andExpect(jsonPath("$.subscriptionDuplicates", hasSize(0)));
    }

    // -------------------------------------------------------------------------
    // Merging an imported transaction into the manual one
    // -------------------------------------------------------------------------

    @Test
    void should_keep_the_manual_transaction_give_it_the_fingerprint_and_delete_the_imported_one() throws Exception {
        Category groceries = data.category(user, "Courses");
        Debt debt = data.debt(user, "50.00", false);
        Subscription subscription = data.subscription(user, "Streaming", "3.20", DAY.minusMonths(3));
        Transaction imported = data.imported(user, account, "CARTE BOULANGERIE TEST", "3.20", DAY);
        Transaction manual = data.save(data.base(user, account, "Pain", "3.20", DAY.plusDays(1))
                .category(groceries).debt(debt).subscription(subscription));

        merge(imported, manual)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.kept.id").value(manual.getId().toString()))
                .andExpect(jsonPath("$.kept.libelle").value("Pain"))
                .andExpect(jsonPath("$.kept.imported").value(true))
                .andExpect(jsonPath("$.removedIds[0]").value(imported.getId().toString()));

        Transaction kept = transactionRepository.findById(manual.getId()).orElseThrow();
        assertThat(kept.getLibelle()).isEqualTo("Pain");
        assertThat(kept.getDate()).isEqualTo(DAY.plusDays(1));
        assertThat(kept.getCategory().getId()).isEqualTo(groceries.getId());
        assertThat(kept.getDebt().getId()).isEqualTo(debt.getId());
        assertThat(kept.getSubscription().getId()).isEqualTo(subscription.getId());
        assertThat(kept.getImportFingerprint()).isEqualTo(imported.getImportFingerprint());
        assertThat(transactionRepository.findById(imported.getId())).isEmpty();
    }

    @Test
    void should_recognize_the_line_as_already_imported_when_the_statement_is_imported_again_after_the_merge()
            throws Exception {
        Account sgAccount = data.account(user, "0");
        importService.confirm(importService.upload(statement(), sgAccount.getId(), user.getId()).id(), false, user.getId());
        Transaction imported = transactionRepository.findByUserIdAndAccountIdAndDateBetween(
                user.getId(), sgAccount.getId(), LocalDate.of(2026, Month.JANUARY, 1), LocalDate.of(2026, Month.DECEMBER, 31))
                .getFirst();
        Transaction manual = data.manual(user, sgAccount, "Pain", "3.20", imported.getDate());

        merge(imported, manual).andExpect(status().isOk());

        ImportDraftResponse again = importService.upload(statement(), sgAccount.getId(), user.getId());
        assertThat(again.alreadyImportedCount()).isEqualTo(1);
        assertThat(again.readyCount()).isZero();
        assertThat(again.lines().getFirst().duplicateTransactionId()).isEqualTo(manual.getId());
    }

    @Test
    void should_give_the_subscription_of_the_imported_transaction_to_a_manual_one_that_has_none() throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", DAY.minusMonths(3));
        Transaction imported = data.save(data.base(user, account, "PRLV STREAMING", "9.99", DAY)
                .subscription(subscription).importFingerprint("fingerprint-1"));
        Transaction manual = data.manual(user, account, "Streaming", "9.99", DAY);

        merge(imported, manual).andExpect(status().isOk());

        assertThat(transactionRepository.findById(manual.getId()).orElseThrow().getSubscription().getId())
                .isEqualTo(subscription.getId());
    }

    @ParameterizedTest
    @CsvSource({"10.00,true,true", "15.00,true,false", "15.00,false,false"})
    void should_delete_an_imported_repayment_when_the_kept_one_repays_the_same_debt_and_reopen_the_debt_if_unsettled(
            String owed, boolean markedRepaid, boolean settled) throws Exception {
        Debt debt = data.debt(user, owed, markedRepaid);
        Transaction imported = data.save(data.base(user, account, "VIR ALEX", "10.00", DAY)
                .type(TransactionType.RECETTE).debt(debt).importFingerprint("fingerprint-1"));
        Transaction manual = data.save(data.base(user, account, "Alex repays", "10.00", DAY)
                .type(TransactionType.RECETTE).debt(debt));

        merge(imported, manual).andExpect(status().isOk());

        assertThat(transactionRepository.sumByDebtId(debt.getId())).isEqualByComparingTo("10.00");
        assertThat(debtRepository.findById(debt.getId()).orElseThrow().getRembourse()).isEqualTo(settled);
    }

    @ParameterizedTest
    @ValueSource(booleans = {false, true})
    void should_refuse_to_delete_a_debt_repayment_the_kept_transaction_does_not_carry(boolean keptRepaysAnotherDebt)
            throws Exception {
        Transaction imported = data.save(data.base(user, account, "VIR ALEX", "10.00", DAY)
                .debt(data.debt(user, "10.00", false)).importFingerprint("fingerprint-1"));
        Transaction.TransactionBuilder keptBuilder = data.base(user, account, "Alex", "10.00", DAY);
        if (keptRepaysAnotherDebt) {
            keptBuilder.debt(data.debt(user, "10.00", false));
        }
        Transaction manual = data.save(keptBuilder);

        merge(imported, manual)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value(DEBT_LINK_MISSING));

        assertThat(transactionRepository.findById(imported.getId())).isPresent();
        assertThat(transactionRepository.findById(manual.getId()).orElseThrow().getImportFingerprint()).isNull();
    }

    @ParameterizedTest
    @ValueSource(strings = {"manual-imported", "imported-kept", "amount", "type", "account", "window", "adjustment", "transfer", "recurring"})
    void should_refuse_a_pair_that_no_longer_satisfies_the_criteria_and_change_nothing(String reason) throws Exception {
        Transaction imported = data.imported(user, account, "CARTE TEST", "8.00", DAY);
        Transaction kept = switch (reason) {
            case "manual-imported" -> data.imported(user, account, "Manual", "8.00", DAY);
            case "amount" -> data.manual(user, account, "Manual", "8.01", DAY);
            case "type" -> data.save(data.base(user, account, "Manual", "8.00", DAY).type(TransactionType.RECETTE));
            case "account" -> data.manual(user, data.account(user, "0"), "Manual", "8.00", DAY);
            case "window" -> data.manual(user, account, "Manual", "8.00", DAY.plusDays(3));
            case "adjustment" -> data.adjustment(user, account, "8.00", DAY);
            case "transfer" -> data.save(data.base(user, account, "Manual", "8.00", DAY).transferId(UUID.randomUUID()));
            case "recurring" -> data.save(data.base(user, account, "Manual", "8.00", DAY).isRecurring(true));
            default -> data.manual(user, account, "Manual", "8.00", DAY);
        };
        Transaction removed = "imported-kept".equals(reason) ? data.manual(user, account, "Not imported", "8.00", DAY) : imported;
        List<String> before = data.snapshot(user.getId());

        merge(removed, kept).andExpect(status().isConflict()).andExpect(jsonPath("$.error").value(STALE));

        assertThat(data.snapshot(user.getId())).isEqualTo(before);
    }

    @Test
    void should_answer_not_found_and_change_nothing_when_a_transaction_belongs_to_another_user() throws Exception {
        User other = data.user();
        Account otherAccount = data.account(other, "0");
        Transaction othersImported = data.imported(other, otherAccount, "CARTE TEST", "8.00", DAY);
        Transaction othersManual = data.manual(other, otherAccount, "Manual", "8.00", DAY);
        Transaction ownImported = data.imported(user, account, "CARTE TEST", "8.00", DAY);
        Transaction ownManual = data.manual(user, account, "Manual", "8.00", DAY);
        List<String> before = data.snapshot(other.getId());

        merge(othersImported, othersManual).andExpect(status().isNotFound()).andExpect(jsonPath("$.error").value("NOT_FOUND"));
        merge(ownImported, othersManual).andExpect(status().isNotFound());
        merge(othersImported, ownManual).andExpect(status().isNotFound());

        assertThat(data.snapshot(other.getId())).isEqualTo(before);
        assertThat(transactionRepository.findById(ownImported.getId())).isPresent();
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "/v1/history-cleanup/duplicates/merge|{\"importedTransactionId\":\"%1$s\",\"keptTransactionId\":\"%1$s\"}",
            "/v1/history-cleanup/subscription-duplicates/merge|{\"keptTransactionId\":\"%1$s\",\"removedTransactionIds\":[\"%1$s\"]}"})
    void should_answer_bad_request_when_the_same_transaction_is_both_kept_and_removed(String pathAndBody) throws Exception {
        String[] parts = pathAndBody.split("\\|");

        postJson(parts[0], parts[1].formatted(UUID.randomUUID()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("BAD_REQUEST"));
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "/v1/history-cleanup/duplicates/merge|{\"importedTransactionId\":\"%s\"}|keptTransactionId",
            "/v1/history-cleanup/subscription-duplicates/merge|{\"keptTransactionId\":\"%s\",\"removedTransactionIds\":[]}|removedTransactionIds"})
    void should_answer_a_validation_error_when_a_field_is_missing_or_empty(String pathBodyAndField) throws Exception {
        String[] parts = pathBodyAndField.split("\\|");

        postJson(parts[0], parts[1].formatted(UUID.randomUUID()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.details[0].field").value(parts[2]));
    }

    // -------------------------------------------------------------------------
    // Keeping one payment of a subscription
    // -------------------------------------------------------------------------

    @Test
    void should_keep_one_payment_and_delete_the_others_when_a_double_click_created_three() throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        Transaction kept = payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 12));
        Transaction second = payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 12));
        Transaction third = payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 12));
        Transaction nextMonth = payment(subscription, LocalDate.of(2026, Month.OCTOBER, 12));

        mergePayments(kept, second, third)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.kept.id").value(kept.getId().toString()))
                .andExpect(jsonPath("$.removedIds", hasSize(2)));

        assertThat(transactionRepository.findById(kept.getId())).isPresent();
        assertThat(transactionRepository.findById(second.getId())).isEmpty();
        assertThat(transactionRepository.findById(third.getId())).isEmpty();
        assertThat(transactionRepository.findById(nextMonth.getId())).isPresent();
        read(DUPLICATES).andExpect(jsonPath("$.subscriptionDuplicates", hasSize(0)));
    }

    @Test
    void should_keep_the_imported_payment_the_user_chose_and_leave_its_fingerprint() throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        Transaction manual = payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 11));
        Transaction imported = data.save(data.base(user, account, "PRLV STREAMING", "10.49", LocalDate.of(2026, Month.SEPTEMBER, 25))
                .subscription(subscription).importFingerprint("fingerprint-1"));

        mergePayments(imported, manual).andExpect(status().isOk()).andExpect(jsonPath("$.kept.imported").value(true));

        assertThat(transactionRepository.findById(imported.getId()).orElseThrow().getImportFingerprint())
                .isEqualTo("fingerprint-1");
        assertThat(transactionRepository.findById(manual.getId())).isEmpty();
    }

    @ParameterizedTest
    @ValueSource(strings = {"other-period", "other-subscription", "no-subscription", "imported-removed", "adjustment", "kept-without-subscription"})
    void should_refuse_payments_that_do_not_belong_together_and_change_nothing(String reason) throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        Subscription other = data.subscription(user, "Music", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        Transaction kept = "kept-without-subscription".equals(reason)
                ? data.manual(user, account, "Manual", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12))
                : payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 12));
        Transaction removed = switch (reason) {
            case "other-period" -> payment(subscription, LocalDate.of(2026, Month.OCTOBER, 12));
            case "other-subscription" -> payment(other, LocalDate.of(2026, Month.SEPTEMBER, 12));
            case "no-subscription" -> data.manual(user, account, "Manual", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12));
            case "imported-removed" -> data.save(data.base(user, account, "PRLV", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12))
                    .subscription(subscription).importFingerprint("fingerprint-1"));
            case "adjustment" -> data.adjustment(user, account, "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12));
            default -> payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 13));
        };
        List<String> before = data.snapshot(user.getId());

        mergePayments(kept, removed).andExpect(status().isConflict()).andExpect(jsonPath("$.error").value(STALE));

        assertThat(data.snapshot(user.getId())).isEqualTo(before);
    }

    @Test
    void should_refuse_to_delete_a_payment_that_repays_a_debt_the_kept_one_does_not() throws Exception {
        Subscription subscription = data.subscription(user, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        Transaction kept = payment(subscription, LocalDate.of(2026, Month.SEPTEMBER, 12));
        Transaction removed = data.save(data.base(user, account, "Streaming", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12))
                .subscription(subscription).debt(data.debt(user, "9.99", false)));

        mergePayments(kept, removed).andExpect(status().isConflict()).andExpect(jsonPath("$.error").value(DEBT_LINK_MISSING));

        assertThat(transactionRepository.findById(removed.getId())).isPresent();
    }

    @Test
    void should_answer_not_found_and_change_nothing_when_a_payment_belongs_to_another_user() throws Exception {
        User other = data.user();
        Subscription othersSubscription = data.subscription(other, "Streaming", "9.99", LocalDate.of(2026, Month.JANUARY, 10));
        Account otherAccount = data.account(other, "0");
        Transaction first = data.save(data.base(other, otherAccount, "Streaming", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12))
                .subscription(othersSubscription));
        Transaction second = data.save(data.base(other, otherAccount, "Streaming", "9.99", LocalDate.of(2026, Month.SEPTEMBER, 12))
                .subscription(othersSubscription));
        List<String> before = data.snapshot(other.getId());

        mergePayments(first, second).andExpect(status().isNotFound());

        assertThat(data.snapshot(other.getId())).isEqualTo(before);
    }

    // -------------------------------------------------------------------------

    private Transaction payment(Subscription subscription, LocalDate date) {
        return data.save(data.base(user, account, subscription.getNom(), "9.99", date).subscription(subscription));
    }

    private ResultActions merge(Transaction imported, Transaction kept) throws Exception {
        return postJson(MERGE, OBJECT_MAPPER.writeValueAsString(Map.of(
                "importedTransactionId", imported.getId(), "keptTransactionId", kept.getId())));
    }

    private ResultActions mergePayments(Transaction kept, Transaction... removed) throws Exception {
        return postJson(MERGE_PAYMENTS, OBJECT_MAPPER.writeValueAsString(Map.of(
                "keptTransactionId", kept.getId(),
                "removedTransactionIds", Arrays.stream(removed).map(Transaction::getId).toList())));
    }

    private static MockMultipartFile statement() {
        return new MockMultipartFile("file", "releve.csv", "text/csv",
                (HEADER + BAKERY + "\n").getBytes(StandardCharsets.ISO_8859_1));
    }
}
