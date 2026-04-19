package fr.kksdev.budget.api.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminUserResponse(
        UUID id,
        String email,
        String displayName,
        LocalDateTime createdAt,
        LocalDateTime disabledAt,
        boolean isAdmin
) {}
