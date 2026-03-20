package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record RecurringTransactionResponse(
        UUID id,
        BigDecimal montant,
        String libelle,
        TransactionType type,
        Frequency frequency,
        LocalDate nextOccurrence,
        Boolean recurringActive,
        CategoryResponse category,
        AccountSummary account
) {}
