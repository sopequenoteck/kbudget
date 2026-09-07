package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.CategoryRuleResponse;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.CategoryRule;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.CategoryRuleRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryRuleService {

    private final CategoryRuleRepository categoryRuleRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    public List<CategoryRuleResponse> getAllByUser(UUID userId) {
        return categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(userId)
                .stream()
                .map(CategoryRuleResponse::from)
                .toList();
    }

    @Transactional
    public CategoryRuleResponse create(String pattern, UUID categoryId, UUID userId) {
        if (pattern == null || pattern.isBlank()) {
            throw new IllegalArgumentException("The pattern must not be empty");
        }

        Category category = categoryRepository.findById(categoryId)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Catégorie non trouvée: id={}, userId={}", categoryId, userId);
                    return new EntityNotFoundException("Category not found");
                });

        if (categoryRuleRepository.existsByUserIdAndPatternIgnoreCase(userId, pattern)) {
            throw new ConflictException("A rule with this pattern already exists: " + pattern);
        }

        CategoryRule rule = CategoryRule.builder()
                .user(userRepository.getReferenceById(userId))
                .pattern(pattern)
                .category(category)
                .build();

        rule = categoryRuleRepository.save(rule);
        log.info("Règle de catégorisation créée: id={}, pattern='{}', userId={}", rule.getId(), pattern, userId);

        return CategoryRuleResponse.from(rule);
    }

    @Transactional
    public CategoryRuleResponse update(UUID ruleId, String pattern, UUID categoryId, UUID userId) {
        CategoryRule rule = categoryRuleRepository.findByIdAndUserId(ruleId, userId)
                .orElseThrow(() -> {
                    log.error("Règle de catégorisation non trouvée: id={}, userId={}", ruleId, userId);
                    return new EntityNotFoundException("Category rule not found");
                });

        Category category = categoryRepository.findById(categoryId)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Catégorie non trouvée: id={}, userId={}", categoryId, userId);
                    return new EntityNotFoundException("Category not found");
                });

        rule.setPattern(pattern);
        rule.setCategory(category);

        rule = categoryRuleRepository.save(rule);
        log.info("Règle de catégorisation mise à jour: id={}, userId={}", ruleId, userId);

        return CategoryRuleResponse.from(rule);
    }

    @Transactional
    public void delete(UUID ruleId, UUID userId) {
        CategoryRule rule = categoryRuleRepository.findByIdAndUserId(ruleId, userId)
                .orElseThrow(() -> {
                    log.error("Règle de catégorisation non trouvée: id={}, userId={}", ruleId, userId);
                    return new EntityNotFoundException("Category rule not found");
                });

        categoryRuleRepository.delete(rule);
        log.info("Règle de catégorisation supprimée: id={}, userId={}", ruleId, userId);
    }

    public void applyRules(List<ImportDraftLine> lines, UUID userId) {
        List<CategoryRule> rules = categoryRuleRepository.findByUserIdOrderByCreatedAtAsc(userId);

        if (rules.isEmpty()) {
            return;
        }

        for (ImportDraftLine line : lines) {
            if (line.getCategory() != null) {
                continue;
            }

            String cleanLabel = line.getCleanLabel();
            if (cleanLabel == null) {
                continue;
            }

            for (CategoryRule rule : rules) {
                if (cleanLabel.toLowerCase().contains(rule.getPattern().toLowerCase())) {
                    line.setCategory(rule.getCategory());
                    if (line.getStatus() == ImportLineStatus.NEEDS_REVIEW) {
                        line.setStatus(ImportLineStatus.READY);
                    }
                    break;
                }
            }
        }
    }
}
