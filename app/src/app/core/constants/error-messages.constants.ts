import { PASSWORD_MIN_LENGTH_MESSAGE } from './password.constants';

/**
 * Catalogue des libelles d'erreur, tenu par le client (KKS-324).
 *
 * Le champ `message` d'une reponse d'erreur est un champ de **diagnostic** :
 * il n'est ni traduit, ni stable, ni redige pour un ecran. Le seul contrat
 * public est `error`, un code machine dont les 27 valeurs sont verrouillees
 * par les tests de KKS-357 — un renommage cote serveur casse le build.
 *
 * Une table plate `Record<string, string>`, pas un `enum` ni une union de
 * litteraux : c'est la forme qu'un fichier de traduction consommera
 * directement quand KKS-325 introduira une bibliotheque i18n, et c'est la
 * forme qui absorbe sans casser un code que le serveur ajouterait apres coup.
 *
 * Ce fichier est le point d'extraction unique. Ajouter un libelle ailleurs
 * annule le benefice de la centralisation.
 */
export const ERROR_MESSAGES: Readonly<Record<string, string>> = {
  // 400
  BAD_REQUEST: "La demande n'a pas pu être traitée.",
  VALIDATION_ERROR: 'Veuillez vérifier les informations saisies.',
  MALFORMED_REQUEST: 'Requête invalide.',
  INVALID_IMAGE_FORMAT: 'Seuls les formats JPG et PNG sont acceptés.',
  INVALID_EXPORT_FORMAT: "Format d'export invalide. Formats acceptés : json, csv.",
  PASSWORD_UNCHANGED: "Le nouveau mot de passe doit être différent de l'actuel.",
  CONFIRMATION_REQUIRED: 'Confirmation explicite requise.',
  // 401
  PASSWORD_INCORRECT: 'Mot de passe incorrect.',
  UNAUTHENTICATED: 'Authentification requise.',
  TOKEN_EXPIRED: 'Votre session a expiré. Veuillez vous reconnecter.',
  TOKEN_REVOKED: 'Votre session a été révoquée. Veuillez vous reconnecter.',
  TOKEN_REUSE_DETECTED: 'Session interrompue par sécurité. Veuillez vous reconnecter.',
  TOKEN_INVALID: 'Session invalide. Veuillez vous reconnecter.',
  // 403
  ACCESS_DENIED: 'Accès refusé',
  PASSWORD_RESET_REQUIRED: 'Reset requis',
  FEATURE_DISABLED: 'Fonctionnalité désactivée',
  PASSWORD_RESET_NOT_REQUIRED:
    "La réinitialisation des identifiants n'est pas requise pour ce compte.",
  LAST_ADMIN_DELETION_FORBIDDEN: 'Au moins un administrateur actif doit exister.',
  // 404
  NOT_FOUND: 'Ressource introuvable',
  AVATAR_NOT_FOUND: 'Avatar introuvable',
  // 409
  CONFLICT: 'Conflit de données',
  LAST_ADMIN_CANNOT_BE_DISABLED: 'Impossible de désactiver le dernier administrateur actif.',
  EMAIL_ALREADY_EXISTS: 'Email déjà utilisé',
  // 413
  FILE_TOO_LARGE: 'Fichier trop volumineux. La taille maximale est 2 MB.',
  // 422
  CSV_PROFILE_NOT_FOUND: 'Profil CSV introuvable',
  // 429
  TOO_MANY_REQUESTS: 'Trop de tentatives. Réessayez dans quelques instants.',
  // 500
  INTERNAL_ERROR: 'Une erreur interne est survenue',
};

/** Libelle servi quand aucun code exploitable n'est disponible. */
export const GENERIC_ERROR_MESSAGE = 'Une erreur est survenue';

/**
 * Libelle du statut 0 — requete jamais partie, ou reponse jamais revenue.
 * Distinct du libelle generique : l'utilisateur peut agir dessus (reseau).
 */
export const NETWORK_ERROR_MESSAGE = 'Impossible de contacter le serveur';

/** Libelle de repli d'une `VALIDATION_ERROR` dont aucun detail n'est reconnu. */
export const VALIDATION_ERROR_MESSAGE = ERROR_MESSAGES['VALIDATION_ERROR'];

/**
 * Affinage d'une `VALIDATION_ERROR` a partir de `details`, par couple
 * `field:code`.
 *
 * `VALIDATION_ERROR` est un code unique couvrant toutes les contraintes de
 * tous les champs : le traduire seul degraderait l'existant, `auth.ts` sachant
 * deja formuler la contrainte de longueur du mot de passe (KKS-351).
 *
 * La table demarre avec la seule entree que les ecrans produisent reellement.
 * En inventer d'autres serait de la sur-ingenierie : `details[].code` derive du
 * nom de l'annotation Bean Validation, une entree ecrite d'avance se
 * desynchroniserait sans qu'aucun test ne rougisse.
 */
export const VALIDATION_DETAIL_MESSAGES: Readonly<Record<string, string>> = {
  'password:SIZE': PASSWORD_MIN_LENGTH_MESSAGE,
};

/**
 * Libelles propres a l'ecran de connexion.
 *
 * `POST /auth/login` refuse des identifiants par un `IllegalArgumentException`,
 * donc par un `BAD_REQUEST` — le meme code que 35 autres sites de `throw`. Le
 * catalogue lui donne a juste titre un libelle general ; sur ce seul endpoint,
 * il n'a qu'un sens possible. Sans cette table, le chemin d'erreur le plus
 * frequent de l'application afficherait « La demande n'a pas pu être traitée. »
 *
 * Introduire un code serveur dedie serait la vraie correction : elle sort du
 * perimetre de KKS-324, qui n'ajoute, ne retire ni ne renomme aucun code.
 */
export const LOGIN_ERROR_OVERRIDES: Readonly<Record<string, string>> = {
  BAD_REQUEST: 'Email ou mot de passe incorrect',
};
