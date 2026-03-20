package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.ImportProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ImportProfileRepository extends JpaRepository<ImportProfile, UUID> {

    List<ImportProfile> findByUserIdOrderByNameAsc(UUID userId);

    Optional<ImportProfile> findByIdAndUserId(UUID id, UUID userId);
}
