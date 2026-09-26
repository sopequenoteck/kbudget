package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.util.UUID;

public record UnbudgetedItemResponse(
        UUID categoryId,
        String categoryNom,
        /** Cle stable de la categorie systeme, null pour une categorie utilisateur (KKS-395). */
        String categorySystemKey,
        String categoryIcone,
        String categoryCouleur,
        BigDecimal montantDepense,
        String currency
) {}
