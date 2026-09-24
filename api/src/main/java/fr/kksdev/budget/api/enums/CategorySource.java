package fr.kksdev.budget.api.enums;

/**
 * Origine de la categorie d'une ligne d'import (KKS-383). Servie comme une
 * simple chaine : un client ancien l'ignore.
 */
public enum CategorySource {
    /** Une regle de categorisation de l'utilisateur. */
    RULE,
    /** La categorie majoritaire des transactions passees du meme commercant. */
    HISTORY,
    /** Choisie par l'utilisateur pendant la revue, directement ou par propagation. */
    USER
}
