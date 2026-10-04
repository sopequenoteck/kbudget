package fr.kksdev.budget.api.enums;

/**
 * Raison pour laquelle une ligne de releve n'a pas pu etre lue (KKS-441).
 *
 * <p>Servie comme une simple chaine : l'API ne se traduit pas, les clients
 * affichent le texte de leur catalogue et ne gardent {@code statusMessage}
 * (anglais, technique) qu'en repli pour une valeur qu'ils ne connaissent pas.
 */
public enum ImportReadError {
    /** La date de la ligne ne suit pas le format du profil. */
    INVALID_DATE,
    /** Le montant de la ligne n'est pas un nombre. */
    INVALID_AMOUNT,
    /** Toute autre erreur de lecture : colonne absente, aucun montant debit/credit, etc. */
    UNREADABLE_LINE
}
