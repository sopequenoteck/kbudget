import { PASSWORD_MIN_LENGTH } from './password.constants';

/**
 * Codes d'erreur que l'API peut emettre (KKS-324), verrouilles par les tests
 * de KKS-357. Chacun a une cle dans les deux catalogues Transloco sous
 * `errors.api.`, obtenue par {@link errorCodeToKey} (KKS-373).
 *
 * Les libelles eux-memes ne vivent plus ici : ils ont ete deplaces a
 * l'identique dans `app/public/i18n/fr.json` et traduits dans `en.json`.
 * Ce fichier ne tient plus que la liste des codes et le mecanisme de
 * derivation de cle, seul point encore partage par `ApiErrorService` et par
 * les tests qui garantissent la completude des catalogues.
 */
export const ERROR_CODES: readonly string[] = [
  // 400
  'BAD_REQUEST',
  'VALIDATION_ERROR',
  'MALFORMED_REQUEST',
  'INVALID_IMAGE_FORMAT',
  'INVALID_EXPORT_FORMAT',
  'PASSWORD_UNCHANGED',
  'CONFIRMATION_REQUIRED',
  // 401
  'PASSWORD_INCORRECT',
  'UNAUTHENTICATED',
  'TOKEN_EXPIRED',
  'TOKEN_REVOKED',
  'TOKEN_REUSE_DETECTED',
  'TOKEN_INVALID',
  // 403
  'ACCESS_DENIED',
  'PASSWORD_RESET_REQUIRED',
  'FEATURE_DISABLED',
  'PASSWORD_RESET_NOT_REQUIRED',
  'LAST_ADMIN_DELETION_FORBIDDEN',
  // 404
  'NOT_FOUND',
  'AVATAR_NOT_FOUND',
  // 409
  'CONFLICT',
  'LAST_ADMIN_CANNOT_BE_DISABLED',
  'EMAIL_ALREADY_EXISTS',
  // 413
  'FILE_TOO_LARGE',
  // 422
  'CSV_PROFILE_NOT_FOUND',
  // 429
  'TOO_MANY_REQUESTS',
  // 500
  'INTERNAL_ERROR',
] as const;

/**
 * Convertit mecaniquement un code d'erreur SCREAMING_SNAKE_CASE en cle
 * `errors.api.<lowerCamelCase>`, sans rien retrancher (`docs/i18n.md`) :
 * `INTERNAL_ERROR` -> `errors.api.internalError`.
 */
export function errorCodeToKey(code: string): string {
  const element = code
    .toLowerCase()
    .replace(/_([a-z0-9])/g, (_match, char: string) => char.toUpperCase());
  return `errors.api.${element}`;
}

/**
 * Libelles propres a l'ecran de connexion, sous forme de **cle** de
 * traduction (KKS-373) — plus une chaine litterale.
 *
 * `POST /auth/login` refuse des identifiants par un `IllegalArgumentException`,
 * donc par un `BAD_REQUEST` — le meme code que 35 autres sites de `throw`. Le
 * catalogue lui donne a juste titre un libelle general ; sur ce seul endpoint,
 * il n'a qu'un sens possible. Sans cette table, le chemin d'erreur le plus
 * frequent de l'application afficherait le libelle general de `BAD_REQUEST`.
 *
 * Introduire un code serveur dedie serait la vraie correction : elle sort du
 * perimetre de KKS-324, qui n'ajoute, ne retire ni ne renomme aucun code.
 */
export const LOGIN_ERROR_OVERRIDES: Readonly<Record<string, string>> = {
  BAD_REQUEST: 'auth.feedback.invalidCredentials',
};

/** Cle et parametres ICU d'un affinage de `VALIDATION_ERROR` par `field:code`. */
interface ValidationDetailTranslation {
  readonly key: string;
  readonly params?: Readonly<Record<string, unknown>>;
}

/**
 * Affinage d'une `VALIDATION_ERROR` a partir de `details`, par couple
 * `field:code` (KKS-351, generalise par KKS-324, deplace en cle par KKS-373).
 *
 * `VALIDATION_ERROR` est un code unique couvrant toutes les contraintes de
 * tous les champs : le traduire seul degraderait l'existant, l'ecran de
 * connexion sachant deja formuler la contrainte de longueur du mot de passe.
 *
 * La table demarre avec la seule entree que les ecrans produisent reellement.
 * En inventer d'autres serait de la sur-ingenierie : `details[].code` derive du
 * nom de l'annotation Bean Validation, une entree ecrite d'avance se
 * desynchroniserait sans qu'aucun test ne rougisse.
 */
export const VALIDATION_DETAIL_TRANSLATIONS: Readonly<Record<string, ValidationDetailTranslation>> =
  {
    'password:SIZE': { key: 'auth.form.passwordMinLength', params: { min: PASSWORD_MIN_LENGTH } },
  };
