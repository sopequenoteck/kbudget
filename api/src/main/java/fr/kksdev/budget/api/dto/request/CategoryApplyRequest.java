package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

/**
 * Category chosen by the user for a group of uncategorized transactions (KKS-387).
 *
 * @param createRule whether to remember the choice as an automatic rule for the merchant; defaults to
 *                   {@code true}. The client sends {@code false} for a group split by amount.
 */
public record CategoryApplyRequest(
        @NotNull UUID categoryId,
        @NotEmpty @Size(max = 500) List<@NotNull UUID> transactionIds,
        Boolean createRule
) {

    public boolean rememberRule() {
        return createRule == null || createRule;
    }
}
