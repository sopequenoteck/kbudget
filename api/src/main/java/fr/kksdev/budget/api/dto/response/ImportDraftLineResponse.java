package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.SystemCategoryKey;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.util.MerchantKey;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Objects;
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
        /** Cle stable de la categorie systeme, null pour une categorie utilisateur (KKS-395). */
        String categorySystemKey,
        UUID duplicateTransactionId,
        boolean suggestRule,
        /** Raison d'un SKIPPED decide par l'import (ex. ALREADY_IMPORTED), null sinon (KKS-382). */
        String skipReason,
        /** Origine de la categorie : RULE, HISTORY ou USER, null sans categorie (KKS-383). */
        String categorySource,
        /** Date d'achat lue dans le libelle brut d'un paiement carte ; {@code date} reste la date comptable (KKS-385). */
        LocalDate purchaseDate,
        /** Transaction existante a laquelle la ligne est rapprochee : elle ne creera rien a la confirmation (KKS-385). */
        UUID matchedTransactionId,
        /** Transactions candidates d'un rapprochement ambigu (statut DUPLICATE) ; liste vide sinon (KKS-385). */
        List<UUID> matchCandidateIds,
        /** Abonnement auquel la transaction creee sera rattachee (KKS-385). */
        UUID subscriptionId,
        /** Detail de la transaction rapprochee, null sans rapprochement ou si elle a disparu depuis (KKS-386). */
        ImportMatchedTransactionResponse matchedTransaction,
        /** Detail des candidats de {@code matchCandidateIds}, dans le meme ordre ; un candidat disparu en est absent (KKS-386). */
        List<ImportMatchedTransactionResponse> matchCandidates,
        /** Cle commercant du libelle nettoye : les lignes de meme cle (et de meme sens) recoivent ensemble la categorie corrigee (KKS-386). */
        String merchantKey
) {
    public static ImportDraftLineResponse from(ImportDraftLine line) {
        return from(line, false, Map.of());
    }

    /**
     * @param transactions detail of the existing transactions the line refers to, by id; only
     *                     transactions of the user must be given (KKS-386)
     */
    public static ImportDraftLineResponse from(ImportDraftLine line, boolean suggestRule,
                                               Map<UUID, ImportMatchedTransactionResponse> transactions) {
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
                line.getCategory() != null ? SystemCategoryKey.nameOf(line.getCategory().getSystemKey()) : null,
                line.getDuplicateTransactionId(),
                suggestRule,
                line.getSkipReason() != null ? line.getSkipReason().name() : null,
                line.getCategory() != null && line.getCategorySource() != null ? line.getCategorySource().name() : null,
                line.getPurchaseDate(),
                line.getMatchedTransactionId(),
                line.getMatchCandidateIds(),
                line.getSubscriptionId(),
                line.getMatchedTransactionId() == null ? null : transactions.get(line.getMatchedTransactionId()),
                line.getMatchCandidateIds().stream().map(transactions::get).filter(Objects::nonNull).toList(),
                MerchantKey.of(line.getCleanLabel())
        );
    }
}
