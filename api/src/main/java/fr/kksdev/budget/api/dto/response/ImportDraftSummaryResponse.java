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
        LocalDateTime createdAt,
        LocalDateTime expiresAt
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
                draft.getCreatedAt(),
                draft.getExpiresAt()
        );
    }
}
