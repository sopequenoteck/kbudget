package fr.kksdev.budget.api.util;

/**
 * Resout un texte optionnel fourni par le client (KKS-396).
 *
 * <p>La constitution (principe VII) interdit a l'API de traduire : elle
 * n'ecrit jamais de texte francais dans les donnees de l'utilisateur. Le
 * client fournit le texte dans sa langue via un champ de requete optionnel ;
 * sans texte exploitable (null, vide, blanc), l'appelant retombe sur un
 * defaut anglais qu'il fournit lui-meme.
 *
 * <p>Factorise ici pour n'ecrire ce choix (null/vide/blanc -> defaut, sinon
 * texte fourni {@code strip()}) qu'une seule fois : un ternaire par appelant
 * ajouterait une branche par site d'appel a la couverture du nouveau code.
 */
public final class ClientText {

    private ClientText() {}

    public static String orDefault(String provided, String defaultValue) {
        if (provided == null) {
            return defaultValue;
        }
        String stripped = provided.strip();
        return stripped.isEmpty() ? defaultValue : stripped;
    }
}
