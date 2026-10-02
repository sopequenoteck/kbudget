package fr.kksdev.budget.api.dto.response;

/**
 * Outcome of the categorization of a group (KKS-387).
 *
 * @param categorizedCount transactions that received the category
 * @param skippedCount     transactions of the request left untouched because they already had a category
 */
public record CategoryApplyResponse(int categorizedCount, int skippedCount) {}
