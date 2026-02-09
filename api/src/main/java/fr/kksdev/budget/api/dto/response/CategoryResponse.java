package fr.kksdev.budget.api.dto.response;

import java.util.UUID;

public record CategoryResponse(
        UUID id,
        String nom,
        String icone,
        String couleur
) {}
