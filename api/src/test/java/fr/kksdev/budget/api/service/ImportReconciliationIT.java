package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ImportLineBatchUpdateRequest;
import fr.kksdev.budget.api.dto.request.ImportLineUpdateRequest;
import fr.kksdev.budget.api.dto.response.ImportBalanceCheckResponse.SuspectTransaction;
import fr.kksdev.budget.api.dto.response.ImportConfirmResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftLineResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.dto.response.ImportMatchedTransactionResponse;
import fr.kksdev.budget.api.dto.response.SubscriptionPaymentResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.ImportDraftLineRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.Month;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.tuple;

/**
 * Reconciliation of statement lines with transactions entered by hand (KKS-385),
 * end to end: real Societe Generale profile, deduplication, matching, review,
 * confirmation, subscriptions, H2.
 *
 * <p>The statements are synthetic: fictitious merchants, zeroed references. They
 * reproduce the patterns observed on real data: card payments booked one to four days
 * after the purchase, direct debits without a purchase date, a furniture purchase.
 */
@SpringBootTest
@ActiveProfiles("test")
class ImportReconciliationIT {

    /** Fixed day for {@code SubscriptionPaymentService#pay}: a test must not depend on the day it runs (KKS-355). */
    private static final LocalDate TODAY = LocalDate.of(2026, Month.OCTOBER, 2);

    @TestConfiguration
    static class FixedClockConfig {
        @Bean
        @Primary
        Clock fixedClock() {
            return Clock.fixed(TODAY.atStartOfDay().toInstant(ZoneOffset.UTC), ZoneOffset.UTC);
        }
    }

    private static final String BALANCE_DATE = "01/10/2026";
    private static final String COFFEE_HOUSE = "CAFE DE LA PLACE";
    private static final String STREAMING_DEBIT_LABEL = "STREAMING TEST";
    /** Merchant key of the label of the debit above, as the statement gives it. */
    private static final String STREAMING_KEY = "STREAMING TEST";

    @Autowired ImportService importService;
    @Autowired SubscriptionPaymentService subscriptionPaymentService;
    @Autowired AccountService accountService;
    @Autowired UserRepository userRepository;
    @Autowired AccountRepository accountRepository;
    @Autowired CategoryRepository categoryRepository;
    @Autowired DebtRepository debtRepository;
    @Autowired ImportDraftLineRepository importDraftLineRepository;
    @Autowired SubscriptionRepository subscriptionRepository;
    @Autowired TransactionRepository transactionRepository;
    @Autowired JdbcTemplate jdbcTemplate;

    private User user;
    private UUID userId;
    private Account account;
    private UUID accountId;

    @BeforeEach
    void setUp() {
        user = createUser();
        userId = user.getId();
        account = createAccount(user, "1000.00");
        accountId = account.getId();
    }

    // -------------------------------------------------------------------------
    // Card payments: the purchase date is in the label, the booking comes later
    // -------------------------------------------------------------------------

    @ParameterizedTest(name = "booked {0} days after the purchase")
    @ValueSource(ints = {1, 2, 3, 4})
    void should_match_a_manual_entry_with_its_card_line_whatever_the_labels_when_booked_up_to_four_days_later(int days) {
        LocalDate purchase = LocalDate.of(2026, Month.AUGUST, 21);
        Transaction manual = saveManual(TransactionType.DEPENSE, "Tabac", "12.50", purchase);

        ImportDraftResponse draft = upload(card(purchase.plusDays(days), purchase, COFFEE_HOUSE, "-12,50"));

        ImportDraftLineResponse line = draft.lines().getFirst();
        assertThat(line.status()).isEqualTo("READY");
        assertThat(line.matchedTransactionId()).isEqualTo(manual.getId());
        assertThat(line.purchaseDate()).isEqualTo(purchase);
        assertThat(line.date()).isEqualTo(purchase.plusDays(days));
        assertThat(line.matchCandidateIds()).isEmpty();
        assertThat(draft.matchedCount()).isEqualTo(1);
        assertThat(draft.readyCount()).isEqualTo(1);
    }

    @Test
    void should_not_match_a_manual_entry_dated_three_days_from_the_purchase() {
        LocalDate purchase = LocalDate.of(2026, Month.AUGUST, 21);
        saveManual(TransactionType.DEPENSE, "Tabac", "12.50", purchase.minusDays(3));

        ImportDraftResponse draft = upload(card(purchase.plusDays(1), purchase, COFFEE_HOUSE, "-12,50"));

        assertThat(draft.lines().getFirst().matchedTransactionId()).isNull();
        assertThat(draft.matchedCount()).isZero();
    }

    @Test
    void should_create_the_transaction_at_the_purchase_date_when_the_line_matches_nothing() {
        LocalDate purchase = LocalDate.of(2026, Month.AUGUST, 21);
        ImportDraftResponse draft = upload(card(purchase.plusDays(3), purchase, COFFEE_HOUSE, "-12,50"));

        ImportConfirmResponse confirmed = importService.confirm(draft.id(), false, userId);

        assertThat(confirmed.importedCount()).isEqualTo(1);
        assertThat(confirmed.matchedCount()).isZero();
        Transaction created = onlyTransaction();
        assertThat(created.getDate()).isEqualTo(purchase);
        assertThat(created.getImportFingerprint()).isNotNull();
    }

    @Test
    void should_create_the_transaction_at_the_booking_date_when_the_label_has_no_purchase_date() {
        LocalDate booking = LocalDate.of(2026, Month.SEPTEMBER, 6);
        ImportDraftResponse draft = upload(debit(booking, "OPERATEUR TEST", "-9,99"));

        assertThat(draft.lines().getFirst().purchaseDate()).isNull();
        importService.confirm(draft.id(), false, userId);

        assertThat(onlyTransaction().getDate()).isEqualTo(booking);
    }

