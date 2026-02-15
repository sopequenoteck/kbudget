package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AccountRepository extends JpaRepository<Account, UUID> {

    List<Account> findByUserIdAndActifTrue(UUID userId);

    List<Account> findByUserId(UUID userId);

    Optional<Account> findByIdAndUserId(UUID id, UUID userId);

    Optional<Account> findByUserIdAndIsDefaultTrue(UUID userId);

    boolean existsByNomIgnoreCaseAndUserIdAndActifTrue(String nom, UUID userId);

    boolean existsByNomIgnoreCaseAndUserIdAndActifTrueAndIdNot(String nom, UUID userId, UUID id);

    long countByUserIdAndActifTrue(UUID userId);
}
