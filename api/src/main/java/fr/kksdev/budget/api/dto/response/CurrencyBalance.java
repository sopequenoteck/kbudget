package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.Currency;

import java.math.BigDecimal;

public record CurrencyBalance(
        Currency currency,
        BigDecimal amount
) {}
