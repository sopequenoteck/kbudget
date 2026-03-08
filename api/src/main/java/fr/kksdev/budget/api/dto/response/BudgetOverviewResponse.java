package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.util.List;

public record BudgetOverviewResponse(
        String month,
        BigDecimal totalBudget,
        BigDecimal totalSpent,
        BigDecimal percentage,
        String currency,
        List<BudgetOverviewItemResponse> items
) {}
