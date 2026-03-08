package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Frequency;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.util.UUID;

public record BudgetRequest(
        @NotNull UUID categoryId,
        @NotNull @Positive BigDecimal montant,
        @NotNull Frequency frequence,
        Currency currency,
        @Min(0) @Max(100) Integer seuilNotification,
        Boolean actif
) {}
