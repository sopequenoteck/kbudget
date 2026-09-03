package fr.kksdev.budget.api.config;

/**
 * Politique de mot de passe, unique pour tous les parcours (KKS-351).
 *
 * <p>Avant ce ticket, {@code AcceptInviteRequest} exigeait 8 caracteres et
 * {@code FirstLoginResetRequest} 12, pour le meme geste : choisir son mot de
 * passe. Les clients validaient l'une ou l'autre valeur selon l'ecran, et un
 * ecran annoncait 8 face a un serveur qui en exigeait 12.
 *
 * <p>Les constantes sont utilisees directement dans les annotations
 * {@code @Size} : une valeur litterale s'y desynchronise sans qu'aucun test ne
 * devienne rouge.
 *
 * <p><b>Le login n'impose aucune longueur minimale</b> : il verifie un mot de
 * passe existant. Un compte cree avant un durcissement resterait accessible.
 */
public final class PasswordPolicy {

    private PasswordPolicy() {}

    /** Longueur minimale a la creation ou au changement de mot de passe. */
    public static final int MIN_LENGTH = 12;

    /** Longueur maximale acceptee, alignee sur la capacite de BCrypt. */
    public static final int MAX_LENGTH = 100;
}
