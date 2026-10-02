package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.ImportDraft;

import java.time.LocalDateTime;
import java.util.UUID;

public record ImportDraftSummaryResponse(
        UUID id,
        UUID accountId,
        String accountName,
        String status,
        String fileName,
        int totalLines,
        int readyCount,
        int reviewCount,
        int duplicateCount,
        int skippedCount,
        /** Sous-ensemble de skippedCount : lignes ecartees car deja importees (KKS-382). */
        int alreadyImportedCount,
        LocalDateTime createdAt,
        LocalDateTime expiresAt,
        /** Sous-ensemble de readyCount : lignes rapprochees d'une transaction existante (KKS-385). */
        int matchedCount
) {
    public static ImportDraftSummaryResponse from(ImportDraft draft) {
        return new ImportDraftSummaryResponse(
                draft.getId(),
                draft.getAccount().getId(),
                draft.getAccount().getNom(),
                draft.getStatus().name(),
                draft.getFileName(),
                draft.getTotalLines(),
                draft.getReadyCount(),
                draft.getReviewCount(),
                draft.getDuplicateCount(),
                draft.getSkippedCount(),
                draft.getAlreadyImportedCount(),
                draft.getCreatedAt(),
                draft.getExpiresAt(),
                draft.getMatchedCount()
        );
    }
}
