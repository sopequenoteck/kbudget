package fr.kksdev.budget.api.dto.response;

import java.time.Instant;
import java.util.UUID;

public record InvitationCreatedResponse(
        UUID token,
        Instant expiresAt
) {}
