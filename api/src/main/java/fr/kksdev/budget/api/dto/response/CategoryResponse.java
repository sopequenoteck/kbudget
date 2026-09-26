package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.Category;

import java.util.UUID;

public record CategoryResponse(
        UUID id,
        String nom,
        String icone,
        String couleur,
        boolean isSystem,
        /** Cle stable de la categorie systeme (nom de {@code SystemCategoryKey}), null pour une categorie utilisateur (KKS-395). */
        String systemKey
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
                Boolean.TRUE.equals(category.getIsSystem()),
                category.getSystemKey() != null ? category.getSystemKey().name() : null
        );
    }
}
