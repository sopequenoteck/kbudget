package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.Frequency;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record SubscriptionResponse(
        UUID id,
        String nom,
        BigDecimal montant,
        Frequency frequence,
        LocalDate dateDebut,
        Boolean actif,
        CategoryResponse category
) {}
