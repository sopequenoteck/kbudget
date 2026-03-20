package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    Optional<Notification> findByIdAndUserId(UUID id, UUID userId);
    Page<Notification> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
    Page<Notification> findByUserIdAndReadOrderByCreatedAtDesc(UUID userId, boolean read, Pageable pageable);
    long countByUserIdAndRead(UUID userId, boolean read);
    boolean existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter(UUID userId, NotificationType type, UUID entityId, LocalDateTime after);

    @Modifying
    @Query("DELETE FROM Notification n WHERE n.user.id = :userId")
    void deleteByUserId(@Param("userId") UUID userId);

    @Modifying
    @Query("DELETE FROM Notification n WHERE n.user.id = :userId AND n.createdAt < :before")
    void deleteByUserIdAndCreatedAtBefore(@Param("userId") UUID userId, @Param("before") LocalDateTime before);

    @Modifying
    @Query("UPDATE Notification n SET n.read = true, n.readAt = :readAt WHERE n.user.id = :userId AND n.read = false")
    int markAllAsReadByUserId(@Param("userId") UUID userId, @Param("readAt") LocalDateTime readAt);
}
