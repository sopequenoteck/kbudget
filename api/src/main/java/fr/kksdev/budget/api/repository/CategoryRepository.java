package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {

    List<Category> findByUserIdOrderByNomAsc(UUID userId);

    boolean existsByNomIgnoreCaseAndUserId(String nom, UUID userId);

    boolean existsByNomIgnoreCaseAndUserIdAndIdNot(String nom, UUID userId, UUID id);

    Optional<Category> findByNomIgnoreCaseAndUserId(String nom, UUID userId);

    List<Category> findByUserIdAndIsSystemTrue(UUID userId);
}
