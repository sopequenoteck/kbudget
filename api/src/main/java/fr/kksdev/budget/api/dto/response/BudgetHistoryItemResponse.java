package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record BudgetHistoryItemResponse(
        UUID categoryId,
        String categoryNom,
        String categoryIcone,
        String categoryCouleur,
        BigDecimal montantBudget,
        String currency,
        BigDecimal tauxChange,
        BigDecimal montantDepense,
        BigDecimal percentage,
        LocalDateTime createdAt
) {}
