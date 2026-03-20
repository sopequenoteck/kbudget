package fr.kksdev.budget.api.dto.response;

import java.util.UUID;

public record ImportConfirmResponse(
        int importedCount,
        int skippedCount,
        UUID historyId
) {}
