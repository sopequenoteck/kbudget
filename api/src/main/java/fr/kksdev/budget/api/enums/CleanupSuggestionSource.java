package fr.kksdev.budget.api.enums;

/**
 * What a category proposed by the history cleanup rests on (KKS-387), from the most to the least
 * reliable. Served as a plain string: an older client ignores a value it does not know.
 */
public enum CleanupSuggestionSource {
    /** A categorization rule of the user. */
    RULE,
    /** The majority category of the user's past transactions with the same merchant at the same amount. */
    HISTORY_AMOUNT,
    /** The majority category of the user's past transactions with the same merchant, whatever the amount. */
    HISTORY_MERCHANT
}
