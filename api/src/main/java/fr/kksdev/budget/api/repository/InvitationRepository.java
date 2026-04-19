package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.Invitation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InvitationRepository extends JpaRepository<Invitation, Long> {
    Optional<Invitation> findByToken(UUID token);
    List<Invitation> findAllByOrderByCreatedAtDesc();
}
