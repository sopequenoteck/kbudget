package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

/**
 * Validation of one proposal of subscription duplicate (KKS-387): the payments of
 * {@code removedTransactionIds} are deleted, the kept one stays.
 */
public record SubscriptionDuplicateMergeRequest(
        @NotNull UUID keptTransactionId,
        @NotEmpty @Size(max = 50) List<@NotNull UUID> removedTransactionIds
) {}
