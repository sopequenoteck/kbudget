package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Debt;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DebtRepository extends JpaRepository<Debt, UUID> {

    List<Debt> findByUserIdOrderByDateDesc(UUID userId);

    List<Debt> findByUserIdAndRembourseFalseOrderByDateDesc(UUID userId);
}
