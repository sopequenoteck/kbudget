package fr.kksdev.budget.api.exception;

import java.util.Arrays;

/**
 * Stable error codes of the history cleanup conflicts (KKS-387), served as {@code error} with a 409.
 * The code travels as the message of a {@link ConflictException}; the handler turns it into the
 * {@code error} field and the description below into the diagnostic {@code message}.
 */
public enum CleanupConflictCode {

    /** The proposal no longer holds: a transaction changed, was imported or deleted since it was shown. */
    CLEANUP_PROPOSAL_STALE("The transactions no longer satisfy the conditions of this proposal"),

    /** A transaction to delete repays a debt that the transaction kept does not repay. */
    CLEANUP_DEBT_LINK_MISSING("The transaction to delete repays a debt that the transaction kept does not repay");

    private final String description;

    CleanupConflictCode(String description) {
        this.description = description;
    }

    public String description() {
        return description;
    }

    public ConflictException toException() {
        return new ConflictException(name());
    }

    /** The code named by {@code value}, {@code null} when {@code value} is not one of them. */
    public static CleanupConflictCode of(String value) {
        return Arrays.stream(values()).filter(code -> code.name().equals(value)).findFirst().orElse(null);
    }
}
