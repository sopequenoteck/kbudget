package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.model.ImportDraft;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ImportDraftRepository extends JpaRepository<ImportDraft, UUID> {

    Optional<ImportDraft> findByUserIdAndAccountIdAndStatus(UUID userId, UUID accountId, ImportDraftStatus status);

    List<ImportDraft> findByUserIdOrderByCreatedAtDesc(UUID userId);

    /**
     * Drafts of the user in {@code status} whose statement gave a bank balance and its date (KKS-387),
     * the latest balance date first, then the most recently created.
     */
    @Query("SELECT d FROM ImportDraft d JOIN FETCH d.account WHERE d.user.id = :userId AND d.status = :status " +
            "AND d.statementBalance IS NOT NULL AND d.statementBalanceDate IS NOT NULL " +
            "ORDER BY d.statementBalanceDate DESC, d.createdAt DESC")
    List<ImportDraft> findWithBankBalance(@Param("userId") UUID userId, @Param("status") ImportDraftStatus status);

    void deleteByStatusAndExpiresAtBefore(ImportDraftStatus status, LocalDateTime now);

    List<ImportDraft> findByStatusAndExpiresAtBefore(ImportDraftStatus status, LocalDateTime now);
}
