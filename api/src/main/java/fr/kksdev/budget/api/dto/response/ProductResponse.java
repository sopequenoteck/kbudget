package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record ProductResponse(
        UUID id,
        String nom,
        String description,
        String icone,
        String imageUrl,
        BigDecimal prixAchat,
        BigDecimal prixVente,
        Integer stock,
        Integer totalVendu,
        Boolean actif,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {}
