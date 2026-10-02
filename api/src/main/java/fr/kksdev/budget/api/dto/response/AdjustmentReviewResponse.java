package fr.kksdev.budget.api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Balance adjustments of the user, by account (KKS-387). Read only: an adjustment is never
 * deleted by the cleanup.
 */
public record AdjustmentReviewResponse(List<AccountAdjustments> accounts) {

    /**
     * Adjustments of one account. {@code bankBalance}, {@code bankBalanceDate} and
     * {@code computedBalance} are {@code null} when no statement of the account gave a bank balance.
     *
     * @param bankBalance     latest bank balance known for the account (KKS-384)
     * @param computedBalance balance of the application at {@code bankBalanceDate}, adjustments included
     */
    public record AccountAdjustments(
            AccountSummary account,
            BigDecimal bankBalance,
            LocalDate bankBalanceDate,
            BigDecimal computedBalance,
            List<Adjustment> adjustments
    ) {}

    /**
     * @param probablyUnnecessary the adjustment is dated up to the bank balance date and, without it, the
     *                            balance of the application at that date would equal the bank balance to the cent
     */
    public record Adjustment(
            UUID id,
            LocalDate date,
            String libelle,
            BigDecimal montant,
            boolean probablyUnnecessary
    ) {}
}
