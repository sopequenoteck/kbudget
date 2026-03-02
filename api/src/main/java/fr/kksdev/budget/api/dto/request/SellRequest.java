package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record SellRequest(
        @NotNull @Positive Integer quantity
) {}
