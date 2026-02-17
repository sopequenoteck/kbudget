package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;

public record MonthlySummaryResponse(
        int month,
        int year,
        BigDecimal totalRecettes,
        BigDecimal totalDepenses,
        BigDecimal solde,
        String currency
) {}
