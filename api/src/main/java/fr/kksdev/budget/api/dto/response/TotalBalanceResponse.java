package fr.kksdev.budget.api.dto.response;

import java.util.List;

public record TotalBalanceResponse(
        List<CurrencyBalance> balances
) {}
