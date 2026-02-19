package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record AdjustBalanceRequest(
        @NotNull BigDecimal newBalance
) {}
