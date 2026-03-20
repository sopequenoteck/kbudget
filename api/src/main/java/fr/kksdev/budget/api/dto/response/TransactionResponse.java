package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record TransactionResponse(
        UUID id,
        BigDecimal montant,
        String libelle,
        TransactionType type,
        LocalDate date,
        CategoryResponse category,
        String note,
        AccountSummary account,
        UUID transferId,
        UUID productId,
        String productName,
        UUID debtId
) {}
