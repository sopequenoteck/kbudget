package fr.kksdev.budget.api.util;

/**
 * Cles du champ {@code params} d'une notification (KKS-397).
 *
 * <p>La constitution interdit a l'API de traduire : {@code title}/{@code message}
 * restent en anglais, {@code params} porte les valeurs brutes (montants, codes
 * devise ISO, dates ISO) que le client compose dans sa langue. Centralise ici
 * pour n'ecrire chaque cle qu'une fois (Sonar S1192) plutot qu'un litteral par
 * site d'appel dans {@link fr.kksdev.budget.api.service.NotificationContentFactory}.
 */
public final class NotificationParamKey {

    private NotificationParamKey() {}

    public static final String NAME = "name";
    public static final String PERSON = "person";
    public static final String AMOUNT = "amount";
    public static final String CURRENCY = "currency";
    public static final String CATEGORY = "category";
    public static final String CATEGORY_SYSTEM_KEY = "categorySystemKey";
    public static final String PERCENTAGE = "percentage";
    public static final String LABEL = "label";
    public static final String DUE_DATE = "dueDate";
}
