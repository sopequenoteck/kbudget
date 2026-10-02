package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Balance check run after an import is confirmed (KKS-384): the balance given
 * by the bank against the one of the application at the same date.
 *
 * @param bankBalance     balance read in the statement header
 * @param balanceDate     date of that balance
 * @param computedBalance balance of the application at {@code balanceDate}, once the import is created
 * @param difference      {@code computedBalance - bankBalance}; zero when both agree
 * @param suspects        transactions of the account within the period of the statement that match
 *                        no line of the statement; empty when there is none
 */
public record ImportBalanceCheckResponse(
        BigDecimal bankBalance,
        LocalDate balanceDate,
        BigDecimal computedBalance,
        BigDecimal difference,
        List<SuspectTransaction> suspects
) {

    /** A transaction of the account that the statement does not know. */
    public record SuspectTransaction(
            UUID id,
            LocalDate date,
            String libelle,
            BigDecimal montant,
            TransactionType type
    ) {}
}
