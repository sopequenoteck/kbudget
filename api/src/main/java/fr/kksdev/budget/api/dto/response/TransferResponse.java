package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record TransferResponse(
        UUID transferId,
        TransactionResponseRef debitTransaction,
        TransactionResponseRef creditTransaction
) {
    public record TransactionResponseRef(
            UUID id,
            BigDecimal montant,
            String libelle,
            TransactionType type,
            LocalDate date,
            UUID accountId,
            String accountNom
    ) {}
}
