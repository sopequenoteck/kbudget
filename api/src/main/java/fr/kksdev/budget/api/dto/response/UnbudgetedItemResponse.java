package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record UnbudgetedItemResponse(
        UUID categoryId,
        String categoryNom,
        String categoryIcone,
        String categoryCouleur,
        BigDecimal montantDepense,
        String currency
) {}
