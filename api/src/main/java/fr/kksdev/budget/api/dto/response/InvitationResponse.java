package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.InvitationStatus;

import java.time.Instant;

public record InvitationResponse(
        Long id,
        String email,
        String invitedByEmail,
        InvitationStatus status,
        Instant createdAt,
        Instant expiresAt,
        Instant usedAt,
        Instant revokedAt
) {}
