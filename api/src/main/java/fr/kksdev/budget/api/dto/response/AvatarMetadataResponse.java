package fr.kksdev.budget.api.dto.response;

import java.time.Instant;

public record AvatarMetadataResponse(
        String url,
        String etag,
        Instant uploadedAt
) {}
