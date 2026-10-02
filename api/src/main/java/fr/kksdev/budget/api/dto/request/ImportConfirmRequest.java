package fr.kksdev.budget.api.dto.request;

/**
 * Optional body of {@code POST /imports/drafts/{id}/confirm} (KKS-384). A
 * confirmation without a body behaves as before.
 *
 * @param applyOpeningBalance when {@code true} and this is the first import of the account,
 *                            the opening balance of the account is set so that its balance
 *                            matches the one given by the bank, apart from the transactions the
 *                            statement does not account for; {@code null} means {@code false}
 */
public record ImportConfirmRequest(Boolean applyOpeningBalance) {

    public boolean applyOpeningBalanceRequested() {
        return Boolean.TRUE.equals(applyOpeningBalance);
    }
}
