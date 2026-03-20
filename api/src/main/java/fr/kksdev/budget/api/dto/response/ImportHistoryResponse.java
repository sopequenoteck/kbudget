package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.ImportHistory;

import java.time.LocalDateTime;
import java.util.UUID;

public record ImportHistoryResponse(
        UUID id,
        UUID accountId,
        String accountName,
        int transactionCount,
        String fileName,
        LocalDateTime importedAt
) {
    public static ImportHistoryResponse from(ImportHistory history) {
        return new ImportHistoryResponse(
                history.getId(),
                history.getAccount().getId(),
                history.getAccount().getNom(),
                history.getTransactionCount(),
                history.getFileName(),
                history.getImportedAt()
        );
    }
}
