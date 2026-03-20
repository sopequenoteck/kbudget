package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.model.ImportDraft;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ImportDraftRepository extends JpaRepository<ImportDraft, UUID> {

    Optional<ImportDraft> findByUserIdAndAccountIdAndStatus(UUID userId, UUID accountId, ImportDraftStatus status);

    List<ImportDraft> findByUserIdOrderByCreatedAtDesc(UUID userId);

    void deleteByStatusAndExpiresAtBefore(ImportDraftStatus status, LocalDateTime now);

    List<ImportDraft> findByStatusAndExpiresAtBefore(ImportDraftStatus status, LocalDateTime now);
}
