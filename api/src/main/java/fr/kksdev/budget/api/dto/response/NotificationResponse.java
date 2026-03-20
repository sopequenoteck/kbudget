package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.NotificationType;

import java.time.LocalDateTime;
import java.util.UUID;

public record NotificationResponse(
        UUID id,
        NotificationType type,
        String title,
        String message,
        EntityType entityType,
        UUID entityId,
        boolean read,
        LocalDateTime readAt,
        LocalDateTime createdAt
) {}
