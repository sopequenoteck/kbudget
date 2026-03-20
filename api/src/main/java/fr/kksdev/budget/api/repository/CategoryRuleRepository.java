package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.CategoryRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategoryRuleRepository extends JpaRepository<CategoryRule, UUID> {

    List<CategoryRule> findByUserIdOrderByCreatedAtAsc(UUID userId);

    boolean existsByUserIdAndPatternIgnoreCase(UUID userId, String pattern);

    Optional<CategoryRule> findByIdAndUserId(UUID id, UUID userId);
}
