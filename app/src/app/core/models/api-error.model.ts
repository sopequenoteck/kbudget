/**
 * Corps d'erreur servi par l'API (`ErrorResponse` cote serveur).
 *
 * Tous les champs sont optionnels a dessein : un 502 de reverse proxy, une
 * coupure reseau ou une reponse tronquee ne portent aucun de ces champs, et le
 * type doit decrire ce qui peut arriver, pas ce qu'on espere recevoir.
 *
 * `details` est **absent** du JSON — et non pas nul ou vide — pour toutes les
 * erreurs autres que `VALIDATION_ERROR` : `ErrorResponse` porte
 * `@JsonInclude(NON_EMPTY)` cote serveur.
 *
 * `message` est un champ de **diagnostic** (KKS-324). Il n'est jamais utilise
 * pour construire un texte presente a l'utilisateur : le libelle derive du code
 * porte par `error`, via `ApiErrorService`.
 */
export interface ApiErrorBody {
  error?: string;
  message?: string;
  details?: ValidationErrorDetail[];
}

/**
 * Entree du tableau `details` d'une `VALIDATION_ERROR`.
 *
 * `code` derive du nom de l'annotation Bean Validation ayant echoue
 * (`@Size` -> `SIZE`), avec `INVALID_VALUE` en repli. Il n'est ecrit nulle part
 * cote serveur : le lien est verrouille par `ValidationErrorCodeContractTest`.
 */
export interface ValidationErrorDetail {
  field: string;
  code: string;
  message: string;
}
