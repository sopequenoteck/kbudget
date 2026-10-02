package fr.kksdev.budget.api.dto.response;

import java.util.List;
import java.util.UUID;

/**
 * Outcome of a validated duplicate proposal (KKS-387).
 *
 * @param kept       the transaction that stays, as it is after the merge
 * @param removedIds transactions deleted
 */
public record DuplicateMergeResponse(CleanupTransactionResponse kept, List<UUID> removedIds) {}
