package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record AdjustBalanceRequest(
        @NotNull BigDecimal newBalance,
        @Size(max = 255) String libelle
) {}
