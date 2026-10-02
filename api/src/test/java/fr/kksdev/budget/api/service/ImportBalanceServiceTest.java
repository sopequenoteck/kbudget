package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.ImportBalanceCheckResponse;
import fr.kksdev.budget.api.dto.response.ImportBalanceCheckResponse.SuspectTransaction;
import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.ImportHistoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ImportBalanceServiceTest {

    private static final LocalDate BALANCE_DATE = LocalDate.of(2026, Month.OCTOBER, 1);
    private static final LocalDate PERIOD_START = LocalDate.of(2026, Month.SEPTEMBER, 16);
    private static final LocalDate PERIOD_END = LocalDate.of(2026, Month.SEPTEMBER, 21);

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private ImportHistoryRepository importHistoryRepository;

    @InjectMocks
    private ImportBalanceService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();

    private Account account(String openingBalance) {
        return Account.builder().id(accountId).soldeInitial(new BigDecimal(openingBalance)).build();
    }

    private ImportDraft draft(String openingBalance, ImportDraftStatus status, String bankBalance, LocalDate balanceDate) {
        return ImportDraft.builder()
                .account(account(openingBalance))
                .status(status)
                .statementBalance(bankBalance == null ? null : new BigDecimal(bankBalance))
                .statementBalanceDate(balanceDate)
                .build();
    }

    private ImportDraft pendingDraft(String openingBalance, String bankBalance) {
        return draft(openingBalance, ImportDraftStatus.PENDING, bankBalance, BALANCE_DATE);
    }

    private static ImportDraftLine line(ImportLineStatus status, TransactionType type, String amount, LocalDate date) {
        return ImportDraftLine.builder()
                .status(status)
                .transactionType(type)
                .amount(new BigDecimal(amount))
                .date(date)
                .build();
    }

    private static ImportDraftLine readyLine(TransactionType type, String amount, LocalDate date) {
        return line(ImportLineStatus.READY, type, amount, date);
    }

    private static Transaction transaction(UUID id, TransactionType type, String libelle, String amount, LocalDate date) {
        return Transaction.builder().id(id).type(type).libelle(libelle).montant(new BigDecimal(amount)).date(date).build();
    }

    // -------------------------------------------------------------------------
    // draftBalances()
    // -------------------------------------------------------------------------

    @Test
    void should_project_balance_with_opening_balance_existing_transactions_and_ready_lines() {
        ImportDraft draft = pendingDraft("100.00", "1842.37");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE))
                .thenReturn(new BigDecimal("50.00"));
        when(importHistoryRepository.existsByUserIdAndAccountId(userId, accountId)).thenReturn(true);
        List<ImportDraftLine> lines = List.of(
                readyLine(TransactionType.RECETTE, "1500.00", PERIOD_END),
                readyLine(TransactionType.DEPENSE, "600.00", PERIOD_END),
                readyLine(TransactionType.DEPENSE, "4.30", PERIOD_START));

        var balances = service.draftBalances(draft, lines, userId);

        assertThat(balances.projectedBalance()).isEqualByComparingTo("1045.70");
    }

    @Test
    void should_propose_the_opening_balance_that_matches_the_bank_when_first_import() {
        ImportDraft draft = pendingDraft("100.00", "1842.37");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE))
                .thenReturn(new BigDecimal("50.00"));
        when(importHistoryRepository.existsByUserIdAndAccountId(userId, accountId)).thenReturn(false);
        List<ImportDraftLine> lines = List.of(readyLine(TransactionType.RECETTE, "895.70", PERIOD_END));

        var balances = service.draftBalances(draft, lines, userId);

        // projected = 100 + 50 + 895.70 = 1045.70 ; proposed = 100 + (1842.37 - 1045.70)
        assertThat(balances.projectedBalance()).isEqualByComparingTo("1045.70");
        assertThat(balances.proposedOpeningBalance()).isEqualByComparingTo("896.67");
    }

    @Test
    void should_not_propose_an_opening_balance_when_account_already_has_an_import() {
        ImportDraft draft = pendingDraft("100.00", "1842.37");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE))
                .thenReturn(BigDecimal.ZERO);
        when(importHistoryRepository.existsByUserIdAndAccountId(userId, accountId)).thenReturn(true);

        var balances = service.draftBalances(draft, List.of(), userId);

        assertThat(balances.projectedBalance()).isEqualByComparingTo("100.00");
        assertThat(balances.proposedOpeningBalance()).isNull();
    }

    @Test
    void should_count_only_ready_lines_dated_up_to_the_balance_date() {
        ImportDraft draft = pendingDraft("0", "10.00");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE))
                .thenReturn(BigDecimal.ZERO);
        when(importHistoryRepository.existsByUserIdAndAccountId(userId, accountId)).thenReturn(true);
        List<ImportDraftLine> lines = List.of(
                readyLine(TransactionType.RECETTE, "10.00", BALANCE_DATE),
                readyLine(TransactionType.RECETTE, "1000.00", BALANCE_DATE.plusDays(1)),
                line(ImportLineStatus.SKIPPED, TransactionType.RECETTE, "2000.00", PERIOD_END),
                line(ImportLineStatus.NEEDS_REVIEW, TransactionType.RECETTE, "3000.00", PERIOD_END),
                line(ImportLineStatus.DUPLICATE, TransactionType.RECETTE, "4000.00", PERIOD_END));

        var balances = service.draftBalances(draft, lines, userId);

        assertThat(balances.projectedBalance()).isEqualByComparingTo("10.00");
    }

    static Stream<ImportDraft> draftsWithoutUsableBalance() {
        return Stream.of(
                new ImportDraft(),
                ImportDraft.builder().status(ImportDraftStatus.PENDING)
                        .statementBalance(new BigDecimal("10.00")).build(),
                ImportDraft.builder().status(ImportDraftStatus.PENDING)
                        .statementBalanceDate(BALANCE_DATE).build());
    }

    @ParameterizedTest
    @MethodSource("draftsWithoutUsableBalance")
    void should_give_no_balances_when_the_statement_has_no_balance_or_no_date(ImportDraft draft) {
        var balances = service.draftBalances(draft, List.of(), userId);

        assertThat(balances.projectedBalance()).isNull();
        assertThat(balances.proposedOpeningBalance()).isNull();
        verifyNoInteractions(transactionRepository, importHistoryRepository);
    }

    @ParameterizedTest
    @EnumSource(value = ImportDraftStatus.class, names = "PENDING", mode = EnumSource.Mode.EXCLUDE)
    void should_give_no_balances_when_the_draft_is_no_longer_pending(ImportDraftStatus status) {
        ImportDraft draft = draft("0", status, "10.00", BALANCE_DATE);

        var balances = service.draftBalances(draft, List.of(), userId);

        assertThat(balances.projectedBalance()).isNull();
        assertThat(balances.proposedOpeningBalance()).isNull();
        verifyNoInteractions(transactionRepository, importHistoryRepository);
    }

    // -------------------------------------------------------------------------
    // check()
    // -------------------------------------------------------------------------

    @ParameterizedTest
    @MethodSource("draftsWithoutUsableBalance")
    void should_give_no_check_when_the_statement_has_no_balance_or_no_date(ImportDraft draft) {
        ImportBalanceCheckResponse check = service.check(draft, List.of(), List.of(), userId);

        assertThat(check).isNull();
        verifyNoInteractions(transactionRepository);
    }

    @Test
    void should_compare_the_computed_balance_with_the_bank_balance() {
        ImportDraft draft = pendingDraft("896.67", "1842.37");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE))
                .thenReturn(new BigDecimal("341.40"));

        ImportBalanceCheckResponse check = service.check(draft, List.of(), List.of(), userId);

        assertThat(check.bankBalance()).isEqualByComparingTo("1842.37");
        assertThat(check.balanceDate()).isEqualTo(BALANCE_DATE);
        assertThat(check.computedBalance()).isEqualByComparingTo("1238.07");
        assertThat(check.difference()).isEqualByComparingTo("-604.30");
        assertThat(check.suspects()).isEmpty();
    }

    @Test
    void should_report_a_zero_difference_when_both_balances_agree() {
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE))
                .thenReturn(new BigDecimal("895.70"));

        ImportBalanceCheckResponse check = service.check(pendingDraft("946.67", "1842.37"), List.of(), List.of(), userId);

        assertThat(check.difference()).isEqualByComparingTo("0");
    }

    @Test
    void should_list_transactions_of_the_period_that_no_line_accounts_for() {
        UUID created = UUID.randomUUID();
        UUID alreadyImported = UUID.randomUUID();
        UUID adjustment = UUID.randomUUID();
        UUID suspectLater = UUID.randomUUID();
        UUID suspectEarlier = UUID.randomUUID();
        List<ImportDraftLine> lines = List.of(
                readyLine(TransactionType.DEPENSE, "4.30", PERIOD_START),
                readyLine(TransactionType.DEPENSE, "600.00", PERIOD_END),
                skippedLineFor(alreadyImported));
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE)).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.findByUserIdAndAccountIdAndDateBetween(userId, accountId, PERIOD_START, BALANCE_DATE))
                .thenReturn(List.of(
                        transaction(created, TransactionType.DEPENSE, "Created", "4.30", PERIOD_START),
                        transaction(alreadyImported, TransactionType.DEPENSE, "Known", "9.99", PERIOD_START),
                        transaction(adjustment, TransactionType.AJUSTEMENT, "Balance adjustment", "50.00", PERIOD_START),
                        transaction(suspectLater, TransactionType.DEPENSE, "Loyer", "600.00", PERIOD_END),
                        transaction(suspectEarlier, TransactionType.DEPENSE, "Pain", "4.30", PERIOD_START)));

        ImportBalanceCheckResponse check = service.check(pendingDraft("0", "10.00"), lines, List.of(created), userId);

        assertThat(check.suspects()).containsExactly(
                new SuspectTransaction(suspectEarlier, PERIOD_START, "Pain", new BigDecimal("4.30"), TransactionType.DEPENSE),
                new SuspectTransaction(suspectLater, PERIOD_END, "Loyer", new BigDecimal("600.00"), TransactionType.DEPENSE));
    }

    private static ImportDraftLine skippedLineFor(UUID transactionId) {
        ImportDraftLine line = line(ImportLineStatus.SKIPPED, TransactionType.DEPENSE, "9.99", PERIOD_START);
        line.setDuplicateTransactionId(transactionId);
        return line;
    }

    @Test
    void should_order_suspects_by_date_then_label() {
        UUID first = UUID.randomUUID();
        UUID second = UUID.randomUUID();
        UUID third = UUID.randomUUID();
        UUID fourth = UUID.randomUUID();
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE)).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.findByUserIdAndAccountIdAndDateBetween(userId, accountId, PERIOD_START, BALANCE_DATE))
                .thenReturn(List.of(
                        transaction(fourth, TransactionType.DEPENSE, "B", "1.00", PERIOD_END),
                        transaction(third, TransactionType.DEPENSE, "B", "1.00", PERIOD_START),
                        transaction(second, TransactionType.DEPENSE, "A", "1.00", PERIOD_END),
                        transaction(first, TransactionType.DEPENSE, "A", "1.00", PERIOD_START)));
        List<ImportDraftLine> lines = List.of(
                readyLine(TransactionType.DEPENSE, "1.00", PERIOD_START),
                readyLine(TransactionType.DEPENSE, "1.00", PERIOD_END));

        ImportBalanceCheckResponse check = service.check(pendingDraft("0", "10.00"), lines, List.of(), userId);

        assertThat(check.suspects()).extracting(SuspectTransaction::id).containsExactly(first, third, second, fourth);
    }

    @Test
    void should_not_treat_a_line_that_is_not_skipped_as_accounting_for_its_duplicate() {
        UUID existing = UUID.randomUUID();
        ImportDraftLine readyAnyway = readyLine(TransactionType.DEPENSE, "4.30", PERIOD_START);
        readyAnyway.setDuplicateTransactionId(existing);
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE)).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.findByUserIdAndAccountIdAndDateBetween(userId, accountId, PERIOD_START, BALANCE_DATE))
                .thenReturn(List.of(transaction(existing, TransactionType.DEPENSE, "Pain", "4.30", PERIOD_START)));

        ImportBalanceCheckResponse check = service.check(pendingDraft("0", "10.00"), List.of(readyAnyway), List.of(), userId);

        assertThat(check.suspects()).extracting(SuspectTransaction::id).containsExactly(existing);
    }

    @Test
    void should_ignore_the_date_of_a_line_that_could_not_be_read_when_computing_the_period() {
        ImportDraftLine unreadable = line(ImportLineStatus.SKIPPED, TransactionType.DEPENSE, "0", BALANCE_DATE.plusMonths(6));
        unreadable.setStatusMessage("Date invalide: 32/13/2026");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE)).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.findByUserIdAndAccountIdAndDateBetween(userId, accountId, PERIOD_START, BALANCE_DATE))
                .thenReturn(List.of());
        List<ImportDraftLine> lines = List.of(
                readyLine(TransactionType.DEPENSE, "1.00", PERIOD_START),
                readyLine(TransactionType.DEPENSE, "1.00", PERIOD_END),
                unreadable);

        ImportBalanceCheckResponse check = service.check(pendingDraft("0", "10.00"), lines, List.of(), userId);

        assertThat(check.suspects()).isEmpty();
        verify(transactionRepository).findByUserIdAndAccountIdAndDateBetween(userId, accountId, PERIOD_START, BALANCE_DATE);
    }

    @Test
    void should_list_no_suspect_without_querying_when_no_line_has_a_date() {
        ImportDraftLine unreadable = line(ImportLineStatus.NEEDS_REVIEW, TransactionType.DEPENSE, "0", BALANCE_DATE);
        unreadable.setStatusMessage("Montant invalide");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE)).thenReturn(BigDecimal.ZERO);

        ImportBalanceCheckResponse empty = service.check(pendingDraft("0", "10.00"), List.of(), List.of(), userId);
        ImportBalanceCheckResponse unreadableOnly = service.check(pendingDraft("0", "10.00"), List.of(unreadable), List.of(), userId);

        assertThat(empty.suspects()).isEmpty();
        assertThat(unreadableOnly.suspects()).isEmpty();
        verify(transactionRepository, never())
                .findByUserIdAndAccountIdAndDateBetween(userId, accountId, BALANCE_DATE, BALANCE_DATE);
    }

    @Test
    void should_not_count_a_matched_line_in_the_projected_balance_since_its_transaction_is_already_there() {
        ImportDraft draft = pendingDraft("100.00", "1842.37");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE))
                .thenReturn(new BigDecimal("-12.50"));
        when(importHistoryRepository.existsByUserIdAndAccountId(userId, accountId)).thenReturn(true);
        ImportDraftLine matched = readyLine(TransactionType.DEPENSE, "12.50", PERIOD_START);
        matched.setMatchedTransactionId(UUID.randomUUID());

        var balances = service.draftBalances(draft, List.of(matched, readyLine(TransactionType.DEPENSE, "4.30", PERIOD_END)), userId);

        assertThat(balances.projectedBalance()).isEqualByComparingTo("83.20");
    }

    @Test
    void should_count_a_line_at_the_date_of_the_transaction_it_creates_when_the_purchase_precedes_the_balance_date() {
        ImportDraft draft = pendingDraft("0", "10.00");
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE)).thenReturn(BigDecimal.ZERO);
        when(importHistoryRepository.existsByUserIdAndAccountId(userId, accountId)).thenReturn(true);
        ImportDraftLine booked = readyLine(TransactionType.RECETTE, "5.00", BALANCE_DATE.plusDays(1));
        booked.setPurchaseDate(BALANCE_DATE);
        ImportDraftLine purchasedAfter = readyLine(TransactionType.RECETTE, "7.00", BALANCE_DATE.plusDays(3));
        purchasedAfter.setPurchaseDate(BALANCE_DATE.plusDays(2));

        var balances = service.draftBalances(draft, List.of(booked, purchasedAfter), userId);

        assertThat(balances.projectedBalance()).isEqualByComparingTo("5.00");
    }

    @ParameterizedTest(name = "line {0} matched with the transaction -> listed as suspect: {1}")
    @CsvSource({"READY, false", "DUPLICATE, true", "NEEDS_REVIEW, true", "SKIPPED, true"})
    void should_not_list_as_suspect_the_transaction_only_a_ready_line_is_matched_with(
            ImportLineStatus status, boolean listed) {
        UUID matchedTransaction = UUID.randomUUID();
        UUID stranger = UUID.randomUUID();
        ImportDraftLine matched = line(status, TransactionType.DEPENSE, "4.30", PERIOD_START);
        matched.setMatchedTransactionId(matchedTransaction);
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE)).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.findByUserIdAndAccountIdAndDateBetween(userId, accountId, PERIOD_START, BALANCE_DATE))
                .thenReturn(List.of(
                        transaction(matchedTransaction, TransactionType.DEPENSE, "Pain", "4.30", PERIOD_START),
                        transaction(stranger, TransactionType.DEPENSE, "Autre", "4.30", PERIOD_START)));

        ImportBalanceCheckResponse check = service.check(pendingDraft("0", "10.00"), List.of(matched), List.of(), userId);

        // Ordered by date then label: "Autre" before "Pain".
        assertThat(check.suspects()).extracting(SuspectTransaction::id)
                .containsExactlyElementsOf(listed ? List.of(stranger, matchedTransaction) : List.of(stranger));
    }

    @Test
    void should_end_the_period_at_the_latest_line_when_it_is_dated_after_the_balance_date() {
        LocalDate lateLine = BALANCE_DATE.plusDays(2);
        when(transactionRepository.calculateBalanceByAccountIdUntil(accountId, BALANCE_DATE)).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.findByUserIdAndAccountIdAndDateBetween(userId, accountId, PERIOD_START, lateLine))
                .thenReturn(List.of());
        List<ImportDraftLine> lines = List.of(
                readyLine(TransactionType.DEPENSE, "1.00", PERIOD_START),
                readyLine(TransactionType.DEPENSE, "1.00", lateLine));

        ImportBalanceCheckResponse check = service.check(pendingDraft("0", "10.00"), lines, List.of(), userId);

        assertThat(check.suspects()).isEmpty();
        verify(transactionRepository).findByUserIdAndAccountIdAndDateBetween(userId, accountId, PERIOD_START, lateLine);
    }
}
