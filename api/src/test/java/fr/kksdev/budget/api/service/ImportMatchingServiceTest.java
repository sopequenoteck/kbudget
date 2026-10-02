package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.ImportSkipReason;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ImportMatchingServiceTest {

    private static final LocalDate BOOKING = LocalDate.of(2026, Month.SEPTEMBER, 20);
    private static final LocalDate PURCHASE = LocalDate.of(2026, Month.SEPTEMBER, 17);
    private static final String STREAMING_KEY = "STREAMING TEST";

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @InjectMocks
    private ImportMatchingService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();

    private static ImportDraftLine line(ImportLineStatus status, TransactionType type, String amount, LocalDate booking,
                                        LocalDate purchase) {
        return ImportDraftLine.builder()
                .id(UUID.randomUUID())
                .lineNumber(1)
                .status(status)
                .transactionType(type)
                .amount(new BigDecimal(amount))
                .date(booking)
                .purchaseDate(purchase)
                .rawLabel("RAW")
                .cleanLabel("Clean label")
                .build();
    }

    private static ImportDraftLine readyExpense(String amount, LocalDate booking, LocalDate purchase) {
        return line(ImportLineStatus.READY, TransactionType.DEPENSE, amount, booking, purchase);
    }

    private static Transaction transaction(TransactionType type, String amount, LocalDate date) {
        return Transaction.builder()
                .id(UUID.randomUUID())
                .type(type)
                .montant(new BigDecimal(amount))
                .date(date)
                .libelle("Manual")
                .build();
    }

    private static Transaction expense(String amount, LocalDate date) {
        return transaction(TransactionType.DEPENSE, amount, date);
    }

    private static Subscription subscription(String amount, String key) {
        return Subscription.builder()
                .id(UUID.randomUUID())
                .nom("Streaming")
                .montant(new BigDecimal(amount))
                .frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2026, Month.JANUARY, 5))
                .actif(true)
                .statementMerchantKey(key)
                .user(User.builder().id(UUID.fromString("00000000-0000-0000-0000-00000000000a")).build())
                .build();
    }

    private void givenTransactions(Transaction... transactions) {
        when(transactionRepository.findByUserIdAndAccountIdAndDateBetween(any(), any(), any(), any()))
                .thenReturn(List.of(transactions));
    }

    // -------------------------------------------------------------------------
    // match(): windows
    // -------------------------------------------------------------------------

    @ParameterizedTest(name = "purchase date known={0}, subscription={1}, offset={2} days -> matched={3}")
    @CsvSource({
            // booking date only: from 5 days before to 1 day after
            "false, false, -6, false", "false, false, -5, true", "false, false, 0, true",
            "false, false, 1, true", "false, false, 2, false",
            // purchase date known: 2 days either side of the purchase
            "true, false, -3, false", "true, false, -2, true", "true, false, 0, true",
            "true, false, 2, true", "true, false, 3, false",
            // transaction linked to a subscription: 8 days either side of the reference date
            "false, true, -9, false", "false, true, -8, true", "false, true, 8, true", "false, true, 9, false",
            "true, true, -9, false", "true, true, -8, true", "true, true, 8, true", "true, true, 9, false"})
    void should_match_only_a_transaction_within_the_window_of_its_kind(
            boolean purchaseKnown, boolean subscribed, int offset, boolean expectedMatch) {
        LocalDate reference = purchaseKnown ? PURCHASE : BOOKING;
        ImportDraftLine line = readyExpense("12.50", BOOKING, purchaseKnown ? PURCHASE : null);
        Transaction candidate = expense("12.50", reference.plusDays(offset));
        if (subscribed) {
            candidate.setSubscription(subscription("12.50", null));
        }
        givenTransactions(candidate);
        Set<UUID> consumed = new HashSet<>();

        service.match(List.of(line), accountId, userId, consumed);

        assertThat(line.getMatchedTransactionId()).isEqualTo(expectedMatch ? candidate.getId() : null);
        assertThat(line.getStatus()).isEqualTo(ImportLineStatus.READY);
        assertThat(consumed).isEqualTo(expectedMatch ? Set.of(candidate.getId()) : Set.of());
    }

    @Test
    void should_search_the_window_of_the_widest_rule_around_the_reference_dates_of_the_lines() {
        ImportDraftLine card = readyExpense("1.00", BOOKING, PURCHASE);
        ImportDraftLine debit = readyExpense("2.00", BOOKING.plusDays(10), null);
        givenTransactions();

        service.match(List.of(card, debit), accountId, userId, new HashSet<>());

        verify(transactionRepository).findByUserIdAndAccountIdAndDateBetween(
                userId, accountId, PURCHASE.minusDays(8), BOOKING.plusDays(10).plusDays(8));
    }

    // -------------------------------------------------------------------------
    // match(): criteria
    // -------------------------------------------------------------------------

    @ParameterizedTest(name = "line {0}, transaction {1}, label \"{2}\"")
    @CsvSource({"12.50, 12.50, Nothing like the bank label", "12.5, 12.50, Manual", "12.50, 12.5, Manual"})
    void should_match_whatever_the_label_and_the_scale_of_the_amount(
            String lineAmount, String transactionAmount, String label) {
        ImportDraftLine line = readyExpense(lineAmount, BOOKING, null);
        Transaction candidate = expense(transactionAmount, BOOKING);
        candidate.setLibelle(label);
        givenTransactions(candidate);

        service.match(List.of(line), accountId, userId, new HashSet<>());

        assertThat(line.getMatchedTransactionId()).isEqualTo(candidate.getId());
    }

    @Test
    void should_not_match_a_transaction_of_another_type_or_amount_or_one_that_came_from_a_statement() {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        Transaction otherType = transaction(TransactionType.RECETTE, "12.50", BOOKING);
        Transaction otherAmount = expense("12.51", BOOKING);
        Transaction imported = expense("12.50", BOOKING);
        imported.setImportFingerprint("fingerprint");
        givenTransactions(otherType, otherAmount, imported);

        service.match(List.of(line), accountId, userId, new HashSet<>());

        assertThat(line.getMatchedTransactionId()).isNull();
        assertThat(line.getStatus()).isEqualTo(ImportLineStatus.READY);
    }

    @Test
    void should_not_match_a_transaction_a_previous_pass_already_consumed() {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        Transaction consumedBefore = expense("12.50", BOOKING);
        givenTransactions(consumedBefore);

        service.match(List.of(line), accountId, userId, new HashSet<>(Set.of(consumedBefore.getId())));

        assertThat(line.getMatchedTransactionId()).isNull();
    }

    @Test
    void should_not_search_anything_when_no_line_is_ready() {
        List<ImportDraftLine> lines = List.of(
                line(ImportLineStatus.SKIPPED, TransactionType.DEPENSE, "1.00", BOOKING, null),
                line(ImportLineStatus.NEEDS_REVIEW, TransactionType.DEPENSE, "1.00", BOOKING, null),
                line(ImportLineStatus.DUPLICATE, TransactionType.DEPENSE, "1.00", BOOKING, null));

        service.match(lines, accountId, userId, new HashSet<>());

        verifyNoInteractions(transactionRepository);
    }

    // -------------------------------------------------------------------------
    // match(): one candidate, several, one at a time
    // -------------------------------------------------------------------------

    @Test
    void should_block_the_line_with_the_candidates_oldest_first_and_consume_none_when_several_fit() {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        Transaction later = expense("12.50", BOOKING);
        Transaction earlier = expense("12.50", BOOKING.minusDays(2));
        Set<UUID> consumed = new HashSet<>();
        givenTransactions(later, earlier);

        service.match(List.of(line), accountId, userId, consumed);

        assertThat(line.getStatus()).isEqualTo(ImportLineStatus.DUPLICATE);
        assertThat(line.getMatchedTransactionId()).isNull();
        assertThat(line.getMatchCandidateIds()).containsExactly(earlier.getId(), later.getId());
        assertThat(consumed).isEmpty();
    }

    @Test
    void should_use_a_transaction_for_one_line_only_in_the_order_of_the_lines() {
        ImportDraftLine first = readyExpense("12.50", BOOKING, null);
        ImportDraftLine second = readyExpense("12.50", BOOKING, null);
        Transaction only = expense("12.50", BOOKING);
        givenTransactions(only);

        service.match(List.of(first, second), accountId, userId, new HashSet<>());

        assertThat(first.getMatchedTransactionId()).isEqualTo(only.getId());
        assertThat(second.getMatchedTransactionId()).isNull();
        assertThat(second.getStatus()).isEqualTo(ImportLineStatus.READY);
    }

    @Test
    void should_leave_a_line_without_candidate_ready_and_unmatched() {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        givenTransactions();

        service.match(List.of(line), accountId, userId, new HashSet<>());

        assertThat(line.getStatus()).isEqualTo(ImportLineStatus.READY);
        assertThat(line.getMatchedTransactionId()).isNull();
        assertThat(line.getMatchCandidateIds()).isEmpty();
    }

    // -------------------------------------------------------------------------
    // linkSubscriptions()
    // -------------------------------------------------------------------------

    static Stream<Arguments> subscriptionsOfTheUser() {
        return Stream.of(
                Arguments.of("one has the same label and amount among others", "STREAMING TEST",
                        List.of(subscription("9.99", STREAMING_KEY), subscription("4.99", STREAMING_KEY),
                                subscription("9.99", "OTHER MERCHANT"), subscription("9.99", null)), 0),
                Arguments.of("two have the same label and amount", "STREAMING TEST",
                        List.of(subscription("9.99", STREAMING_KEY), subscription("9.99", STREAMING_KEY)), -1),
                Arguments.of("the label has no merchant key", "12345",
                        List.of(subscription("9.99", STREAMING_KEY)), -1));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("subscriptionsOfTheUser")
    void should_link_a_ready_expense_only_to_the_one_subscription_with_its_label_and_amount(
            String description, String cleanLabel, List<Subscription> subscriptions, int expectedIndex) {
        ImportDraftLine line = readyExpense("9.99", BOOKING, null);
        line.setCleanLabel(cleanLabel);
        when(subscriptionRepository.findByUserIdAndActifTrueOrderByNomAsc(userId)).thenReturn(subscriptions);

        service.linkSubscriptions(List.of(line), userId);

        assertThat(line.getSubscriptionId())
                .isEqualTo(expectedIndex < 0 ? null : subscriptions.get(expectedIndex).getId());
    }

    @Test
    void should_not_look_for_subscriptions_when_no_line_can_be_linked() {
        ImportDraftLine matched = readyExpense("9.99", BOOKING, null);
        matched.setMatchedTransactionId(UUID.randomUUID());
        List<ImportDraftLine> lines = List.of(
                matched,
                line(ImportLineStatus.READY, TransactionType.RECETTE, "9.99", BOOKING, null),
                line(ImportLineStatus.DUPLICATE, TransactionType.DEPENSE, "9.99", BOOKING, null),
                line(ImportLineStatus.SKIPPED, TransactionType.DEPENSE, "9.99", BOOKING, null));

        service.linkSubscriptions(lines, userId);

        verifyNoInteractions(subscriptionRepository);
        assertThat(lines).allSatisfy(l -> assertThat(l.getSubscriptionId()).isNull());
    }

    // -------------------------------------------------------------------------
    // requireMatchable()
    // -------------------------------------------------------------------------

    private void givenOwnedTransaction(Transaction transaction) {
        when(transactionRepository.findByUserIdAndAccountIdAndIdIn(userId, accountId, Set.of(transaction.getId())))
                .thenReturn(List.of(transaction));
    }

    static Stream<Arguments> situationsThatAllowTheChoice() {
        Function<UUID, List<ImportDraftLine>> none = id -> List.of();
        Function<UUID, List<ImportDraftLine>> probableDuplicate = id -> {
            ImportDraftLine other = line(ImportLineStatus.DUPLICATE, TransactionType.DEPENSE, "12.50", BOOKING, null);
            other.setDuplicateTransactionId(id);
            return List.of(other);
        };
        Function<UUID, List<ImportDraftLine>> skippedByTheUser = id -> {
            ImportDraftLine other = line(ImportLineStatus.SKIPPED, TransactionType.DEPENSE, "12.50", BOOKING, null);
            other.setDuplicateTransactionId(id);
            return List.of(other);
        };
        Function<UUID, List<ImportDraftLine>> recognizedWithAnother = id -> {
            ImportDraftLine other = line(ImportLineStatus.SKIPPED, TransactionType.DEPENSE, "12.50", BOOKING, null);
            other.setSkipReason(ImportSkipReason.ALREADY_IMPORTED);
            other.setDuplicateTransactionId(UUID.randomUUID());
            return List.of(other);
        };
        return Stream.of(
                Arguments.of("no other line", none),
                Arguments.of("another line only suspects it as a probable duplicate", probableDuplicate),
                Arguments.of("a line skipped by the user points at it", skippedByTheUser),
                Arguments.of("a line recognized as already imported with another transaction", recognizedWithAnother));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("situationsThatAllowTheChoice")
    void should_accept_a_transaction_of_the_user_and_account_with_the_type_and_amount_whatever_its_date(
            String description, Function<UUID, List<ImportDraftLine>> otherLines) {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        Transaction faraway = expense("12.50", BOOKING.minusYears(1));
        // The line itself may already hold it: the user chooses it again.
        line.setMatchedTransactionId(faraway.getId());
        givenOwnedTransaction(faraway);
        List<ImportDraftLine> draftLines = Stream.concat(Stream.of(line), otherLines.apply(faraway.getId()).stream()).toList();

        Transaction accepted = service.requireMatchable(line, faraway.getId(), accountId, userId, draftLines);

        assertThat(accepted).isSameAs(faraway);
    }

    @Test
    void should_report_not_found_when_the_transaction_is_not_the_users_or_not_on_the_account() {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        UUID unknown = UUID.randomUUID();
        when(transactionRepository.findByUserIdAndAccountIdAndIdIn(userId, accountId, Set.of(unknown)))
                .thenReturn(List.of());

        List<ImportDraftLine> draftLines = List.of(line);

        assertThatThrownBy(() -> service.requireMatchable(line, unknown, accountId, userId, draftLines))
                .isInstanceOf(EntityNotFoundException.class);
    }

    static Stream<Arguments> transactionsThatDoNotFit() {
        Transaction imported = expense("12.50", BOOKING);
        imported.setImportFingerprint("fingerprint");
        return Stream.of(
                Arguments.of("came from a statement", imported, "already comes from an import"),
                Arguments.of("other amount", expense("12.51", BOOKING), "type and amount"),
                Arguments.of("other type", transaction(TransactionType.RECETTE, "12.50", BOOKING), "type and amount"));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("transactionsThatDoNotFit")
    void should_refuse_a_transaction_that_does_not_fit_the_line(
            String description, Transaction transaction, String message) {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        givenOwnedTransaction(transaction);
        UUID transactionId = transaction.getId();
        List<ImportDraftLine> draftLines = List.of(line);

        assertThatThrownBy(() -> service.requireMatchable(line, transactionId, accountId, userId, draftLines))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(message);
    }

    static Stream<Arguments> linesStandingForATransaction() {
        Function<UUID, ImportDraftLine> matched = id -> {
            ImportDraftLine other = readyExpense("12.50", BOOKING, null);
            other.setMatchedTransactionId(id);
            return other;
        };
        Function<UUID, ImportDraftLine> recognized = id -> {
            ImportDraftLine other = line(ImportLineStatus.SKIPPED, TransactionType.DEPENSE, "12.50", BOOKING, null);
            other.setSkipReason(ImportSkipReason.ALREADY_IMPORTED);
            other.setDuplicateTransactionId(id);
            return other;
        };
        return Stream.of(
                Arguments.of("another line is matched with it", matched),
                Arguments.of("a skipped line was recognized as already imported with it", recognized));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("linesStandingForATransaction")
    void should_refuse_a_transaction_another_line_already_stands_for(
            String description, Function<UUID, ImportDraftLine> otherLine) {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        Transaction wanted = expense("12.50", BOOKING);
        givenOwnedTransaction(wanted);
        UUID wantedId = wanted.getId();
        List<ImportDraftLine> draftLines = List.of(line, otherLine.apply(wantedId));

        assertThatThrownBy(() -> service.requireMatchable(line, wantedId, accountId, userId, draftLines))
                .isInstanceOf(ConflictException.class);
    }

    // -------------------------------------------------------------------------
    // confirmMatches()
    // -------------------------------------------------------------------------

    private ImportDraftLine matchedLine(Transaction transaction, String cleanLabel) {
        ImportDraftLine line = readyExpense("12.50", BOOKING, null);
        line.setCleanLabel(cleanLabel);
        line.setMatchedTransactionId(transaction.getId());
        return line;
    }

    private void givenExisting(Transaction... transactions) {
        when(transactionRepository.findByUserIdAndAccountIdAndIdIn(any(), any(), any()))
                .thenReturn(List.of(transactions));
    }

    @Test
    void should_give_the_fingerprint_of_the_line_to_the_matched_transaction_and_change_nothing_else() {
        Transaction transaction = expense("12.50", BOOKING.minusDays(1));
        ImportDraftLine line = matchedLine(transaction, "Clean label");
        givenExisting(transaction);

        service.confirmMatches(List.of(line), accountId, userId);

        assertThat(transaction.getImportFingerprint()).isEqualTo(DeduplicationService.fingerprintOf(line));
        assertThat(transaction.getLibelle()).isEqualTo("Manual");
        assertThat(transaction.getDate()).isEqualTo(BOOKING.minusDays(1));
        verify(transactionRepository).saveAll(List.of(transaction));
        verify(subscriptionRepository).saveAll(List.of());
    }

    @ParameterizedTest(name = "label \"{0}\", known key {1} -> {2}")
    @CsvSource(value = {"STREAMING TEST ref 12345, null, STREAMING TEST REF, true", "12345, KNOWN KEY, KNOWN KEY, false"},
            nullValues = "null")
    void should_teach_the_subscription_of_the_matched_transaction_the_merchant_key_of_a_label_that_has_one(
            String label, String knownKey, String expectedKey, boolean taught) {
        Transaction transaction = expense("12.50", BOOKING);
        Subscription subscription = subscription("12.50", knownKey);
        transaction.setSubscription(subscription);
        givenExisting(transaction);

        service.confirmMatches(List.of(matchedLine(transaction, label)), accountId, userId);

        assertThat(subscription.getStatementMerchantKey()).isEqualTo(expectedKey);
        verify(subscriptionRepository).saveAll(taught ? List.of(subscription) : List.of());
    }

    @ParameterizedTest(name = "exists={0}, imported meanwhile={1}, lines holding it={2}")
    @CsvSource({"false, false, 1", "true, true, 1", "true, false, 2"})
    void should_ask_to_undo_the_match_when_the_transaction_is_gone_imported_meanwhile_or_held_twice(
            boolean exists, boolean importedMeanwhile, int holdingLines) {
        Transaction transaction = expense("12.50", BOOKING);
        if (importedMeanwhile) {
            transaction.setImportFingerprint("fingerprint");
        }
        List<ImportDraftLine> matched = IntStream.range(0, holdingLines)
                .mapToObj(i -> matchedLine(transaction, "Clean label"))
                .toList();
        if (exists) {
            givenExisting(transaction);
        } else {
            givenExisting();
        }

        assertThatThrownBy(() -> service.confirmMatches(matched, accountId, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("line 1")
                .hasMessageContaining("undo the match");
        verify(transactionRepository, never()).saveAll(any());
    }

    @Test
    void should_do_nothing_when_there_is_no_matched_line() {
        service.confirmMatches(List.of(), accountId, userId);

        verifyNoInteractions(transactionRepository, subscriptionRepository);
    }

    // -------------------------------------------------------------------------
    // subscriptionsOf()
    // -------------------------------------------------------------------------

    @Test
    void should_return_only_the_subscriptions_of_the_user_the_lines_are_linked_to() {
        UUID ownerId = UUID.fromString("00000000-0000-0000-0000-00000000000a");
        Subscription own = subscription("9.99", STREAMING_KEY);
        Subscription foreign = subscription("9.99", STREAMING_KEY);
        foreign.setUser(User.builder().id(UUID.randomUUID()).build());
        ImportDraftLine linked = readyExpense("9.99", BOOKING, null);
        linked.setSubscriptionId(own.getId());
        ImportDraftLine linkedToForeign = readyExpense("9.99", BOOKING, null);
        linkedToForeign.setSubscriptionId(foreign.getId());
        when(subscriptionRepository.findAllById(Set.of(own.getId(), foreign.getId()))).thenReturn(List.of(own, foreign));

        Map<UUID, Subscription> subscriptions = service.subscriptionsOf(
                List.of(linked, linkedToForeign, readyExpense("1.00", BOOKING, null)), ownerId);

        assertThat(subscriptions).containsOnlyKeys(own.getId());
    }

    @Test
    void should_not_read_any_subscription_when_no_line_is_linked() {
        assertThat(service.subscriptionsOf(List.of(readyExpense("1.00", BOOKING, null)), userId)).isEmpty();

        verifyNoInteractions(subscriptionRepository);
    }

    @ParameterizedTest
    @EnumSource(value = ImportLineStatus.class, names = "READY", mode = EnumSource.Mode.EXCLUDE)
    void should_not_match_lines_that_are_not_ready_even_among_ready_ones(ImportLineStatus status) {
        ImportDraftLine notReady = line(status, TransactionType.DEPENSE, "12.50", BOOKING, null);
        ImportDraftLine ready = readyExpense("12.50", BOOKING, null);
        Transaction candidate = expense("12.50", BOOKING);
        givenTransactions(candidate);

        service.match(List.of(notReady, ready), accountId, userId, new HashSet<>());

        assertThat(notReady.getMatchedTransactionId()).isNull();
        assertThat(notReady.getStatus()).isEqualTo(status);
        assertThat(ready.getMatchedTransactionId()).isEqualTo(candidate.getId());
    }

    // -------------------------------------------------------------------------
    // inWindowOfImported(): the window applied to a transaction already imported (KKS-387)
    // -------------------------------------------------------------------------

    @ParameterizedTest(name = "subscription={0}, offset={1} days -> in window={2}")
    @CsvSource({
            // either window of a manual transaction: from 5 days before to 2 days after
            "false, -6, false", "false, -5, true", "false, 0, true", "false, 1, true", "false, 2, true", "false, 3, false",
            // subscription payment: 8 days either side
            "true, -9, false", "true, -8, true", "true, 8, true", "true, 9, false"})
    void should_apply_the_matching_windows_to_the_date_of_an_imported_transaction(
            boolean subscriptionLinked, int offset, boolean expected) {
        Transaction manual = expense("12.50", BOOKING.plusDays(offset));
        if (subscriptionLinked) {
            manual.setSubscription(subscription("12.50", null));
        }

        assertThat(ImportMatchingService.inWindowOfImported(BOOKING, manual)).isEqualTo(expected);
    }
}
