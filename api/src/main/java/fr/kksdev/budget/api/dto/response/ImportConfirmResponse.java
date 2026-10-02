package fr.kksdev.budget.api.dto.response;

import java.util.UUID;

public record ImportConfirmResponse(
        int importedCount,
        int skippedCount,
        UUID historyId,
        /** Sous-ensemble de skippedCount : lignes ecartees car deja importees (KKS-382). */
        int alreadyImportedCount,
        /** Controle du solde bancaire apres import (KKS-384) ; nul quand le releve n'en donne pas. */
        ImportBalanceCheckResponse balanceCheck,
        /** Lignes rapprochees d'une transaction existante : elles n'ont rien cree et sont comptees hors importedCount (KKS-385). */
        int matchedCount
) {}
