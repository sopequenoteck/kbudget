package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Validation of one proposal of imported duplicate (KKS-387): the imported transaction is deleted,
 * the one entered by hand is kept and receives its import fingerprint.
 */
public record DuplicateMergeRequest(
        @NotNull UUID importedTransactionId,
        @NotNull UUID keptTransactionId
) {}
