package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.CleanupSuggestionSource;
import fr.kksdev.budget.api.enums.TransactionType;

import java.math.BigDecimal;
import java.util.List;

/**
 * Transactions with no category, grouped by merchant (KKS-387). Reading them changes nothing.
 *
 * @param groups groups with a proposed category first, then the others, the biggest first
 */
public record CategoryProposalsResponse(List<Group> groups) {

    /**
     * Transactions of one merchant and one type. {@code merchantKey} is empty when the label gives
     * no merchant: such transactions are grouped together without being related.
     *
     * <p>{@code amount} is {@code null} for a whole merchant. It is set when the proposed categories
     * of the merchant differ from one amount to the other (several subscriptions under one label):
     * the merchant is then split by amount, and creating a rule for the merchant would be wrong.
     *
     * @param totalAmount sum of the amounts of the group, unsigned
     * @param suggestion  proposed category, {@code null} when the history gives none
     */
    public record Group(
            String merchantKey,
            TransactionType type,
            BigDecimal amount,
            int count,
            BigDecimal totalAmount,
            Suggestion suggestion,
            List<CleanupTransactionResponse> transactions
    ) {}

    public record Suggestion(CategoryResponse category, CleanupSuggestionSource source) {}
}
