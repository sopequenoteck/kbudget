package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.InvitationStatus;

import java.time.Instant;
import java.util.UUID;

public record InvitationResponse(
        Long id,
        String email,
        String invitedByEmail,
        InvitationStatus status,
        UUID token,
        Instant createdAt,
        Instant expiresAt,
        Instant usedAt,
        Instant revokedAt
) {}
