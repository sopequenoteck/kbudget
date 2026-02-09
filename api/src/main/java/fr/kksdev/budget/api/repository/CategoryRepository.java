package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {

    List<Category> findByUserIdOrderByNomAsc(UUID userId);

    boolean existsByNomAndUserId(String nom, UUID userId);

    boolean existsByNomAndUserIdAndIdNot(String nom, UUID userId, UUID id);
}
