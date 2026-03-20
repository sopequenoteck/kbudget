package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.ImportDraftLine;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record ImportDraftLineResponse(
        UUID id,
        int lineNumber,
        String rawLabel,
        String cleanLabel,
        BigDecimal amount,
        LocalDate date,
        String transactionType,
        String status,
        String statusMessage,
        UUID categoryId,
        String categoryName,
        UUID duplicateTransactionId,
        boolean suggestRule
) {
    public static ImportDraftLineResponse from(ImportDraftLine line) {
        return from(line, false);
    }

    public static ImportDraftLineResponse from(ImportDraftLine line, boolean suggestRule) {
        return new ImportDraftLineResponse(
                line.getId(),
                line.getLineNumber(),
                line.getRawLabel(),
                line.getCleanLabel(),
                line.getAmount(),
                line.getDate(),
                line.getTransactionType().name(),
                line.getStatus().name(),
                line.getStatusMessage(),
                line.getCategory() != null ? line.getCategory().getId() : null,
                line.getCategory() != null ? line.getCategory().getNom() : null,
                line.getDuplicateTransactionId(),
                suggestRule
        );
    }
}