    @Test
    void should_leave_no_duplicate_when_eleven_manual_entries_meet_their_statement_lines() {
        // 11 manual entries and their bank lines: 355.90 would have been counted twice.
        List<Transaction> manuals = List.of(
                saveManual(TransactionType.DEPENSE, "Tabac", "4.50", date(Month.AUGUST, 20)),
                saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21)),
                saveManual(TransactionType.DEPENSE, "Courses", "8.90", date(Month.AUGUST, 25)),
                saveManual(TransactionType.DEPENSE, "Livre", "15.40", date(Month.AUGUST, 28)),
                saveManual(TransactionType.DEPENSE, "Cadeau", "23.60", date(Month.SEPTEMBER, 2)),
                saveManual(TransactionType.DEPENSE, "Resto", "31.20", date(Month.SEPTEMBER, 4)),
                saveManual(TransactionType.DEPENSE, "Icloud", "2.99", date(Month.SEPTEMBER, 5)),
                saveManual(TransactionType.DEPENSE, "Musique", "9.99", date(Month.SEPTEMBER, 10)),
                saveManual(TransactionType.DEPENSE, "Assurance", "19.99", date(Month.SEPTEMBER, 15)),
                saveManual(TransactionType.DEPENSE, "Commode chambre", "129.90", date(Month.SEPTEMBER, 12)),
                saveManual(TransactionType.DEPENSE, "Table basse", "97.43", date(Month.SEPTEMBER, 19)));
        assertThat(manuals.stream().map(Transaction::getMontant).reduce(BigDecimal.ZERO, BigDecimal::add))
                .isEqualByComparingTo("355.90");

        ImportDraftResponse draft = importService.upload(statement("644,10 EUR",
                // Card payments, 1 to 4 days after the purchase
                card(date(Month.AUGUST, 21), date(Month.AUGUST, 20), "BAR TABAC TEST", "-4,50"),
                card(date(Month.AUGUST, 24), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"),
                card(date(Month.AUGUST, 28), date(Month.AUGUST, 25), "EPICERIE TEST", "-8,90"),
                card(date(Month.SEPTEMBER, 1), date(Month.AUGUST, 28), "LIBRAIRIE DU COIN", "-15,40"),
                card(date(Month.SEPTEMBER, 3), date(Month.SEPTEMBER, 2), "BOUTIQUE CADEAUX TEST", "-23,60"),
                card(date(Month.SEPTEMBER, 9), date(Month.SEPTEMBER, 5), "RESTAURANT TEST", "-31,20"),
                // Direct debits: no purchase date, booked a day after, the same day, a day before the entry
                debit(date(Month.SEPTEMBER, 6), "OPERATEUR TEST", "-2,99"),
                debit(date(Month.SEPTEMBER, 10), "ABONNEMENT MUSIQUE TEST", "-9,99"),
                debit(date(Month.SEPTEMBER, 14), "ASSURANCE TEST", "-19,99"),
                // Furniture bought by card
                card(date(Month.SEPTEMBER, 15), date(Month.SEPTEMBER, 12), "PSP*BOUTIQUE TEST", "-129,90"),
                card(date(Month.SEPTEMBER, 22), date(Month.SEPTEMBER, 18), "MAGASIN DE MEUBLES TEST", "-97,43")),
                accountId, userId);

        assertThat(draft.totalLines()).isEqualTo(11);
        assertThat(draft.matchedCount()).isEqualTo(11);
        assertThat(draft.duplicateCount()).isZero();
        assertThat(draft.lines()).extracting(ImportDraftLineResponse::matchedTransactionId)
                .containsExactlyInAnyOrderElementsOf(manuals.stream().map(Transaction::getId).toList());
        assertThat(draft.projectedBalance()).isEqualByComparingTo("644.10");

        ImportConfirmResponse confirmed = importService.confirm(draft.id(), false, userId);

        assertThat(confirmed.importedCount()).isZero();
        assertThat(confirmed.matchedCount()).isEqualTo(11);
        assertThat(allTransactions()).hasSize(11).allSatisfy(t -> assertThat(t.getImportFingerprint()).isNotNull())
                .extracting(Transaction::getLibelle).contains("Tabac", "Icloud", "Commode chambre");
        assertThat(confirmed.balanceCheck().difference()).isEqualByComparingTo("0");
        assertThat(confirmed.balanceCheck().suspects()).isEmpty();
        assertThat(accountService.getAccountById(accountId, userId).solde()).isEqualByComparingTo("644.10");
    }

    @Test
    void should_keep_the_manual_transaction_as_it_is_and_only_give_it_the_fingerprint() {
        Category groceries = createCategory(user, "Courses");
        Transaction manual = saveManual(TransactionType.DEPENSE, "Pain du matin", "3.20", date(Month.AUGUST, 20));
        manual.setCategory(groceries);
        manual.setNote("note of the user");
        transactionRepository.save(manual);

        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 20), "BOULANGERIE TEST", "-3,20"));
        importService.confirm(draft.id(), false, userId);

        Transaction after = onlyTransaction();
        assertThat(after.getId()).isEqualTo(manual.getId());
        assertThat(after.getLibelle()).isEqualTo("Pain du matin");
        assertThat(after.getDate()).isEqualTo(date(Month.AUGUST, 20));
        assertThat(after.getNote()).isEqualTo("note of the user");
        assertThat(jdbcTemplate.queryForObject("SELECT category_id FROM transactions WHERE id = ?", UUID.class, manual.getId()))
                .isEqualTo(groceries.getId());
        assertThat(after.getImportFingerprint()).isNotNull();
    }

    @Test
    void should_recognize_every_line_when_the_same_statement_is_imported_again_after_the_matches() {
        saveManual(TransactionType.DEPENSE, "Tabac", "4.50", date(Month.AUGUST, 20));
        String line = card(date(Month.AUGUST, 21), date(Month.AUGUST, 20), "BAR TABAC TEST", "-4,50");
        importService.confirm(upload(line).id(), false, userId);

        ImportDraftResponse again = upload(line);

        assertThat(again.alreadyImportedCount()).isEqualTo(1);
        assertThat(again.matchedCount()).isZero();
        assertThat(importService.confirm(again.id(), false, userId).importedCount()).isZero();
        assertThat(allTransactions()).hasSize(1);
    }

    // -------------------------------------------------------------------------
    // Windows without purchase date: transfers and direct debits
    // -------------------------------------------------------------------------

    @Test
    void should_match_a_debt_repayment_entered_by_hand_with_its_transfer_and_keep_the_debt() {
        Debt debt = debtRepository.save(Debt.builder().personne("Ami test").montant(new BigDecimal("500.00"))
                .sens(DebtType.EMPRUNT).date(date(Month.JULY, 1)).rembourse(false).user(user).build());
        Transaction repayment = transactionRepository.save(Transaction.builder()
                .libelle("Remboursement Ami test").montant(new BigDecimal("220.00")).type(TransactionType.DEPENSE)
                .date(date(Month.SEPTEMBER, 10)).account(account).debt(debt).user(user).build());

        ImportDraftResponse draft = upload(
                "11/09/2026;VIR EUROPEEN EMIS;VIR EUROPEEN EMIS 4444444444 POUR: AMI TEST MOTIF: LOYER ;-220,00;EUR");
        importService.confirm(draft.id(), false, userId);

        assertThat(draft.lines().getFirst().matchedTransactionId()).isEqualTo(repayment.getId());
        assertThat(allTransactions()).hasSize(1);
        assertThat(jdbcTemplate.queryForObject("SELECT debt_id FROM transactions WHERE id = ?", UUID.class, repayment.getId()))
                .isEqualTo(debt.getId());
        assertThat(onlyTransaction().getImportFingerprint()).isNotNull();
    }

    // -------------------------------------------------------------------------
    // Several candidates: nothing is decided automatically
    // -------------------------------------------------------------------------

    @Test
    void should_block_the_line_with_its_candidates_when_two_manual_entries_fit() {
        Transaction first = saveManual(TransactionType.DEPENSE, "Cafe 1", "12.00", date(Month.AUGUST, 20));
        Transaction second = saveManual(TransactionType.DEPENSE, "Cafe 2", "12.00", date(Month.AUGUST, 21));

        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        ImportDraftLineResponse line = draft.lines().getFirst();
        assertThat(line.status()).isEqualTo("DUPLICATE");
        assertThat(line.matchedTransactionId()).isNull();
        assertThat(line.matchCandidateIds()).containsExactly(first.getId(), second.getId());
        assertThat(draft.duplicateCount()).isEqualTo(1);
        assertThat(draft.matchedCount()).isZero();
        UUID draftId = draft.id();
        assertThatThrownBy(() -> importService.confirm(draftId, false, userId))
                .isInstanceOf(IllegalArgumentException.class);
        assertThat(allTransactions()).allSatisfy(t -> assertThat(t.getImportFingerprint()).isNull());
    }

    @Test
    void should_settle_the_ambiguous_line_with_the_chosen_transaction_and_leave_the_other_alone() {
        saveManual(TransactionType.DEPENSE, "Cafe 1", "12.00", date(Month.AUGUST, 20));
        Transaction second = saveManual(TransactionType.DEPENSE, "Cafe 2", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        UUID lineId = draft.lines().getFirst().id();

        ImportDraftLineResponse settled = importService.updateLine(
                draft.id(), lineId, new ImportLineUpdateRequest(null, null, second.getId(), null), userId);

        assertThat(settled.status()).isEqualTo("READY");
        assertThat(settled.matchedTransactionId()).isEqualTo(second.getId());
        assertThat(settled.matchCandidateIds()).isEmpty();
        ImportDraftResponse reloaded = importService.getDraft(draft.id(), userId);
        assertThat(reloaded.matchedCount()).isEqualTo(1);
        assertThat(reloaded.duplicateCount()).isZero();

        ImportConfirmResponse confirmed = importService.confirm(draft.id(), false, userId);

        assertThat(confirmed.importedCount()).isZero();
        assertThat(confirmed.matchedCount()).isEqualTo(1);
        assertThat(transactionRepository.findById(second.getId()).orElseThrow().getImportFingerprint()).isNotNull();
        assertThat(allTransactions().stream().filter(t -> t.getImportFingerprint() == null)).hasSize(1);
    }

    @ParameterizedTest(name = "status {0}, clearMatch {1}")
    @CsvSource({",true", "READY,"})
    void should_create_a_new_transaction_when_the_user_gives_up_the_candidates_of_an_ambiguous_line(
            String status, Boolean clearMatch) {
        saveManual(TransactionType.DEPENSE, "Cafe 1", "12.00", date(Month.AUGUST, 20));
        saveManual(TransactionType.DEPENSE, "Cafe 2", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        ImportDraftLineResponse ready = importService.updateLine(draft.id(), draft.lines().getFirst().id(),
                new ImportLineUpdateRequest(null, status, null, clearMatch), userId);

        assertThat(ready.status()).isEqualTo("READY");
        assertThat(ready.matchCandidateIds()).isEmpty();
        assertThat(importService.confirm(draft.id(), false, userId).importedCount()).isEqualTo(1);
        assertThat(allTransactions()).hasSize(3);
    }

    @Test
    void should_match_the_first_line_only_when_two_identical_lines_meet_one_manual_entry() {
        saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        String line = card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00");

        ImportDraftResponse draft = upload(line, line);

        assertThat(draft.lines().get(0).matchedTransactionId()).isNotNull();
        assertThat(draft.lines().get(1).matchedTransactionId()).isNull();
        assertThat(draft.lines().get(1).status()).isEqualTo("READY");
        ImportConfirmResponse confirmed = importService.confirm(draft.id(), false, userId);
        assertThat(confirmed.importedCount()).isEqualTo(1);
        assertThat(confirmed.matchedCount()).isEqualTo(1);
        assertThat(allTransactions()).hasSize(2);
    }

    @Test
    void should_not_decide_for_the_user_when_a_batch_validation_reaches_an_ambiguous_line() {
        saveManual(TransactionType.DEPENSE, "Cafe 1", "12.00", date(Month.AUGUST, 20));
        saveManual(TransactionType.DEPENSE, "Cafe 2", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(
                card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"),
                debit(date(Month.SEPTEMBER, 6), "OPERATEUR TEST", "-9,99"));
        List<UUID> allLineIds = draft.lines().stream().map(ImportDraftLineResponse::id).toList();

        List<ImportDraftLineResponse> updated = importService.batchUpdateLines(
                draft.id(), new ImportLineBatchUpdateRequest(allLineIds, null, "READY"), userId);

        assertThat(updated).hasSize(1);
        ImportDraftResponse reloaded = importService.getDraft(draft.id(), userId);
        assertThat(reloaded.duplicateCount()).isEqualTo(1);
        assertThat(reloaded.lines().getFirst().matchCandidateIds()).hasSize(2);
    }

    @Test
    void should_keep_the_matches_when_a_batch_only_sets_the_category() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        Category category = createCategory(user, "Sorties");
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        List<ImportDraftLineResponse> updated = importService.batchUpdateLines(draft.id(),
                new ImportLineBatchUpdateRequest(List.of(draft.lines().getFirst().id()), category.getId(), null), userId);

        assertThat(updated.getFirst().categoryId()).isEqualTo(category.getId());
        assertThat(updated.getFirst().matchedTransactionId()).isEqualTo(manual.getId());
        assertThat(importService.getDraft(draft.id(), userId).matchedCount()).isEqualTo(1);
    }

    @Test
    void should_count_the_matched_lines_in_the_list_of_pending_drafts() {
        saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        assertThat(importService.listDrafts(userId)).singleElement()
                .satisfies(summary -> assertThat(summary.matchedCount()).isEqualTo(1));
    }

    // -------------------------------------------------------------------------
    // Detail of the matched transactions for the review (KKS-386)
    // -------------------------------------------------------------------------

    @Test
    void should_give_the_detail_of_the_matched_transaction_in_every_response_that_carries_the_line() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Tabac", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        UUID lineId = draft.lines().getFirst().id();
        ImportMatchedTransactionResponse expected = new ImportMatchedTransactionResponse(
                manual.getId(), date(Month.AUGUST, 21), "Tabac", new BigDecimal("12.00"), TransactionType.DEPENSE);

        ImportDraftLineResponse updated = importService.updateLine(draft.id(), lineId,
                new ImportLineUpdateRequest(null, "READY", null, null), userId);
        List<ImportDraftLineResponse> batched = importService.batchUpdateLines(draft.id(),
                new ImportLineBatchUpdateRequest(List.of(lineId), null, "READY"), userId);

        assertThat(draft.lines().getFirst().matchedTransaction()).isEqualTo(expected);
        assertThat(importService.getDraft(draft.id(), userId).lines().getFirst().matchedTransaction()).isEqualTo(expected);
        assertThat(updated.matchedTransaction()).isEqualTo(expected);
        assertThat(batched.getFirst().matchedTransaction()).isEqualTo(expected);
        assertThat(updated.matchCandidates()).isEmpty();
    }

    @Test
    void should_give_the_detail_of_the_candidates_of_an_ambiguous_line_in_the_order_of_their_identifiers() {
        saveManual(TransactionType.DEPENSE, "Cafe 1", "12.00", date(Month.AUGUST, 20));
        saveManual(TransactionType.DEPENSE, "Cafe 2", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        ImportDraftLineResponse line = importService.getDraft(draft.id(), userId).lines().getFirst();

        assertThat(line.matchedTransaction()).isNull();
        assertThat(line.matchCandidates().stream().map(ImportMatchedTransactionResponse::id).toList())
                .isEqualTo(line.matchCandidateIds());
        assertThat(line.matchCandidates())
                .extracting(ImportMatchedTransactionResponse::libelle, ImportMatchedTransactionResponse::date)
                .containsExactly(tuple("Cafe 1", date(Month.AUGUST, 20)), tuple("Cafe 2", date(Month.AUGUST, 21)));
    }

    @Test
    void should_leave_out_the_detail_of_a_transaction_deleted_since_the_upload() {
        Transaction first = saveManual(TransactionType.DEPENSE, "Cafe 1", "12.00", date(Month.AUGUST, 20));
        saveManual(TransactionType.DEPENSE, "Cafe 2", "12.00", date(Month.AUGUST, 21));
        Transaction matched = saveManual(TransactionType.DEPENSE, "Tabac", "4.50", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(
                card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"),
                card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), "BAR TABAC TEST", "-4,50"));
        transactionRepository.deleteById(first.getId());
        transactionRepository.deleteById(matched.getId());

        ImportDraftResponse reloaded = importService.getDraft(draft.id(), userId);

        ImportDraftLineResponse ambiguous = reloaded.lines().get(0);
        assertThat(ambiguous.matchCandidateIds()).hasSize(2);
        assertThat(ambiguous.matchCandidates()).extracting(ImportMatchedTransactionResponse::libelle).containsExactly("Cafe 2");
        assertThat(reloaded.lines().get(1).matchedTransactionId()).isEqualTo(matched.getId());
        assertThat(reloaded.lines().get(1).matchedTransaction()).isNull();
    }

    @Test
    void should_never_give_the_detail_of_a_transaction_of_another_user_or_of_another_account() {
        User otherUser = createUser();
        Transaction others = transactionRepository.save(
                manualOf(createAccount(otherUser, "0"), otherUser, "Secret libelle of another user", date(Month.AUGUST, 21)));
        Transaction elsewhere = transactionRepository.save(
                manualOf(createAccount(user, "0"), user, "Secret libelle of another account", date(Month.AUGUST, 21)));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        ImportDraftLine line = importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draft.id()).getFirst();
        line.setMatchedTransactionId(others.getId());
        line.setMatchCandidateIds(List.of(others.getId(), elsewhere.getId()));
        importDraftLineRepository.save(line);

        ImportDraftLineResponse response = importService.getDraft(draft.id(), userId).lines().getFirst();

        assertThat(response.matchedTransaction()).isNull();
        assertThat(response.matchCandidates()).isEmpty();
        assertThat(response.toString()).doesNotContain("Secret libelle");
    }

    // -------------------------------------------------------------------------
    // Review: choose a transaction, undo a match
    // -------------------------------------------------------------------------

    @Test
    void should_create_the_transaction_and_leave_the_manual_one_alone_when_the_user_undoes_a_match() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        assertThat(draft.matchedCount()).isEqualTo(1);

        ImportDraftLineResponse undone = importService.updateLine(
                draft.id(), draft.lines().getFirst().id(), new ImportLineUpdateRequest(null, null, null, true), userId);

        assertThat(undone.status()).isEqualTo("READY");
        assertThat(undone.matchedTransactionId()).isNull();
        assertThat(importService.getDraft(draft.id(), userId).matchedCount()).isZero();
        ImportConfirmResponse confirmed = importService.confirm(draft.id(), false, userId);
        assertThat(confirmed.importedCount()).isEqualTo(1);
        assertThat(confirmed.matchedCount()).isZero();
        assertThat(allTransactions()).hasSize(2);
        assertThat(transactionRepository.findById(manual.getId()).orElseThrow().getImportFingerprint()).isNull();
    }

    @Test
    void should_list_the_unmatched_manual_transaction_as_a_suspect_once_the_match_is_undone() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 22));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        importService.updateLine(draft.id(), draft.lines().getFirst().id(),
                new ImportLineUpdateRequest(null, null, null, true), userId);

        ImportConfirmResponse confirmed = importService.confirm(draft.id(), false, userId);

        assertThat(confirmed.balanceCheck().suspects()).extracting(SuspectTransaction::id).containsExactly(manual.getId());
    }

    @Test
    void should_match_a_line_with_a_transaction_chosen_outside_the_date_window() {
        Transaction faraway = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 1));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        assertThat(draft.lines().getFirst().matchedTransactionId()).isNull();

        ImportDraftLineResponse matched = importService.updateLine(draft.id(), draft.lines().getFirst().id(),
                new ImportLineUpdateRequest(null, "READY", faraway.getId(), null), userId);

        assertThat(matched.matchedTransactionId()).isEqualTo(faraway.getId());
        assertThat(importService.getDraft(draft.id(), userId).matchedCount()).isEqualTo(1);
        assertThat(importService.confirm(draft.id(), false, userId).matchedCount()).isEqualTo(1);
    }

    @Test
    void should_drop_the_match_when_the_matched_line_is_skipped() {
        saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        ImportDraftLineResponse skipped = importService.updateLine(draft.id(), draft.lines().getFirst().id(),
                new ImportLineUpdateRequest(null, "SKIPPED", null, null), userId);

        assertThat(skipped.status()).isEqualTo("SKIPPED");
        assertThat(skipped.matchedTransactionId()).isNull();
        assertThat(importService.getDraft(draft.id(), userId).matchedCount()).isZero();
    }

    @Test
    void should_keep_the_match_when_the_review_screen_asks_again_for_the_ready_status() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        Category category = createCategory(user, "Sorties");
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        ImportDraftLineResponse updated = importService.updateLine(draft.id(), draft.lines().getFirst().id(),
                new ImportLineUpdateRequest(category.getId(), "READY", null, null), userId);

        assertThat(updated.matchedTransactionId()).isEqualTo(manual.getId());
    }

    @Test
    void should_drop_the_match_of_every_skipped_line_in_a_batch() {
        saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        importService.batchUpdateLines(draft.id(),
                new ImportLineBatchUpdateRequest(List.of(draft.lines().getFirst().id()), null, "SKIPPED"), userId);

        ImportDraftResponse reloaded = importService.getDraft(draft.id(), userId);
        assertThat(reloaded.matchedCount()).isZero();
        assertThat(reloaded.lines().getFirst().matchedTransactionId()).isNull();
    }

    @Test
    void should_refuse_to_choose_a_transaction_that_does_not_fit_the_line() {
        Transaction otherAmount = saveManual(TransactionType.DEPENSE, "Cafe", "13.00", date(Month.AUGUST, 21));
        Transaction otherType = saveManual(TransactionType.RECETTE, "Remboursement", "12.00", date(Month.AUGUST, 21));
        Transaction imported = saveManual(TransactionType.DEPENSE, "Deja importe", "12.00", date(Month.AUGUST, 21));
        imported.setImportFingerprint("fingerprint of another line");
        transactionRepository.save(imported);
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        UUID draftId = draft.id();
        UUID lineId = draft.lines().getFirst().id();

        for (Transaction wrong : List.of(otherAmount, otherType, imported)) {
            UUID wrongId = wrong.getId();
            assertThatThrownBy(() -> updateMatch(draftId, lineId, wrongId, null))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }

    @Test
    void should_refuse_a_transaction_already_matched_with_another_line_of_the_draft() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        String line = card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00");
        ImportDraftResponse draft = upload(line, line);
        UUID draftId = draft.id();
        UUID secondLineId = draft.lines().get(1).id();

        UUID manualId = manual.getId();

        assertThatThrownBy(() -> updateMatch(draftId, secondLineId, manualId, null))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void should_refuse_to_combine_a_chosen_transaction_with_clear_match_or_to_undo_nothing() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "13.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        UUID draftId = draft.id();
        UUID lineId = draft.lines().getFirst().id();

        UUID manualId = manual.getId();

        assertThatThrownBy(() -> updateMatch(draftId, lineId, manualId, true))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("cannot be combined");
        assertThatThrownBy(() -> updateMatch(draftId, lineId, null, true))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("no match to undo");
    }

    @Test
    void should_refuse_to_match_a_line_that_is_skipped() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 1));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        UUID draftId = draft.id();
        UUID lineId = draft.lines().getFirst().id();
        importService.updateLine(draftId, lineId, new ImportLineUpdateRequest(null, "SKIPPED", null, null), userId);

        UUID manualId = manual.getId();

        assertThatThrownBy(() -> updateMatch(draftId, lineId, manualId, null))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("status");
    }

    @Test
    void should_refuse_to_confirm_when_the_matched_transaction_was_deleted_since_the_upload() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        transactionRepository.deleteById(manual.getId());
        UUID draftId = draft.id();

        assertThatThrownBy(() -> importService.confirm(draftId, false, userId))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("undo the match");
        assertThat(allTransactions()).isEmpty();
    }

    @Test
    void should_refuse_to_confirm_when_the_matched_transaction_amount_changed_since_the_upload() {
        Transaction manual = saveManual(TransactionType.DEPENSE, "Cafe", "12.00", date(Month.AUGUST, 21));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        manual.setMontant(new BigDecimal("13.00"));
        transactionRepository.save(manual);
        UUID draftId = draft.id();

        assertThatThrownBy(() -> importService.confirm(draftId, false, userId))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("undo the match");
        assertThat(transactionRepository.findById(manual.getId()))
                .hasValueSatisfying(kept -> assertThat(kept.getImportFingerprint()).isNull());
    }

    // -------------------------------------------------------------------------
    // Isolation
    // -------------------------------------------------------------------------

    @Test
    void should_never_match_a_transaction_of_another_user_or_of_another_account() {
        User otherUser = createUser();
        Account othersAccount = createAccount(otherUser, "0");
        transactionRepository.save(manualOf(othersAccount, otherUser, "Cafe d'un autre", date(Month.AUGUST, 21)));
        Account myOtherAccount = createAccount(user, "0");
        transactionRepository.save(manualOf(myOtherAccount, user, "Cafe autre compte", date(Month.AUGUST, 21)));

        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));

        assertThat(draft.lines().getFirst().matchedTransactionId()).isNull();
        assertThat(draft.lines().getFirst().status()).isEqualTo("READY");
        assertThat(draft.matchedCount()).isZero();
    }

    @Test
    void should_not_let_a_user_choose_the_transaction_of_another_user_or_account() {
        User otherUser = createUser();
        Transaction others = transactionRepository.save(
                manualOf(createAccount(otherUser, "0"), otherUser, "Cafe d'un autre", date(Month.AUGUST, 21)));
        Transaction elsewhere = transactionRepository.save(
                manualOf(createAccount(user, "0"), user, "Cafe autre compte", date(Month.AUGUST, 21)));
        ImportDraftResponse draft = upload(card(date(Month.AUGUST, 22), date(Month.AUGUST, 21), COFFEE_HOUSE, "-12,00"));
        UUID draftId = draft.id();
        UUID lineId = draft.lines().getFirst().id();

        for (Transaction foreign : List.of(others, elsewhere)) {
            UUID foreignId = foreign.getId();
            assertThatThrownBy(() -> updateMatch(draftId, lineId, foreignId, null))
                    .isInstanceOf(EntityNotFoundException.class);
        }
        assertThat(transactionRepository.findById(others.getId()).orElseThrow().getImportFingerprint()).isNull();
    }

    // -------------------------------------------------------------------------
    // Subscriptions
    // -------------------------------------------------------------------------

    @Test
    void should_match_a_subscription_payment_entered_by_pay_then_create_and_link_the_next_charge() {
        Category entertainment = createCategory(user, "Loisirs");
        Subscription subscription = saveSubscription("Streaming", "13.99", entertainment);
        SubscriptionPaymentResponse payment = subscriptionPaymentService.pay(subscription.getId(), userId);
        assertThat(payment.date()).isEqualTo(TODAY);

        // First statement: the debit of the month is the payment entered by hand.
        ImportDraftResponse first = upload(debit(date(Month.OCTOBER, 1), STREAMING_DEBIT_LABEL, "-13,99"));
        assertThat(first.lines().getFirst().matchedTransactionId()).isEqualTo(payment.id());
        assertThat(first.lines().getFirst().subscriptionId()).isNull();
        importService.confirm(first.id(), false, userId);
        assertThat(allTransactions()).hasSize(1);
        assertThat(subscriptionRepository.findById(subscription.getId()).orElseThrow().getStatementMerchantKey())
                .isEqualTo(STREAMING_KEY);

        // Next statement: no payment entered, the debit is created and linked to the subscription.
        ImportDraftResponse second = upload(debit(date(Month.NOVEMBER, 1), STREAMING_DEBIT_LABEL, "-13,99"));
        assertThat(second.lines().getFirst().matchedTransactionId()).isNull();
        assertThat(second.lines().getFirst().subscriptionId()).isEqualTo(subscription.getId());
        ImportConfirmResponse confirmed = importService.confirm(second.id(), false, userId);

        assertThat(confirmed.importedCount()).isEqualTo(1);
        Transaction created = transactionRepository.findBySubscriptionIdAndUserIdOrderByDateDesc(subscription.getId(), userId)
                .getFirst();
        assertThat(created.getDate()).isEqualTo(date(Month.NOVEMBER, 1));
        assertThat(created.getImportFingerprint()).isNotNull();
        assertThat(jdbcTemplate.queryForObject("SELECT category_id FROM transactions WHERE id = ?", UUID.class, created.getId()))
                .isEqualTo(entertainment.getId());
        assertThat(transactionRepository.countBySubscriptionIdAndUserId(subscription.getId(), userId)).isEqualTo(2);
    }

    @Test
    void should_link_a_charge_to_the_one_subscription_with_the_same_label_and_amount() {
        Subscription small = saveSubscription("Stockage 1", "2.99", null);
        Subscription large = saveSubscription("Stockage 2", "9.99", null);
        learnLabel(small, STREAMING_KEY);
        learnLabel(large, STREAMING_KEY);

        ImportDraftResponse draft = upload(
                debit(date(Month.SEPTEMBER, 6), STREAMING_DEBIT_LABEL, "-9,99"),
                debit(date(Month.SEPTEMBER, 7), STREAMING_DEBIT_LABEL, "-4,99"));

        assertThat(draft.lines().get(0).subscriptionId()).isEqualTo(large.getId());
        assertThat(draft.lines().get(1).subscriptionId()).isNull();
    }

    @Test
    void should_not_link_a_charge_to_ambiguous_inactive_or_foreign_subscriptions() {
        // 9.99: two active subscriptions alike. 7.77: an inactive one. 5.55: one of another user.
        learnLabel(saveSubscription("Stockage 1", "9.99", null), STREAMING_KEY);
        learnLabel(saveSubscription("Stockage 2", "9.99", null), STREAMING_KEY);
        Subscription inactive = saveSubscription("Ancien", "7.77", null);
        inactive.setActif(false);
        learnLabel(inactive, STREAMING_KEY);
        User otherUser = createUser();
        learnLabel(subscriptionRepository.save(Subscription.builder().nom("D'un autre")
                .montant(new BigDecimal("5.55")).frequence(Frequency.MENSUEL).dateDebut(date(Month.JANUARY, 5))
                .actif(true).user(otherUser).build()), STREAMING_KEY);

        ImportDraftResponse draft = upload(
                debit(date(Month.SEPTEMBER, 6), STREAMING_DEBIT_LABEL, "-9,99"),
                debit(date(Month.SEPTEMBER, 7), STREAMING_DEBIT_LABEL, "-7,77"),
                debit(date(Month.SEPTEMBER, 8), STREAMING_DEBIT_LABEL, "-5,55"));

        assertThat(draft.lines()).extracting(ImportDraftLineResponse::subscriptionId).containsOnlyNulls();
    }

    @Test
    void should_create_the_charge_without_link_when_the_subscription_was_deleted_since_the_upload() {
        Subscription subscription = saveSubscription("Streaming", "9.99", null);
        learnLabel(subscription, STREAMING_KEY);
        ImportDraftResponse draft = upload(debit(date(Month.SEPTEMBER, 6), STREAMING_DEBIT_LABEL, "-9,99"));
        assertThat(draft.lines().getFirst().subscriptionId()).isEqualTo(subscription.getId());
        subscriptionRepository.deleteById(subscription.getId());

        ImportConfirmResponse confirmed = importService.confirm(draft.id(), false, userId);

        assertThat(confirmed.importedCount()).isEqualTo(1);
        assertThat(jdbcTemplate.queryForObject("SELECT subscription_id FROM transactions WHERE account_id = ?", UUID.class, accountId)).isNull();
    }

    @Test
    void should_match_a_subscription_payment_within_eight_days_and_not_beyond() {
        Subscription subscription = saveSubscription("Streaming", "13.99", null);
        Transaction payment = transactionRepository.save(Transaction.builder()
                .libelle("Streaming").montant(new BigDecimal("13.99")).type(TransactionType.DEPENSE)
                .date(date(Month.SEPTEMBER, 20)).account(account).subscription(subscription).user(user).build());

        ImportDraftResponse near = upload(debit(date(Month.SEPTEMBER, 28), STREAMING_DEBIT_LABEL, "-13,99"));
        assertThat(near.lines().getFirst().matchedTransactionId()).isEqualTo(payment.getId());
        importService.deleteDraft(near.id(), userId);

        ImportDraftResponse far = upload(debit(date(Month.SEPTEMBER, 29), STREAMING_DEBIT_LABEL, "-13,99"));
        assertThat(far.lines().getFirst().matchedTransactionId()).isNull();
    }

    // -------------------------------------------------------------------------
    // pay(): idempotent
    // -------------------------------------------------------------------------

    @Test
    void should_create_a_single_payment_when_pay_is_called_twice_for_the_same_period() {
        Subscription subscription = saveSubscription("Streaming", "13.99", null);

        SubscriptionPaymentResponse first = subscriptionPaymentService.pay(subscription.getId(), userId);
        SubscriptionPaymentResponse second = subscriptionPaymentService.pay(subscription.getId(), userId);

        assertThat(second.id()).isEqualTo(first.id());
        assertThat(transactionRepository.countBySubscriptionIdAndUserId(subscription.getId(), userId)).isEqualTo(1);
    }

    @Test
    void should_count_a_charge_imported_for_the_period_as_the_payment_of_the_subscription() {
        Subscription subscription = saveSubscription("Streaming", "13.99", null);
        learnLabel(subscription, STREAMING_KEY);
        ImportDraftResponse draft = upload(debit(date(Month.OCTOBER, 1), STREAMING_DEBIT_LABEL, "-13,99"));
        importService.confirm(draft.id(), false, userId);

        SubscriptionPaymentResponse payment = subscriptionPaymentService.pay(subscription.getId(), userId);

        assertThat(payment.date()).isEqualTo(date(Month.OCTOBER, 1));
        assertThat(transactionRepository.countBySubscriptionIdAndUserId(subscription.getId(), userId)).isEqualTo(1);
    }

    // -------------------------------------------------------------------------

    private static LocalDate date(Month month, int day) {
        return LocalDate.of(2026, month, day);
    }

    private static String card(LocalDate booking, LocalDate purchase, String merchant, String amount) {
        String day = "%02d/%02d".formatted(purchase.getDayOfMonth(), purchase.getMonthValue());
        return "%s;CARTE X1596 %s ;CARTE X1596 %s %s 110600000000101IOPD ;%s;EUR".formatted(
                frenchDate(booking), day, day, merchant, amount);
    }

    private static String debit(LocalDate booking, String label, String amount) {
        return "%s;PRELEVEMENT EUROPE;PRELEVEMENT EUROPEEN 3333333333 DE: %s ID: FR00ZZZ000002 REF: ref-0202 ;%s;EUR"
                .formatted(frenchDate(booking), label, amount);
    }

    private static String frenchDate(LocalDate date) {
        return "%02d/%02d/%d".formatted(date.getDayOfMonth(), date.getMonthValue(), date.getYear());
    }

    private static MockMultipartFile statement(String balance, String... operations) {
        return new MockMultipartFile("file", "releve.csv", "text/csv", ImportTestFiles.sgStatementOf(
                ImportTestFiles.sgBankHeader("0000000000001596", BALANCE_DATE, balance), operations));
    }

    private ImportDraftLineResponse updateMatch(UUID draftId, UUID lineId, UUID matchedTransactionId, Boolean clearMatch) {
        return importService.updateLine(draftId, lineId,
                new ImportLineUpdateRequest(null, null, matchedTransactionId, clearMatch), userId);
    }

    private ImportDraftResponse upload(String... operations) {
        return importService.upload(statement("0,00 EUR", operations), accountId, userId);
    }

    private List<Transaction> allTransactions() {
        return transactionRepository.findByUserIdAndAccountIdAndDateBetween(
                userId, accountId, LocalDate.of(2000, Month.JANUARY, 1), LocalDate.of(2100, Month.JANUARY, 1));
    }

    private Transaction onlyTransaction() {
        List<Transaction> all = allTransactions();
        assertThat(all).hasSize(1);
        return all.getFirst();
    }

    private Transaction saveManual(TransactionType type, String libelle, String amount, LocalDate date) {
        return transactionRepository.save(Transaction.builder()
                .libelle(libelle).montant(new BigDecimal(amount)).type(type).date(date)
                .account(account).user(user).build());
    }

    private static Transaction manualOf(Account owningAccount, User owner, String libelle, LocalDate date) {
        return Transaction.builder()
                .libelle(libelle).montant(new BigDecimal("12.00")).type(TransactionType.DEPENSE).date(date)
                .account(owningAccount).user(owner).build();
    }

    private Subscription saveSubscription(String name, String amount, Category category) {
        return subscriptionRepository.save(Subscription.builder()
                .nom(name).montant(new BigDecimal(amount)).frequence(Frequency.MENSUEL)
                .dateDebut(date(Month.JANUARY, 5)).actif(true).category(category).account(account).user(user)
                .build());
    }

    private void learnLabel(Subscription subscription, String key) {
        subscription.setStatementMerchantKey(key);
        subscriptionRepository.save(subscription);
    }

    private Category createCategory(User owner, String name) {
        return categoryRepository.save(Category.builder().nom(name).icone("🏷").couleur("#000000").user(owner).build());
    }

    private User createUser() {
        return userRepository.save(User.builder()
                .email("reconciliation-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Reconciliation")
                .build());
    }

    private Account createAccount(User owner, String openingBalance) {
        return accountRepository.save(Account.builder()
                // Unique name: PostgreSQL enforces UNIQUE(nom, user_id), which the generated H2 schema ignores.
                .nom("Compte " + UUID.randomUUID().toString().substring(0, 8))
                .type(AccountType.COURANT)
                .soldeInitial(new BigDecimal(openingBalance))
                .icone("🏦")
                .couleur("#000000")
                .bankCode("SG")
                .user(owner)
                .build());
    }
}
