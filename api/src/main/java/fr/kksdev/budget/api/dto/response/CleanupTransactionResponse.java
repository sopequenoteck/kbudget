package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Transaction;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * A transaction as shown by the history cleanup (KKS-387).
 *
 * @param imported       whether it comes from a statement (it carries an import fingerprint, never served)
 * @param debtId         debt it repays, {@code null} when none
 * @param subscriptionId subscription it pays, {@code null} when none
 */
public record CleanupTransactionResponse(
        UUID id,
        LocalDate date,
        String libelle,
        BigDecimal montant,
        TransactionType type,
        CategoryResponse category,
        AccountSummary account,
        boolean imported,
        UUID debtId,
        UUID subscriptionId
) {
    public static CleanupTransactionResponse from(Transaction transaction) {
        return new CleanupTransactionResponse(
                transaction.getId(),
                transaction.getDate(),
                transaction.getLibelle(),
                transaction.getMontant(),
                transaction.getType(),
                CategoryResponse.from(transaction.getCategory()),
                AccountSummary.from(transaction.getAccount()),
                transaction.getImportFingerprint() != null,
                transaction.getDebt() != null ? transaction.getDebt().getId() : null,
                transaction.getSubscription() != null ? transaction.getSubscription().getId() : null);
    }
}
