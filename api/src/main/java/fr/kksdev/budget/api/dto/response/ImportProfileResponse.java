package fr.kksdev.budget.api.dto.response;

import java.util.UUID;

public record ImportProfileResponse(
        UUID id,
        String bankCode,
        String name,
        String source,
        boolean editable
) {}
