package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.ImportDraft;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
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
        /** Sous-ensemble de skippedCount : lignes ecartees car deja importees (KKS-382). */
        int alreadyImportedCount,
        String profileName,
        String profileSource,
        LocalDateTime createdAt,
        LocalDateTime expiresAt,
        List<ImportDraftLineResponse> lines,
        /** 4 derniers chiffres du numero de compte lus dans l'en-tete du releve (KKS-384) ; nul sans en-tete exploitable. */
        String statementAccountSuffix,
        /** Solde donne par la banque dans l'en-tete du releve (KKS-384). */
        BigDecimal statementBalance,
        LocalDate statementBalanceDate,
        /** Solde que l'application aura a la date du solde si l'import est confirme tel quel (KKS-384). */
        BigDecimal projectedBalance,
        /** Premier import du compte seulement : solde initial qui ferait egaler solde de l'application et solde bancaire (KKS-384). */
        BigDecimal proposedOpeningBalance,
        /** Sous-ensemble de readyCount : lignes rapprochees d'une transaction existante (KKS-385). */
        int matchedCount
) {
    public static ImportDraftResponse from(ImportDraft draft, BigDecimal projectedBalance,
                                           BigDecimal proposedOpeningBalance,
                                           Map<UUID, ImportMatchedTransactionResponse> transactions) {
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
                draft.getAlreadyImportedCount(),
                null,
                draft.getProfileSource() != null ? draft.getProfileSource().name() : null,
                draft.getCreatedAt(),
                draft.getExpiresAt(),
                draft.getLines().stream()
                        .map(line -> ImportDraftLineResponse.from(line, false, transactions))
                        .toList(),
                draft.getStatementAccountSuffix(),
                draft.getStatementBalance(),
                draft.getStatementBalanceDate(),
                projectedBalance,
                proposedOpeningBalance,
                draft.getMatchedCount()
        );
    }
}
