package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.DuplicateMergeRequest;
import fr.kksdev.budget.api.dto.request.SubscriptionDuplicateMergeRequest;
import fr.kksdev.budget.api.dto.response.CleanupTransactionResponse;
import fr.kksdev.budget.api.dto.response.DuplicateMergeResponse;
import fr.kksdev.budget.api.dto.response.DuplicateProposalsResponse;
import fr.kksdev.budget.api.dto.response.DuplicateProposalsResponse.ImportedDuplicate;
import fr.kksdev.budget.api.dto.response.DuplicateProposalsResponse.SubscriptionDuplicate;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.CleanupConflictCode;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.util.SubscriptionPeriod;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Finds the operations counted twice in the history of a user, and merges them on request
 * (KKS-387). Steps 1 to 5 of KKS-382 to KKS-386 prevent new duplicates; this service deals with
 * the ones already stored. Reading changes nothing, and each merge is validated by the user.
 *
 * <p>Two kinds of duplicates:
 * <ul>
 *   <li>a transaction imported from a statement and the one the user had entered by hand: same
 *       account, type and amount, and a manual date within the window of the import matching
 *       ({@link ImportMatchingService#inWindowOfImported}). The manual transaction is kept, takes
 *       the import fingerprint (a later import of the same statement recognizes the line) and the
 *       imported one is deleted. A transaction is in one proposal only: an imported transaction with
 *       several candidates is one proposal listing them, and the candidates of a proposal are not
 *       offered elsewhere. A manual transaction that several imported ones could stand for goes to the
 *       one with the fewest candidates first; what remains shows up on the next reading;</li>
 *   <li>several payments of one subscription in the same due period ({@link SubscriptionPeriod}):
 *       the user keeps one and deletes the others. A group with more than one imported payment is
 *       not proposed, those are operations of the bank.</li>
 * </ul>
 * Recurring templates, transfer legs and adjustments are never proposed nor merged. A transaction
 * that repays a debt is only deleted when the one kept repays the same debt, since the remaining
 * amount of a debt is the sum of its transactions.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DuplicateCleanupService {

    private static final String TRANSACTION_NOT_FOUND = "Transaction not found";

    private final TransactionRepository transactionRepository;
    private final DebtRepository debtRepository;

    /** Account, type and amount that two transactions must share to stand for the same operation. */
    private record OperationKey(UUID accountId, TransactionType type, BigDecimal amount) {

        static OperationKey of(Transaction transaction) {
            return new OperationKey(transaction.getAccount().getId(), transaction.getType(),
                    transaction.getMontant().stripTrailingZeros());
        }
    }

    /** One subscription and one due period. */
    private record PaymentKey(UUID subscriptionId, SubscriptionPeriod period) {

        static PaymentKey of(Transaction transaction) {
            Subscription subscription = transaction.getSubscription();
            return new PaymentKey(subscription.getId(), SubscriptionPeriod.containing(
                    subscription.getDateDebut(), subscription.getFrequence(), transaction.getDate()));
        }
    }

    /** An imported transaction and the manual ones it may stand for. */
    private record Match(Transaction imported, List<Transaction> candidates) {}

    public DuplicateProposalsResponse findProposals(UUID userId) {
        List<Transaction> mergeable = transactionRepository.findMergeableByUserId(userId, TransactionType.AJUSTEMENT);
        Set<UUID> claimed = new HashSet<>();
        List<ImportedDuplicate> imported = findImportedDuplicates(mergeable, claimed);
        List<SubscriptionDuplicate> subscriptions = findSubscriptionDuplicates(mergeable, claimed);
        log.info("History cleanup duplicates read: {} imported, {} subscription groups, userId={}",
                imported.size(), subscriptions.size(), userId);
        return new DuplicateProposalsResponse(imported, subscriptions);
    }

    /**
     * Merges an imported transaction into the one entered by hand.
     *
     * @throws EntityNotFoundException when a transaction is not the user's
     * @throws IllegalArgumentException when both ids are the same
     * @throws fr.kksdev.budget.api.exception.ConflictException {@code CLEANUP_PROPOSAL_STALE} when the pair no
     *         longer satisfies the criteria, {@code CLEANUP_DEBT_LINK_MISSING} when the debt link would be lost
     */
    @Transactional
    public DuplicateMergeResponse mergeImported(DuplicateMergeRequest request, UUID userId) {
        if (request.importedTransactionId().equals(request.keptTransactionId())) {
            throw new IllegalArgumentException("The imported and the kept transactions must differ");
        }
        Map<UUID, Transaction> found = load(userId, List.of(request.importedTransactionId(), request.keptTransactionId()));
        Transaction imported = found.get(request.importedTransactionId());
        Transaction kept = found.get(request.keptTransactionId());
        requireMergeable(imported);
        requireMergeable(kept);
        if (imported.getImportFingerprint() == null || kept.getImportFingerprint() != null || !sameOperation(imported, kept)) {
            throw CleanupConflictCode.CLEANUP_PROPOSAL_STALE.toException();
        }
        requireDebtLinkKept(imported, kept);

        kept.setImportFingerprint(imported.getImportFingerprint());
        if (kept.getSubscription() == null) {
            // The payment link of the statement line is not lost when the manual entry had none.
            kept.setSubscription(imported.getSubscription());
        }
        transactionRepository.save(kept);
        delete(List.of(imported));
        log.info("Imported duplicate merged: keptId={}, removedId={}, userId={}", kept.getId(), imported.getId(), userId);
        return new DuplicateMergeResponse(CleanupTransactionResponse.from(kept), List.of(imported.getId()));
    }

    /**
     * Keeps one payment of a subscription for a due period and deletes the others.
     *
     * @throws EntityNotFoundException when a transaction is not the user's
     * @throws IllegalArgumentException when the kept transaction is also to be removed
     * @throws fr.kksdev.budget.api.exception.ConflictException {@code CLEANUP_PROPOSAL_STALE} when the payments are
     *         not of the same subscription and period any more, or one to remove is imported;
     *         {@code CLEANUP_DEBT_LINK_MISSING} when a debt link would be lost
     */
    @Transactional
    public DuplicateMergeResponse mergeSubscriptionPayments(SubscriptionDuplicateMergeRequest request, UUID userId) {
        Set<UUID> removedIds = new LinkedHashSet<>(request.removedTransactionIds());
        if (removedIds.contains(request.keptTransactionId())) {
            throw new IllegalArgumentException("The kept transaction cannot also be removed");
        }
        Set<UUID> ids = new LinkedHashSet<>(removedIds);
        ids.add(request.keptTransactionId());
        Map<UUID, Transaction> found = load(userId, ids);
        Transaction kept = found.get(request.keptTransactionId());
        List<Transaction> removed = removedIds.stream().map(found::get).toList();

        requireMergeable(kept);
        removed.forEach(DuplicateCleanupService::requireMergeable);
        if (kept.getSubscription() == null) {
            throw CleanupConflictCode.CLEANUP_PROPOSAL_STALE.toException();
        }
        PaymentKey key = PaymentKey.of(kept);
        for (Transaction payment : removed) {
            if (payment.getSubscription() == null || !key.equals(PaymentKey.of(payment))
                    || payment.getImportFingerprint() != null) {
                throw CleanupConflictCode.CLEANUP_PROPOSAL_STALE.toException();
            }
            requireDebtLinkKept(payment, kept);
        }

        delete(removed);
        log.info("Subscription payments merged: keptId={}, removedCount={}, userId={}",
                kept.getId(), removed.size(), userId);
        return new DuplicateMergeResponse(CleanupTransactionResponse.from(kept), List.copyOf(removedIds));
    }

    private List<ImportedDuplicate> findImportedDuplicates(List<Transaction> mergeable, Set<UUID> claimed) {
        Map<OperationKey, List<Transaction>> manualByOperation = mergeable.stream()
                .filter(t -> t.getImportFingerprint() == null)
                .collect(Collectors.groupingBy(OperationKey::of));
        List<Match> matches = mergeable.stream()
                .filter(t -> t.getImportFingerprint() != null)
                .map(imported -> new Match(imported, manualByOperation
                        .getOrDefault(OperationKey.of(imported), List.of()).stream()
                        .filter(manual -> ImportMatchingService.inWindowOfImported(imported.getDate(), manual))
                        .toList()))
                .filter(match -> !match.candidates().isEmpty())
                // The fewest candidates first: a manual transaction with one possible import goes to it.
                .sorted(Comparator.comparingInt((Match match) -> match.candidates().size())
                        .thenComparing(match -> match.imported().getDate())
                        .thenComparing(match -> match.imported().getId()))
                .toList();

        List<ImportedDuplicate> proposals = new ArrayList<>();
        for (Match match : matches) {
            List<Transaction> free = match.candidates().stream().filter(t -> !claimed.contains(t.getId())).toList();
            if (free.isEmpty()) {
                continue;
            }
            claimed.add(match.imported().getId());
            free.forEach(t -> claimed.add(t.getId()));
            proposals.add(new ImportedDuplicate(
                    CleanupTransactionResponse.from(match.imported()),
                    free.stream()
                            .sorted(Comparator.comparingLong((Transaction t) ->
                                            Math.abs(ChronoUnit.DAYS.between(match.imported().getDate(), t.getDate())))
                                    .thenComparing(Transaction::getDate).thenComparing(Transaction::getId))
                            .map(CleanupTransactionResponse::from)
                            .toList()));
        }
        proposals.sort(Comparator.comparing((ImportedDuplicate p) -> p.imported().date())
                .thenComparing(p -> p.imported().id()));
        return proposals;
    }

    private static List<SubscriptionDuplicate> findSubscriptionDuplicates(List<Transaction> mergeable, Set<UUID> claimed) {
        Map<PaymentKey, List<Transaction>> byPeriod = mergeable.stream()
                .filter(t -> t.getSubscription() != null && !claimed.contains(t.getId()))
                .collect(Collectors.groupingBy(PaymentKey::of, LinkedHashMap::new, Collectors.toList()));
        return byPeriod.entrySet().stream()
                .filter(entry -> entry.getValue().size() > 1 && importedCount(entry.getValue()) <= 1)
                .map(entry -> toSubscriptionDuplicate(entry.getKey(), entry.getValue()))
                .toList();
    }

    private static SubscriptionDuplicate toSubscriptionDuplicate(PaymentKey key, List<Transaction> payments) {
        // Oldest first, as the repository sorts them.
        Transaction suggested = payments.stream()
                .filter(t -> t.getImportFingerprint() != null)
                .findFirst()
                .orElse(payments.getFirst());
        Subscription subscription = suggested.getSubscription();
        return new SubscriptionDuplicate(
                key.subscriptionId(), subscription.getNom(), key.period().start(), key.period().end(),
                suggested.getId(), payments.stream().map(CleanupTransactionResponse::from).toList());
    }

    private static long importedCount(Collection<Transaction> transactions) {
        return transactions.stream().filter(t -> t.getImportFingerprint() != null).count();
    }

    /** The transactions of the user among {@code ids}; one that is missing or someone else's is not found. */
    private Map<UUID, Transaction> load(UUID userId, Collection<UUID> ids) {
        Map<UUID, Transaction> found = transactionRepository.findByUserIdAndIdIn(userId, ids).stream()
                .collect(Collectors.toMap(Transaction::getId, Function.identity()));
        if (!found.keySet().containsAll(ids)) {
            log.error("Transaction to merge not found: userId={}", userId);
            throw new EntityNotFoundException(TRANSACTION_NOT_FOUND);
        }
        return found;
    }

    private static void requireMergeable(Transaction transaction) {
        if (transaction.getType() == TransactionType.AJUSTEMENT
                || Boolean.TRUE.equals(transaction.getIsRecurring())
                || transaction.getTransferId() != null) {
            throw CleanupConflictCode.CLEANUP_PROPOSAL_STALE.toException();
        }
    }

    private static boolean sameOperation(Transaction imported, Transaction manual) {
        return OperationKey.of(imported).equals(OperationKey.of(manual))
                && ImportMatchingService.inWindowOfImported(imported.getDate(), manual);
    }

    private static void requireDebtLinkKept(Transaction removed, Transaction kept) {
        Debt debt = removed.getDebt();
        if (debt != null && (kept.getDebt() == null || !kept.getDebt().getId().equals(debt.getId()))) {
            throw CleanupConflictCode.CLEANUP_DEBT_LINK_MISSING.toException();
        }
    }

    /** Deletes the transactions, then reopens the debts they repaid that are no longer fully repaid. */
    private void delete(List<Transaction> removed) {
        Map<UUID, Debt> debts = removed.stream()
                .map(Transaction::getDebt)
                .filter(Objects::nonNull)
                .collect(Collectors.toMap(Debt::getId, Function.identity(), (first, second) -> first));
        transactionRepository.deleteAll(removed);
        transactionRepository.flush();
        for (Debt debt : debts.values()) {
            BigDecimal paid = transactionRepository.sumByDebtId(debt.getId());
            if (Boolean.TRUE.equals(debt.getRembourse()) && debt.getMontant().compareTo(paid) > 0) {
                debt.setRembourse(false);
                debtRepository.save(debt);
                log.info("Debt reopened after a duplicate was removed: debtId={}", debt.getId());
            }
        }
    }
}
