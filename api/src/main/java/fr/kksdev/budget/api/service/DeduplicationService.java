package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.ImportSkipReason;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.util.ImportFingerprint;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.text.similarity.JaroWinklerSimilarity;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayDeque;
import java.util.Comparator;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.BiConsumer;
import java.util.function.BiPredicate;

/**
 * Rapproche les lignes d'un releve des transactions deja en base, en trois
 * passes de la plus sure a la plus incertaine (KKS-382).
 *
 * <ol>
 *   <li><strong>Empreinte</strong> : la ligne a deja ete importee depuis KKS-382.
 *       Certain, meme si la transaction a ete renommee ou recategorisee depuis.</li>
 *   <li><strong>Import anterieur</strong> : transaction sans empreinte, de meme
 *       date, montant et sens, au libelle nettoye identique.</li>
 *   <li><strong>Doublon probable</strong> : meme date, montant et sens, libelle
 *       seulement proche. Reste bloquant : c'est a l'utilisateur de trancher.</li>
 * </ol>
 *
 * Les deux premieres passes ecartent la ligne d'office ({@code SKIPPED} +
 * {@link ImportSkipReason#ALREADY_IMPORTED}) au lieu de bloquer l'import.
 *
 * <p>Chaque transaction ne sert qu'une fois : deux lignes identiques d'un meme
 * releve sont deux operations reelles, et ne sont ecartees que si la base en
 * contient deux.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeduplicationService {

    private static final double SIMILARITY_THRESHOLD = 0.85;
    private static final int DATE_MARGIN_DAYS = 3;

    private final TransactionRepository transactionRepository;

    public void detectDuplicates(List<ImportDraftLine> lines, UUID accountId, UUID userId) {
        List<ImportDraftLine> candidates = lines == null ? List.of() : lines.stream()
                .filter(l -> l.getStatus() == ImportLineStatus.READY)
                .toList();
        if (candidates.isEmpty()) {
            return;
        }

        Set<UUID> consumed = new HashSet<>();
        int byFingerprint = matchByFingerprint(candidates, accountId, userId, consumed);

        List<Transaction> window = findInDateWindow(candidates, accountId, userId);
        List<Transaction> withoutFingerprint = window.stream().filter(t -> t.getImportFingerprint() == null).toList();
        int byLabel = matchRemaining(candidates, withoutFingerprint, consumed,
                DeduplicationService::sameCleanLabel, DeduplicationService::markAlreadyImported);

        int duplicates = matchRemaining(candidates, window, consumed,
                DeduplicationService::similarLabel, DeduplicationService::markDuplicate);

        log.info("Deduplication: {} already imported ({} by fingerprint, {} by label), {} probable duplicates out of {} lines",
                byFingerprint + byLabel, byFingerprint, byLabel, duplicates, lines.size());
    }

    static String fingerprintOf(ImportDraftLine line) {
        return ImportFingerprint.of(line.getDate(), line.getAmount(), line.getTransactionType(), line.getRawLabel());
    }

    private int matchByFingerprint(List<ImportDraftLine> lines, UUID accountId, UUID userId, Set<UUID> consumed) {
        Map<ImportDraftLine, String> fingerprints = new IdentityHashMap<>();
        lines.forEach(line -> fingerprints.put(line, fingerprintOf(line)));

        Map<String, Deque<Transaction>> available = new HashMap<>();
        transactionRepository
                .findByUserIdAndAccountIdAndImportFingerprintIn(userId, accountId, new HashSet<>(fingerprints.values()))
                .stream()
                .sorted(Comparator.comparing(Transaction::getId))
                .forEach(t -> available.computeIfAbsent(t.getImportFingerprint(), k -> new ArrayDeque<>()).add(t));

        int matched = 0;
        for (ImportDraftLine line : lines) {
            Deque<Transaction> sameFingerprint = available.get(fingerprints.get(line));
            if (sameFingerprint == null || sameFingerprint.isEmpty()) {
                continue;
            }
            Transaction existing = sameFingerprint.poll();
            consumed.add(existing.getId());
            markAlreadyImported(line, existing);
            matched++;
        }
        return matched;
    }

    private int matchRemaining(List<ImportDraftLine> lines, List<Transaction> existing, Set<UUID> consumed,
                               BiPredicate<ImportDraftLine, Transaction> labelMatches,
                               BiConsumer<ImportDraftLine, Transaction> mark) {
        int matched = 0;
        for (ImportDraftLine line : lines) {
            if (line.getStatus() != ImportLineStatus.READY) {
                continue;
            }
            for (Transaction candidate : existing) {
                if (!consumed.contains(candidate.getId())
                        && sameOperation(line, candidate)
                        && labelMatches.test(line, candidate)) {
                    consumed.add(candidate.getId());
                    mark.accept(line, candidate);
                    matched++;
                    break;
                }
            }
        }
        return matched;
    }

    private List<Transaction> findInDateWindow(List<ImportDraftLine> lines, UUID accountId, UUID userId) {
        LocalDate minDate = lines.stream().map(ImportDraftLine::getDate).min(Comparator.naturalOrder()).orElseThrow();
        LocalDate maxDate = lines.stream().map(ImportDraftLine::getDate).max(Comparator.naturalOrder()).orElseThrow();
        return transactionRepository.findByUserIdAndAccountIdAndDateBetween(
                        userId, accountId, minDate.minusDays(DATE_MARGIN_DAYS), maxDate.plusDays(DATE_MARGIN_DAYS))
                .stream()
                .sorted(Comparator.comparing(Transaction::getId))
                .toList();
    }

    private static boolean sameOperation(ImportDraftLine line, Transaction existing) {
        return line.getTransactionType() == existing.getType()
                && line.getDate().equals(existing.getDate())
                && line.getAmount().compareTo(existing.getMontant()) == 0;
    }

    private static boolean sameCleanLabel(ImportDraftLine line, Transaction existing) {
        return trimmed(line.getCleanLabel()).equalsIgnoreCase(trimmed(existing.getLibelle()));
    }

    private static boolean similarLabel(ImportDraftLine line, Transaction existing) {
        return new JaroWinklerSimilarity().apply(trimmed(line.getCleanLabel()), trimmed(existing.getLibelle()))
                >= SIMILARITY_THRESHOLD;
    }

    private static String trimmed(String label) {
        return label == null ? "" : label.trim();
    }

    private static void markAlreadyImported(ImportDraftLine line, Transaction existing) {
        line.setStatus(ImportLineStatus.SKIPPED);
        line.setSkipReason(ImportSkipReason.ALREADY_IMPORTED);
        line.setDuplicateTransactionId(existing.getId());
    }

    private static void markDuplicate(ImportDraftLine line, Transaction existing) {
        line.setStatus(ImportLineStatus.DUPLICATE);
        line.setDuplicateTransactionId(existing.getId());
    }
}
