package fr.kksdev.budget.api.dto.response;

public record CurrencyInfo(
        String code,
        String symbol,
        String name,
        int decimalPlaces
) {}
