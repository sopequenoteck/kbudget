import { ERROR_CODES, errorCodeToKey } from './error-messages.constants';
import fr from '../../../../public/i18n/fr.json';
import en from '../../../../public/i18n/en.json';

/**
 * Garde-fou de completude des catalogues (FR-037), en remplacement du
 * garde-fou de comptage que tenait `api-error.spec.ts` avant KKS-373
 * (`Object.keys(ERROR_MESSAGES).toHaveLength(27)`).
 *
 * Les libelles francais ci-dessous sont ceux de KKS-324, transcrits ici une
 * fois pour prouver — caractere pour caractere — que le deplacement vers
 * `fr.json` n'en a perdu aucun (SC-003). Ce fichier est le seul endroit du
 * depot ou ce texte de reference est retype ; `error-messages.constants.ts`
 * et `ApiErrorService` ne connaissent plus que des cles.
 */
const EXPECTED_FRENCH_LABELS: Readonly<Record<string, string>> = {
  BAD_REQUEST: "La demande n'a pas pu être traitée.",
  VALIDATION_ERROR: 'Veuillez vérifier les informations saisies.',
  MALFORMED_REQUEST: 'Requête invalide.',
  INVALID_IMAGE_FORMAT: 'Seuls les formats JPG et PNG sont acceptés.',
  INVALID_EXPORT_FORMAT: "Format d'export invalide. Formats acceptés : json, csv.",
  PASSWORD_UNCHANGED: "Le nouveau mot de passe doit être différent de l'actuel.",
  CONFIRMATION_REQUIRED: 'Confirmation explicite requise.',
  PASSWORD_INCORRECT: 'Mot de passe incorrect.',
  UNAUTHENTICATED: 'Authentification requise.',
  TOKEN_EXPIRED: 'Votre session a expiré. Veuillez vous reconnecter.',
  TOKEN_REVOKED: 'Votre session a été révoquée. Veuillez vous reconnecter.',
  TOKEN_REUSE_DETECTED: 'Session interrompue par sécurité. Veuillez vous reconnecter.',
  TOKEN_INVALID: 'Session invalide. Veuillez vous reconnecter.',
  ACCESS_DENIED: 'Accès refusé',
  PASSWORD_RESET_REQUIRED: 'Reset requis',
  FEATURE_DISABLED: 'Fonctionnalité désactivée',
  PASSWORD_RESET_NOT_REQUIRED:
    "La réinitialisation des identifiants n'est pas requise pour ce compte.",
  LAST_ADMIN_DELETION_FORBIDDEN: 'Au moins un administrateur actif doit exister.',
  NOT_FOUND: 'Ressource introuvable',
  AVATAR_NOT_FOUND: 'Avatar introuvable',
  CONFLICT: 'Conflit de données',
  LAST_ADMIN_CANNOT_BE_DISABLED: 'Impossible de désactiver le dernier administrateur actif.',
  EMAIL_ALREADY_EXISTS: 'Email déjà utilisé',
  FILE_TOO_LARGE: 'Fichier trop volumineux. La taille maximale est 2 MB.',
  CSV_PROFILE_NOT_FOUND: 'Profil CSV introuvable',
  TOO_MANY_REQUESTS: 'Trop de tentatives. Réessayez dans quelques instants.',
  INTERNAL_ERROR: 'Une erreur interne est survenue',
};

function getValue(catalogue: unknown, key: string): unknown {
  return key.split('.').reduce<unknown>((node, segment) => {
    if (typeof node !== 'object' || node === null) {
      return undefined;
    }
    return (node as Record<string, unknown>)[segment];
  }, catalogue);
}

describe('catalogue errors.api', () => {
  it('should_cover_the_27_codes_emitted_by_the_api', () => {
    // Le nombre de codes est verrouille par KKS-357 ; ce test tient le role
    // que jouait l'ancien garde-fou de comptage sur `ERROR_MESSAGES`.
    expect(ERROR_CODES).toHaveLength(27);
  });

  it.each(ERROR_CODES)('should_have_a_french_and_english_key_when_code_is_%s', (code) => {
    // Act
    const key = errorCodeToKey(code);

    // Assert — SC-003 : une cle existe dans les deux catalogues.
    expect(getValue(fr, key)).toBeDefined();
    expect(getValue(en, key)).toBeDefined();
  });

  it.each(Object.entries(EXPECTED_FRENCH_LABELS))(
    'should_keep_the_kks_324_french_label_unchanged_when_code_is_%s',
    (code, expected) => {
      // Act
      const key = errorCodeToKey(code);

      // Assert — caractere pour caractere (SC-003).
      expect(getValue(fr, key)).toBe(expected);
    },
  );

  it('should_expose_exactly_the_same_french_labels_as_kks_324', () => {
    // Assert — aucun code oublie, aucun code invente.
    expect(Object.keys(EXPECTED_FRENCH_LABELS).sort()).toEqual([...ERROR_CODES].sort());
  });
});
