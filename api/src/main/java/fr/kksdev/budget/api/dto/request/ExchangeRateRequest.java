package fr.kksdev.budget.api.dto.request;

import fr.kksdev.budget.api.enums.Currency;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record ExchangeRateRequest(
        @NotNull Currency baseCurrency,
        @NotNull Currency targetCurrency,
        @NotNull @DecimalMin("0.000001") @Digits(integer = 14, fraction = 6) BigDecimal rate
) {}
