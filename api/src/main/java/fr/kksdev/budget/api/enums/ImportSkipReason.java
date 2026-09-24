package fr.kksdev.budget.api.enums;

/**
 * Raison pour laquelle l'import a lui-meme passe une ligne en SKIPPED (KKS-382).
 *
 * <p>Une ligne ignoree par l'utilisateur n'en porte aucune. Servie comme une
 * simple chaine : un client ancien qui ignore le champ voit une ligne ignoree
 * ordinaire, sans valeur d'enum inconnue a absorber.
 */
public enum ImportSkipReason {
    /** La ligne vient d'un releve deja importe et existe deja en transaction. */
    ALREADY_IMPORTED
}
