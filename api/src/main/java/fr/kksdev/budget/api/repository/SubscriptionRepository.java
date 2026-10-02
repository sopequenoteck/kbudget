package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Subscription;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {

    /**
     * Reads a subscription of the given user and locks its row until the end of the
     * transaction. Filtering by user in the query itself means the row of another
     * user's subscription is never locked.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM Subscription s WHERE s.id = :id AND s.user.id = :userId")
    Optional<Subscription> findByIdAndUserIdForUpdate(@Param("id") UUID id, @Param("userId") UUID userId);

    List<Subscription> findByUserIdOrderByNomAsc(UUID userId);

    List<Subscription> findByUserIdAndActifTrueOrderByNomAsc(UUID userId);

    boolean existsByAccountId(UUID accountId);
}
