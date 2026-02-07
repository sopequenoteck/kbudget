package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {

    List<Subscription> findByUserIdOrderByNomAsc(UUID userId);

    List<Subscription> findByUserIdAndActifTrueOrderByNomAsc(UUID userId);
}
