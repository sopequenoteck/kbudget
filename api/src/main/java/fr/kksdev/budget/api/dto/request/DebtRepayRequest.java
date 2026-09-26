package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.UUID;

public record DebtRepayRequest(
        @NotNull UUID accountId,
        @Positive BigDecimal amount,
        @Size(max = 255) String libelle
) {}
