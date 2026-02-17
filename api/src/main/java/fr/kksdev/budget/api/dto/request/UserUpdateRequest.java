package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Currency;
import jakarta.validation.constraints.NotNull;

public record UserUpdateRequest(
        @NotNull Currency defaultCurrency
) {}
