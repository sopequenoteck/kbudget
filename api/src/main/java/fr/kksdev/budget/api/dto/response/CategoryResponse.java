package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.Category;

import java.util.UUID;

public record CategoryResponse(
        UUID id,
        String nom,
        String icone,
        String couleur,
        boolean isSystem
) {
    public static CategoryResponse from(Category category) {
        if (category == null) {
            return null;
        }
        return new CategoryResponse(
                category.getId(),
                category.getNom(),
                category.getIcone(),
                category.getCouleur(),
                Boolean.TRUE.equals(category.getIsSystem())
        );
    }
}
