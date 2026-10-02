package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.util.MerchantKey;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Matches the lines of a statement with the transactions the user already entered
 * by hand, so that an operation is never counted twice (KKS-385).
 *
 * <p>The label is not a criterion: the user's wording and the bank's have nothing
 * in common. A transaction is a candidate for a line when it is on the same
 * account, has no import fingerprint (it did not come from a statement), has the
 * same type and amount, and falls in a date window around the reference date of
 * the line, which is its purchase date when the profile reads one, its booking
 * date otherwise:
 * <ul>
 *   <li>transaction linked to a subscription: {@value #SUBSCRIPTION_WINDOW_DAYS} days either side;</li>
 *   <li>purchase date known (card): {@value #PURCHASE_DATE_WINDOW_DAYS} days either side of it;</li>
 *   <li>booking date only (transfer, direct debit): from {@value #BOOKING_DAYS_BEFORE} days
 *       before to {@value #BOOKING_DAYS_AFTER} day after.</li>
 * </ul>
 * One candidate is matched automatically. Several are never decided here: the line
 * becomes a blocking {@code DUPLICATE} carrying the candidates, for the user to settle.
 *
 * <p>It also links the lines of an unmatched subscription charge to their subscription.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImportMatchingService {

    static final int SUBSCRIPTION_WINDOW_DAYS = 8;
    static final int PURCHASE_DATE_WINDOW_DAYS = 2;
    static final int BOOKING_DAYS_BEFORE = 5;
    static final int BOOKING_DAYS_AFTER = 1;

    private final TransactionRepository transactionRepository;
    private final SubscriptionRepository subscriptionRepository;

    /**
     * Matches the still {@code READY} lines, in the order given, with the manual transactions
     * of the account that no other line consumed. A transaction matched here is added to
     * {@code consumed}; the candidates of an ambiguous line are not, nothing being decided.
     */
    public void match(List<ImportDraftLine> lines, UUID accountId, UUID userId, Set<UUID> consumed) {
        List<ImportDraftLine> pending = lines.stream()
                .filter(line -> line.getStatus() == ImportLineStatus.READY)
                .toList();
        if (pending.isEmpty()) {
            return;
        }
        List<Transaction> manual = findManualTransactions(pending, accountId, userId);

        int matched = 0;
        int ambiguous = 0;
        for (ImportDraftLine line : pending) {
            List<Transaction> candidates = manual.stream()
                    .filter(t -> !consumed.contains(t.getId()))
                    .filter(t -> isCandidate(line, t))
                    .toList();
            if (candidates.size() == 1) {
                line.setMatchedTransactionId(candidates.getFirst().getId());
                consumed.add(candidates.getFirst().getId());
                matched++;
            } else if (candidates.size() > 1) {
                line.setStatus(ImportLineStatus.DUPLICATE);
                line.setMatchCandidateIds(candidates.stream().map(Transaction::getId).toList());
                ambiguous++;
            }
        }
        log.info("Reconciliation: {} lines matched with an existing transaction, {} ambiguous, out of {} lines",
                matched, ambiguous, pending.size());
    }

    /**
     * Links each still {@code READY}, unmatched expense line to the one active subscription of
     * the user whose statement merchant key and amount equal its own. With several subscriptions
     * alike (five under the same label, told apart by their amount) the amount decides; if it
     * still does not, no link is made.
     */
    public void linkSubscriptions(List<ImportDraftLine> lines, UUID userId) {
        List<ImportDraftLine> expenses = lines.stream()
                .filter(line -> line.getStatus() == ImportLineStatus.READY)
                .filter(line -> line.getMatchedTransactionId() == null)
                .filter(line -> line.getTransactionType() == TransactionType.DEPENSE)
                .toList();
        if (expenses.isEmpty()) {
            return;
        }
        List<Subscription> learned = subscriptionRepository.findByUserIdAndActifTrueOrderByNomAsc(userId).stream()
                .filter(s -> s.getStatementMerchantKey() != null)
                .toList();
        int linked = 0;
        for (ImportDraftLine line : expenses) {
            String key = MerchantKey.of(line.getCleanLabel());
            List<Subscription> same = learned.stream()
                    .filter(s -> s.getStatementMerchantKey().equals(key))
                    .filter(s -> s.getMontant().compareTo(line.getAmount()) == 0)
                    .toList();
            if (same.size() == 1) {
                line.setSubscriptionId(same.getFirst().getId());
                linked++;
            }
        }
        log.info("Subscription link: {} lines linked to a subscription out of {} expense lines", linked, expenses.size());
    }

    /**
     * Checks that a transaction chosen by the user for a line can stand for it: it belongs to the
     * user and to the account of the draft, did not come from a statement, has the type and amount
     * of the line, and is not already taken by another line of the draft. The date window is not
     * checked: the user may know better.
     *
     * @throws EntityNotFoundException when the transaction is not the user's, or not on the account
     * @throws IllegalArgumentException when it came from a statement or differs from the line
     * @throws ConflictException when another line of the draft already stands for it
     */
    public Transaction requireMatchable(ImportDraftLine line, UUID transactionId, UUID accountId, UUID userId,
                                        Collection<ImportDraftLine> draftLines) {
        Transaction transaction = transactionRepository
                .findByUserIdAndAccountIdAndIdIn(userId, accountId, Set.of(transactionId)).stream()
                .findFirst()
                .orElseThrow(() -> {
                    log.error("Transaction to match not found: id={}, accountId={}, userId={}", transactionId, accountId, userId);
                    return new EntityNotFoundException("Transaction not found");
                });
        if (transaction.getImportFingerprint() != null) {
            throw new IllegalArgumentException("The transaction already comes from an import");
        }
        if (transaction.getType() != line.getTransactionType()
                || transaction.getMontant().compareTo(line.getAmount()) != 0) {
            throw new IllegalArgumentException("The transaction does not have the type and amount of the line");
        }
        boolean taken = draftLines.stream()
                .filter(other -> !other.getId().equals(line.getId()))
                .anyMatch(other -> stands(other, transactionId));
        if (taken) {
            throw new ConflictException("The transaction is already matched with another line of this import");
        }
        return transaction;
    }

    /**
     * Applies the matches of a confirmed draft: each matched transaction receives the import
     * fingerprint of its line, and the subscription it is linked to, if any, learns the merchant
     * key of the statement label. Nothing is created.
     *
     * @throws IllegalArgumentException when a matched transaction no longer exists on the account,
     *         or was imported meanwhile: the match has to be undone
     */
    public void confirmMatches(List<ImportDraftLine> matchedLines, UUID accountId, UUID userId) {
        if (matchedLines.isEmpty()) {
            return;
        }
        Set<UUID> ids = matchedLines.stream().map(ImportDraftLine::getMatchedTransactionId).collect(Collectors.toSet());
        Map<UUID, Transaction> existing = transactionRepository.findByUserIdAndAccountIdAndIdIn(userId, accountId, ids)
                .stream()
                .collect(Collectors.toMap(Transaction::getId, Function.identity()));

        List<Transaction> matched = new ArrayList<>();
        List<Subscription> learning = new ArrayList<>();
        for (ImportDraftLine line : matchedLines) {
            Transaction transaction = existing.get(line.getMatchedTransactionId());
            if (transaction == null || transaction.getImportFingerprint() != null
                    || transaction.getType() != line.getTransactionType()
                    || transaction.getMontant().compareTo(line.getAmount()) != 0) {
                throw new IllegalArgumentException("The transaction matched with line " + line.getLineNumber()
                        + " is no longer available, undo the match");
            }
            transaction.setImportFingerprint(DeduplicationService.fingerprintOf(line));
            matched.add(transaction);
            learnMerchantKey(transaction.getSubscription(), line, learning);
        }
        transactionRepository.saveAll(matched);
        subscriptionRepository.saveAll(learning);
        log.info("{} transactions matched with a statement line, {} subscriptions learned their statement label",
                matched.size(), learning.size());
    }

    /** The subscriptions the lines are linked to, among the user's own; one deleted since the upload is absent. */
    public Map<UUID, Subscription> subscriptionsOf(List<ImportDraftLine> lines, UUID userId) {
        Set<UUID> ids = lines.stream()
                .map(ImportDraftLine::getSubscriptionId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        if (ids.isEmpty()) {
            return Map.of();
        }
        return subscriptionRepository.findAllById(ids).stream()
                .filter(s -> s.getUser().getId().equals(userId))
                .collect(Collectors.toMap(Subscription::getId, Function.identity()));
    }

    private static void learnMerchantKey(Subscription subscription, ImportDraftLine line, List<Subscription> learning) {
        if (subscription == null) {
            return;
        }
        String key = MerchantKey.of(line.getCleanLabel());
        if (!key.isEmpty()) {
            subscription.setStatementMerchantKey(key);
            learning.add(subscription);
        }
    }

    private List<Transaction> findManualTransactions(List<ImportDraftLine> lines, UUID accountId, UUID userId) {
        LocalDate earliest = lines.stream().map(ImportDraftLine::transactionDate).min(Comparator.naturalOrder()).orElseThrow();
        LocalDate latest = lines.stream().map(ImportDraftLine::transactionDate).max(Comparator.naturalOrder()).orElseThrow();
        return transactionRepository.findByUserIdAndAccountIdAndDateBetween(
                        userId, accountId,
                        earliest.minusDays(SUBSCRIPTION_WINDOW_DAYS), latest.plusDays(SUBSCRIPTION_WINDOW_DAYS))
                .stream()
                .filter(t -> t.getImportFingerprint() == null)
                .sorted(Comparator.comparing(Transaction::getDate).thenComparing(Transaction::getId))
                .toList();
    }

    private static boolean isCandidate(ImportDraftLine line, Transaction transaction) {
        return line.getTransactionType() == transaction.getType()
                && line.getAmount().compareTo(transaction.getMontant()) == 0
                && inWindow(line, transaction);
    }

    private static boolean inWindow(ImportDraftLine line, Transaction transaction) {
        // Positive when the transaction is dated after the reference date of the line.
        long offset = ChronoUnit.DAYS.between(line.transactionDate(), transaction.getDate());
        if (transaction.getSubscription() != null) {
            return Math.abs(offset) <= SUBSCRIPTION_WINDOW_DAYS;
        }
        if (line.getPurchaseDate() != null) {
            return Math.abs(offset) <= PURCHASE_DATE_WINDOW_DAYS;
        }
        return offset >= -BOOKING_DAYS_BEFORE && offset <= BOOKING_DAYS_AFTER;
    }

    /** Whether the line already stands for the transaction: matched with it, or skipped because it was imported before. */
    private static boolean stands(ImportDraftLine line, UUID transactionId) {
        return transactionId.equals(line.getMatchedTransactionId())
                || (ImportService.isAlreadyImported(line) && transactionId.equals(line.getDuplicateTransactionId()));
    }
}
