package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record BudgetResponse(
        UUID id,
        BigDecimal montant,
        String currency,
        String frequence,
        Integer seuilNotification,
        Boolean actif,
        CategoryResponse category,
        BigDecimal spent,
        LocalDateTime updatedAt
) {}
