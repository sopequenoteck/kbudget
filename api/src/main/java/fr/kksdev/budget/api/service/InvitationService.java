package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.InvitationResponse;
import fr.kksdev.budget.api.enums.InvitationStatus;
import fr.kksdev.budget.api.model.Invitation;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.InvitationRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class InvitationService {

    private final InvitationRepository invitationRepository;

    @Transactional
    public Invitation create(User invitedBy, String email) {
        String normalizedEmail = email.trim().toLowerCase();

        Invitation invitation = Invitation.builder()
                .token(UUID.randomUUID())
                .email(normalizedEmail)
                .invitedBy(invitedBy)
                .expiresAt(Instant.now().plus(Duration.ofDays(7)))
                .build();

        Invitation saved = invitationRepository.save(invitation);
        log.info("Admin action: invitation.create by {} target=invitation:{}", invitedBy.getEmail(), saved.getId());
        return saved;
    }

    @Transactional
    public void revoke(Long id, User admin) {
        Invitation invitation = invitationRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Invitation introuvable"));
        invitation.setRevokedAt(Instant.now());
        log.info("Admin action: invitation.revoke by {} target=invitation:{}", admin.getEmail(), id);
    }

    @Transactional(readOnly = true)
    public List<InvitationResponse> list() {
        return invitationRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(inv -> new InvitationResponse(
                        inv.getId(),
                        inv.getEmail(),
                        inv.getInvitedBy().getEmail(),
                        deriveStatus(inv),
                        inv.getCreatedAt(),
                        inv.getExpiresAt(),
                        inv.getUsedAt(),
                        inv.getRevokedAt()
                ))
                .toList();
    }

    public InvitationStatus deriveStatus(Invitation inv) {
        if (inv.getRevokedAt() != null) return InvitationStatus.REVOKED;
        if (inv.getUsedAt() != null) return InvitationStatus.USED;
        if (inv.getExpiresAt().isBefore(Instant.now())) return InvitationStatus.EXPIRED;
        return InvitationStatus.ACTIVE;
    }
}
