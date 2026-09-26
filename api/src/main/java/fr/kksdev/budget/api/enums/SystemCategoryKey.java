package fr.kksdev.budget.api.enums;

/**
 * Cle stable d'une categorie systeme (KKS-395), independante du nom affiche.
 * L'API ne traduit jamais : le nom stocke reste francais, la cle permet au
 * client de retrouver et de traduire la categorie sans dependre du texte.
 */
public enum SystemCategoryKey {
    /** Categorie des abonnements crees automatiquement. */
    SUBSCRIPTION,
    /** Categorie des dettes creees automatiquement. */
    DEBT,
    /** Categorie des virements entre comptes. */
    TRANSFER,
    /** Categorie des ajustements de solde. */
    ADJUSTMENT
}
