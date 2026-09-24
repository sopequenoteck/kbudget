package fr.kksdev.budget.api.dto.response;

import java.util.UUID;

public record ImportConfirmResponse(
        int importedCount,
        int skippedCount,
        UUID historyId,
        /** Sous-ensemble de skippedCount : lignes ecartees car deja importees (KKS-382). */
        int alreadyImportedCount
) {}
