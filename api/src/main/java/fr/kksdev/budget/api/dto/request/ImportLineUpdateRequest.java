package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.Size;

import java.util.UUID;

public record ImportLineUpdateRequest(
        UUID categoryId,
        @Size(max = 20) String status,
        /** Rapproche la ligne de cette transaction existante, sans controle de fenetre de date (KKS-385). Optionnel. */
        UUID matchedTransactionId,
        /** {@code true} defait le rapprochement : une transaction sera creee a la confirmation (KKS-385). Optionnel. */
        Boolean clearMatch
) {}
