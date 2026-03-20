package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.text.similarity.JaroWinklerSimilarity;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DeduplicationService {

    private static final double SIMILARITY_THRESHOLD = 0.85;

    private final TransactionRepository transactionRepository;

    public void detectDuplicates(List<ImportDraftLine> lines, UUID accountId, UUID userId) {
        if (lines == null || lines.isEmpty()) {
            return;
        }

        // Find the date range from the lines
        LocalDate minDate = lines.stream()
                .map(ImportDraftLine::getDate)
                .min(Comparator.naturalOrder())
                .orElse(LocalDate.now());
        LocalDate maxDate = lines.stream()
                .map(ImportDraftLine::getDate)
                .max(Comparator.naturalOrder())
                .orElse(LocalDate.now());

        // Query existing transactions with 3-day margin on each side
        List<Transaction> existingTransactions = transactionRepository.findByUserIdAndAccountIdAndDateBetween(
                userId, accountId, minDate.minusDays(3), maxDate.plusDays(3));

        JaroWinklerSimilarity similarity = new JaroWinklerSimilarity();
        int duplicateCount = 0;

        for (ImportDraftLine line : lines) {
            for (Transaction existing : existingTransactions) {
                // Only match same transaction type
                if (line.getTransactionType() != existing.getType()) {
                    continue;
                }

                // Exact match on date AND amount
                boolean dateMatch = line.getDate().equals(existing.getDate());
                boolean amountMatch = line.getAmount().compareTo(existing.getMontant()) == 0;

                if (dateMatch && amountMatch) {
                    // Compute label similarity
                    String lineLabel = line.getCleanLabel() != null ? line.getCleanLabel() : "";
                    String existingLabel = existing.getLibelle() != null ? existing.getLibelle() : "";
                    double score = similarity.apply(lineLabel, existingLabel);

                    if (score >= SIMILARITY_THRESHOLD) {
                        line.setStatus(ImportLineStatus.DUPLICATE);
                        line.setDuplicateTransactionId(existing.getId());
                        duplicateCount++;
                        break;
                    }
                }
            }
        }

        log.info("Deduplication: {} duplicates found out of {} lines", duplicateCount, lines.size());
    }
}
