package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Transaction;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Existing transaction a statement line is matched with, or one of its candidates,
 * for the review screen to show what it stands for (KKS-386).
 */
public record ImportMatchedTransactionResponse(
        UUID id,
        LocalDate date,
        String libelle,
        BigDecimal montant,
        TransactionType type
) {
    public static ImportMatchedTransactionResponse from(Transaction transaction) {
        return new ImportMatchedTransactionResponse(
                transaction.getId(), transaction.getDate(), transaction.getLibelle(),
                transaction.getMontant(), transaction.getType());
    }
}
