package fr.kksdev.budget.api.dto.response;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Probable duplicates found in the history of the user (KKS-387). Nothing is changed by
 * reading them: each proposal is validated by its own call.
 *
 * @param importedDuplicates     transactions imported from a statement that the user had already entered by hand
 * @param subscriptionDuplicates several payments of one subscription for the same due period
 */
public record DuplicateProposalsResponse(
        List<ImportedDuplicate> importedDuplicates,
        List<SubscriptionDuplicate> subscriptionDuplicates
) {

    /**
     * A transaction imported from a statement and the transactions entered by hand that stand for the
     * same operation (same account, type and amount, date within the window of the import matching).
     * The user picks the one to keep among {@code candidates}; the proposal is identified by
     * {@code imported.id}, which appears in no other proposal.
     */
    public record ImportedDuplicate(
            CleanupTransactionResponse imported,
            List<CleanupTransactionResponse> candidates
    ) {}

    /**
     * Payments linked to the same subscription within the same due period. At most one of them is
     * imported from a statement. {@code suggestedKeepTransactionId} is the imported one when there is
     * one, the oldest otherwise.
     */
    public record SubscriptionDuplicate(
            UUID subscriptionId,
            String subscriptionName,
            LocalDate periodStart,
            LocalDate periodEnd,
            UUID suggestedKeepTransactionId,
            List<CleanupTransactionResponse> transactions
    ) {}
}
