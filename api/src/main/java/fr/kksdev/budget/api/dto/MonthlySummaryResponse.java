package fr.kksdev.budget.api.dto;

import java.math.BigDecimal;

public record MonthlySummaryResponse(
        int month,
        int year,
        BigDecimal totalRecettes,
        BigDecimal totalDepenses,
        BigDecimal solde
) {}
