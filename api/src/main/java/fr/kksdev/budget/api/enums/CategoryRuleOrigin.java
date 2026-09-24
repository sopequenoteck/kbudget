package fr.kksdev.budget.api.enums;

/**
 * Origine d'une regle de categorisation (KKS-383). Elle decide aussi de sa
 * facon de reconnaitre un libelle.
 */
public enum CategoryRuleOrigin {
    /** Saisie par l'utilisateur : le libelle nettoye contient le motif. */
    MANUAL,
    /**
     * Creee par une correction pendant la revue : le motif est une cle
     * commercant, reconnue par mots entiers. Une cle courte ne doit pas
     * reconnaitre n'importe quel libelle qui la contient.
     */
    AUTO
}
