package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record ExchangeRateResponse(
        UUID id,
        String baseCurrency,
        String targetCurrency,
        BigDecimal rate,
        LocalDateTime updatedAt
) {}
