package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.CategoryRule;

import java.time.LocalDateTime;
import java.util.UUID;

public record CategoryRuleResponse(
        UUID id,
        String pattern,
        UUID categoryId,
        String categoryName,
        /** Cle stable de la categorie systeme, null pour une categorie utilisateur (KKS-395). */
        String categorySystemKey,
        String categoryIcon,
        LocalDateTime createdAt,
        /** MANUAL (saisie) ou AUTO (creee par une correction pendant la revue) — KKS-383. */
        String origin
) {
    public static CategoryRuleResponse from(CategoryRule rule) {
        return new CategoryRuleResponse(
                rule.getId(),
                rule.getPattern(),
                rule.getCategory().getId(),
                rule.getCategory().getNom(),
                rule.getCategory().getSystemKey() != null ? rule.getCategory().getSystemKey().name() : null,
                rule.getCategory().getIcone(),
                rule.getCreatedAt(),
                rule.getOrigin() != null ? rule.getOrigin().name() : null
        );
    }
}
