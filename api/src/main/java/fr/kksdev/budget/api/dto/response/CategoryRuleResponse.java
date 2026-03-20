package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.model.CategoryRule;

import java.time.LocalDateTime;
import java.util.UUID;

public record CategoryRuleResponse(
        UUID id,
        String pattern,
        UUID categoryId,
        String categoryName,
        String categoryIcon,
        LocalDateTime createdAt
) {
    public static CategoryRuleResponse from(CategoryRule rule) {
        return new CategoryRuleResponse(
                rule.getId(),
                rule.getPattern(),
                rule.getCategory().getId(),
                rule.getCategory().getNom(),
                rule.getCategory().getIcone(),
                rule.getCreatedAt()
        );
    }
}
