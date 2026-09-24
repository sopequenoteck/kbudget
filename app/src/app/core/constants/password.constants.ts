/**
 * Politique de mot de passe, alignee sur `PasswordPolicy` cote API (KKS-351).
 *
 * Une valeur ecrite en dur dans un validateur se desynchronise du serveur sans
 * qu'aucun test ne devienne rouge : c'est ce qui avait laisse l'ecran de
 * premiere connexion annoncer 8 caracteres face a un serveur qui en exigeait 12.
 *
 * Le formulaire de connexion n'utilise pas ces constantes : il verifie un mot
 * de passe existant, lui imposer une longueur minimale bloquerait un compte
 * cree avant un durcissement.
 */
export const PASSWORD_MIN_LENGTH = 12;
export const PASSWORD_MAX_LENGTH = 100;
/**
 * Texte d'indication sous le champ mot de passe (formulaires de premiere
 * connexion, d'acceptation d'invitation et de changement de mot de passe).
 * Distinct de la cle de catalogue `auth.form.passwordMinLength` (KKS-373),
 * qui porte le meme texte pour l'affinage d'une `VALIDATION_ERROR` : cette
 * constante reste hors du perimetre de KKS-373 (FR-032, FR-040), elle
 * partira avec le domaine `auth` a une etape ulterieure de KKS-325.
 */
export const PASSWORD_MIN_LENGTH_MESSAGE = `${PASSWORD_MIN_LENGTH} caractères minimum`;
export const PASSWORD_PLACEHOLDER = `Au moins ${PASSWORD_MIN_LENGTH} caractères`;
export const PASSWORD_MAX_LENGTH_MESSAGE = `${PASSWORD_MAX_LENGTH} caractères maximum`;
