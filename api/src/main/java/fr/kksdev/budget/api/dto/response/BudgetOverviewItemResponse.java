package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record BudgetOverviewItemResponse(
        UUID budgetId,
        UUID categoryId,
        String categoryNom,
        String categoryIcone,
        String categoryCouleur,
        BigDecimal montantBudget,
        BigDecimal montantBudgetNormalise,
        String currency,
        BigDecimal montantDepense,
        BigDecimal percentage,
        String frequence
) {}
