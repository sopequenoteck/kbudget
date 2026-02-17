package fr.kksdev.budget.api.dto.response;

import java.util.UUID;

public record AccountSummary(
        UUID id,
        String nom,
        String icone,
        String couleur,
        String currency
) {}
