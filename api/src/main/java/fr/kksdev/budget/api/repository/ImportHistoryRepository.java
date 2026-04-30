package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.ImportHistory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ImportHistoryRepository extends JpaRepository<ImportHistory, UUID> {

    Page<ImportHistory> findByUserIdOrderByImportedAtDesc(UUID userId, Pageable pageable);

    List<ImportHistory> findByUserId(UUID userId);
}
