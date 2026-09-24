package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.InvitationStatus;
import fr.kksdev.budget.api.model.Invitation;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.InvitationRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InvitationServiceTest {

    @Mock
    private InvitationRepository invitationRepository;

    @InjectMocks
    private InvitationService invitationService;

    private User buildUser(String email) {
        return User.builder()
                .id(UUID.randomUUID())
                .email(email)
                .name("Admin")
                .password("hashed")
                .build();
    }

    @Test
    void should_persist_invitation_with_7d_expiry_when_created() {
        User admin = buildUser("admin@example.com");
        String rawEmail = "  USER@MAIL.COM  ";

        ArgumentCaptor<Invitation> captor = ArgumentCaptor.forClass(Invitation.class);
        when(invitationRepository.save(captor.capture())).thenAnswer(inv -> {
            Invitation i = captor.getValue();
            i = Invitation.builder()
                    .id(1L)
                    .token(i.getToken())
                    .email(i.getEmail())
                    .invitedBy(i.getInvitedBy())
                    .expiresAt(i.getExpiresAt())
                    .build();
            return i;
        });

        Instant before = Instant.now();
        Invitation result = invitationService.create(admin, rawEmail);
        Instant after = Instant.now();

        assertThat(result.getToken()).isNotNull();
        assertThat(result.getEmail()).isEqualTo("user@mail.com");
        assertThat(result.getInvitedBy()).isEqualTo(admin);

        long daysBetween = ChronoUnit.DAYS.between(before, result.getExpiresAt());
        assertThat(daysBetween).isEqualTo(7);

        Instant expectedExpiry = before.plus(7, ChronoUnit.DAYS);
        long diffSeconds = Math.abs(result.getExpiresAt().getEpochSecond() - expectedExpiry.getEpochSecond());
        assertThat(diffSeconds).isLessThan(60);
    }

    @Test
    void should_revoke_invitation_when_id_exists() {
        User admin = buildUser("admin@example.com");
        Invitation invitation = Invitation.builder()
                .id(42L)
                .token(UUID.randomUUID())
                .email("user@example.com")
                .invitedBy(admin)
                .expiresAt(Instant.now().plus(7, ChronoUnit.DAYS))
                .build();

        when(invitationRepository.findById(42L)).thenReturn(Optional.of(invitation));

        invitationService.revoke(42L, admin);

        assertThat(invitation.getRevokedAt()).isNotNull();
    }

    @Test
    void should_throw_entity_not_found_when_revoke_nonexistent_id() {
        User admin = buildUser("admin@example.com");
        when(invitationRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> invitationService.revoke(99L, admin))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessageContaining("Invitation not found");
    }

    @Test
    void should_return_all_invitations_with_derived_status_when_list() {
        User admin = buildUser("admin@example.com");
        Instant now = Instant.now();

        Invitation active = Invitation.builder()
                .id(1L).token(UUID.randomUUID()).email("active@x.com")
                .invitedBy(admin).expiresAt(now.plus(7, ChronoUnit.DAYS))
                .build();

        Invitation expired = Invitation.builder()
                .id(2L).token(UUID.randomUUID()).email("expired@x.com")
                .invitedBy(admin).expiresAt(now.minus(1, ChronoUnit.DAYS))
                .build();

        Invitation used = Invitation.builder()
                .id(3L).token(UUID.randomUUID()).email("used@x.com")
                .invitedBy(admin).expiresAt(now.plus(7, ChronoUnit.DAYS))
                .usedAt(now.minus(1, ChronoUnit.HOURS))
                .build();

        Invitation revoked = Invitation.builder()
                .id(4L).token(UUID.randomUUID()).email("revoked@x.com")
                .invitedBy(admin).expiresAt(now.plus(7, ChronoUnit.DAYS))
                .revokedAt(now.minus(1, ChronoUnit.HOURS))
                .build();

        when(invitationRepository.findAllByOrderByCreatedAtDesc())
                .thenReturn(List.of(revoked, used, expired, active));

        var results = invitationService.list();

        assertThat(results).hasSize(4);
        assertThat(results.get(0).status()).isEqualTo(InvitationStatus.REVOKED);
        assertThat(results.get(1).status()).isEqualTo(InvitationStatus.USED);
        assertThat(results.get(2).status()).isEqualTo(InvitationStatus.EXPIRED);
        assertThat(results.get(3).status()).isEqualTo(InvitationStatus.ACTIVE);
    }

    @Test
    void should_derive_status_revoked_when_revoked_at_set() {
        Invitation inv = Invitation.builder()
                .token(UUID.randomUUID()).email("x@x.com")
                .invitedBy(buildUser("a@a.com"))
                .expiresAt(Instant.now().plus(7, ChronoUnit.DAYS))
                .revokedAt(Instant.now())
                .build();

        assertThat(invitationService.deriveStatus(inv)).isEqualTo(InvitationStatus.REVOKED);
    }

    @Test
    void should_derive_status_used_when_used_at_set() {
        Invitation inv = Invitation.builder()
                .token(UUID.randomUUID()).email("x@x.com")
                .invitedBy(buildUser("a@a.com"))
                .expiresAt(Instant.now().plus(7, ChronoUnit.DAYS))
                .usedAt(Instant.now())
                .build();

        assertThat(invitationService.deriveStatus(inv)).isEqualTo(InvitationStatus.USED);
    }

    @Test
    void should_derive_status_expired_when_expires_at_in_past() {
        Invitation inv = Invitation.builder()
                .token(UUID.randomUUID()).email("x@x.com")
                .invitedBy(buildUser("a@a.com"))
                .expiresAt(Instant.now().minus(1, ChronoUnit.DAYS))
                .build();

        assertThat(invitationService.deriveStatus(inv)).isEqualTo(InvitationStatus.EXPIRED);
    }

    @Test
    void should_derive_status_active_when_not_expired_not_used_not_revoked() {
        Invitation inv = Invitation.builder()
                .token(UUID.randomUUID()).email("x@x.com")
                .invitedBy(buildUser("a@a.com"))
                .expiresAt(Instant.now().plus(7, ChronoUnit.DAYS))
                .build();

        assertThat(invitationService.deriveStatus(inv)).isEqualTo(InvitationStatus.ACTIVE);
    }
}
