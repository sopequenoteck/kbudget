package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Budget;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BudgetRepository extends JpaRepository<Budget, UUID> {

    List<Budget> findByUserId(UUID userId);

    List<Budget> findByUserIdAndActifTrue(UUID userId);

    Optional<Budget> findByIdAndUserId(UUID id, UUID userId);

    boolean existsByCategoryIdAndUserId(UUID categoryId, UUID userId);
}
