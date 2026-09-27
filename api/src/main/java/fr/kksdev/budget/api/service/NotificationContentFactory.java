package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.util.NotificationParamKey;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

/**
 * Construit le {@code title}/{@code message} anglais et les {@code params}
 * d'une notification, par type (KKS-397).
 *
 * <p>La constitution interdit a l'API de traduire : le texte fixe ici est un
 * defaut anglais pour les clients qui n'exploitent pas encore {@code params}
 * (dont Flutter). Centralise pour n'ecrire chaque gabarit qu'une fois plutot
 * qu'un litteral par appelant ({@link NotificationScheduler}, {@link BudgetService}).
 */
final class NotificationContentFactory {

    private NotificationContentFactory() {}

    static NotificationContent subscriptionDue(String name) {
        return new NotificationContent(
                "Subscription " + name,
                name + " is due tomorrow",
                Map.of(NotificationParamKey.NAME, name));
    }

    static NotificationContent debtDue(String person) {
        return new NotificationContent(
                "Debt with " + person,
                "Debt with " + person + " is due tomorrow",
                Map.of(NotificationParamKey.PERSON, person));
    }

    static NotificationContent debtReminder(String person, String amount, Currency currency) {
        String currencyCode = currency.name();
        return new NotificationContent(
                "Debt reminder - " + person,
                "Reminder: " + amount + " " + currencyCode + " left on the debt with " + person,
                Map.of(
                        NotificationParamKey.PERSON, person,
                        NotificationParamKey.AMOUNT, amount,
                        NotificationParamKey.CURRENCY, currencyCode));
    }

    /**
     * @param categorySystemKey cle stable (KKS-395) si la categorie est systeme, null sinon.
     */
    static NotificationContent budgetThreshold(String category, String categorySystemKey, int percentage) {
        return new NotificationContent(
                "Budget " + category + ": " + percentage + "%",
                "You have reached " + percentage + "% of the " + category + " budget",
                budgetParams(category, categorySystemKey, percentage));
    }

    /**
     * @param categorySystemKey cle stable (KKS-395) si la categorie est systeme, null sinon.
     */
    static NotificationContent budgetExceeded(String category, String categorySystemKey, int percentage) {
        return new NotificationContent(
                "Budget " + category + " exceeded",
                "You have exceeded the " + category + " budget (" + percentage + "%)",
                budgetParams(category, categorySystemKey, percentage));
    }

    private static Map<String, String> budgetParams(String category, String categorySystemKey, int percentage) {
        Map<String, String> params = new HashMap<>();
        params.put(NotificationParamKey.CATEGORY, category);
        if (categorySystemKey != null) {
            params.put(NotificationParamKey.CATEGORY_SYSTEM_KEY, categorySystemKey);
        }
        params.put(NotificationParamKey.PERCENTAGE, String.valueOf(percentage));
        return Map.copyOf(params);
    }

    /**
     * @param currency devise du compte lie, null si la recurrence n'a pas de compte.
     */
    static NotificationContent recurringTransactionDue(String label, String amount, Currency currency, LocalDate dueDate) {
        String dueDateText = dueDate.toString();
        Map<String, String> params = new HashMap<>();
        params.put(NotificationParamKey.LABEL, label);
        params.put(NotificationParamKey.AMOUNT, amount);
        String message;
        if (currency != null) {
            String currencyCode = currency.name();
            params.put(NotificationParamKey.CURRENCY, currencyCode);
            message = label + " " + amount + " " + currencyCode + " due on " + dueDateText;
        } else {
            message = label + " " + amount + " due on " + dueDateText;
        }
        params.put(NotificationParamKey.DUE_DATE, dueDateText);
        return new NotificationContent("Recurring transaction " + label, message, Map.copyOf(params));
    }
}
