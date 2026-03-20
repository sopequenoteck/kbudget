package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.ImportDraft;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record ImportDraftResponse(
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
        String profileName,
        String profileSource,
        LocalDateTime createdAt,
        LocalDateTime expiresAt,
        List<ImportDraftLineResponse> lines
) {
    public static ImportDraftResponse from(ImportDraft draft) {
        return new ImportDraftResponse(
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
                null,
                draft.getProfileSource() != null ? draft.getProfileSource().name() : null,
                draft.getCreatedAt(),
                draft.getExpiresAt(),
                draft.getLines().stream()
                        .map(ImportDraftLineResponse::from)
                        .toList()
        );
    }
}
