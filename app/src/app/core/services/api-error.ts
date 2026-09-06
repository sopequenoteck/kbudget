import { Injectable, inject } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';

import { DevLogger } from './dev-logger';
import { ApiErrorBody, ValidationErrorDetail } from '../models/api-error.model';
import {
  ERROR_MESSAGES,
  GENERIC_ERROR_MESSAGE,
  NETWORK_ERROR_MESSAGE,
  VALIDATION_DETAIL_MESSAGES,
  VALIDATION_ERROR_MESSAGE,
} from '../constants/error-messages.constants';

/**
 * Point de resolution unique d'un libelle d'erreur (KKS-324).
 *
 * Avant ce service, sept fichiers affichaient `error.error.message` : le texte
 * lu par l'utilisateur etait redige par le serveur, dans une langue et un ton
 * qu'aucun contrat ne garantit. Le champ `message` est desormais un champ de
 * diagnostic — ce service ne le lit a aucun moment, y compris en repli.
 *
 * Le libelle derive du code porte par `error`, seule partie contractuelle du
 * corps d'erreur.
 */
@Injectable({ providedIn: 'root' })
export class ApiErrorService {
  private readonly logger = inject(DevLogger);

  /**
   * Traduit une erreur HTTP en libelle affichable. Ne leve jamais.
   *
   * @param error l'erreur telle que recue — `HttpErrorResponse` ou n'importe quoi d'autre.
   * @param fallback libelle contextuel du site appelant (« Erreur lors du
   *   virement », « Erreur lors de la suppression »…). Sans lui, les sept sites
   *   convergeraient vers un « Une erreur est survenue » indifferencie, ce qui
   *   serait une regression d'UX presentee comme une amelioration.
   * @param overrides libelles propres au site appelant, consultes **avant** le
   *   catalogue. Un seul usage aujourd'hui : `BAD_REQUEST` couvre 35 sites de
   *   `throw` heterogenes cote serveur et recoit donc un libelle general, mais
   *   sur `/auth/login` il ne signifie qu'une chose — identifiants refuses.
   *   Sans cette porte, le chemin d'erreur le plus frequent de l'application
   *   perdrait sa precision au profit d'une formule vague.
   */
  label(
    error: unknown,
    fallback: string = GENERIC_ERROR_MESSAGE,
    overrides: Readonly<Record<string, string>> = {},
  ): string {
    // Teste avant toute lecture de corps : sur un statut 0 il n'y en a pas.
    if (error instanceof HttpErrorResponse && error.status === 0) {
      return NETWORK_ERROR_MESSAGE;
    }

    const code = this.extractCode(error);
    if (!code) {
      return fallback;
    }

    if (code in overrides) {
      return overrides[code];
    }

    if (code === 'VALIDATION_ERROR') {
      return this.refineValidation(this.extractBody(error)?.details);
    }

    if (code in ERROR_MESSAGES) {
      return ERROR_MESSAGES[code];
    }

    // Un client ancien face a un serveur recent est un fonctionnement nominal :
    // la constitution interdit de retirer un champ de reponse, pas d'ajouter un
    // code. D'ou `warn` et non `error`. Le `message` du serveur accompagne le
    // diagnostic — il n'est jamais affiche.
    this.logger.warn('Unknown API error code', code, this.extractBody(error)?.message);
    return fallback;
  }

  /**
   * Extrait le corps d'erreur s'il ressemble a un `ErrorResponse`.
   *
   * Un 502 de reverse proxy renvoie du HTML, une coupure ne renvoie rien, et
   * `HttpErrorResponse.error` peut valoir n'importe quoi : tout ce qui n'est
   * pas un objet simple est rejete ici plutot que de casser plus loin.
   */
  private extractBody(error: unknown): ApiErrorBody | null {
    if (!(error instanceof HttpErrorResponse)) {
      return null;
    }
    const body: unknown = error.error;
    if (typeof body !== 'object' || body === null || Array.isArray(body)) {
      return null;
    }
    return body as ApiErrorBody;
  }

  private extractCode(error: unknown): string | null {
    const code = this.extractBody(error)?.error;
    return typeof code === 'string' && code.length > 0 ? code : null;
  }

  /**
   * Affine une `VALIDATION_ERROR` a partir de `details` (KKS-351, generalise).
   *
   * `details` est **absent** du JSON quand il est vide : le supposer present
   * casserait sur la majorite des erreurs.
   */
  private refineValidation(details: ValidationErrorDetail[] | undefined): string {
    if (!Array.isArray(details)) {
      return VALIDATION_ERROR_MESSAGE;
    }
    for (const detail of details) {
      const key = `${detail?.field}:${detail?.code}`;
      if (key in VALIDATION_DETAIL_MESSAGES) {
        return VALIDATION_DETAIL_MESSAGES[key];
      }
    }
    return VALIDATION_ERROR_MESSAGE;
  }
}
