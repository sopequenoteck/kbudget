package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.BudgetSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BudgetSnapshotRepository extends JpaRepository<BudgetSnapshot, UUID> {

    List<BudgetSnapshot> findByUserIdAndMois(UUID userId, String mois);
}
