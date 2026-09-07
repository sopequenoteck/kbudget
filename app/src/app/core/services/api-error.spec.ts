import { TestBed } from '@angular/core/testing';
import { HttpErrorResponse } from '@angular/common/http';

import { ApiErrorService } from './api-error';
import { DevLogger } from './dev-logger';
import {
  ERROR_MESSAGES,
  GENERIC_ERROR_MESSAGE,
  LOGIN_ERROR_OVERRIDES,
  NETWORK_ERROR_MESSAGE,
  VALIDATION_ERROR_MESSAGE,
} from '../constants/error-messages.constants';
import { PASSWORD_MIN_LENGTH_MESSAGE } from '../constants/password.constants';

function httpError(status: number, body: unknown): HttpErrorResponse {
  return new HttpErrorResponse({ status, error: body });
}

describe('ApiErrorService', () => {
  let service: ApiErrorService;
  let logger: { warn: ReturnType<typeof vi.fn>; error: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    logger = { warn: vi.fn(), error: vi.fn() };
    TestBed.configureTestingModule({
      providers: [ApiErrorService, { provide: DevLogger, useValue: logger }],
    });
    service = TestBed.inject(ApiErrorService);
  });

  describe('catalogue', () => {
    it('should_cover_the_27_codes_emitted_by_the_api', () => {
      // Le catalogue est tenu a la main : ce test est le seul garde-fou contre
      // un libelle manquant. Les 27 codes sont verrouilles par KKS-357.
      expect(Object.keys(ERROR_MESSAGES)).toHaveLength(27);
    });

    it.each(Object.entries(ERROR_MESSAGES))(
      'should_return_the_catalogue_label_when_code_is_%s',
      (code, expected) => {
        // Arrange
        const error = httpError(400, { error: code, message: 'texte serveur arbitraire' });

        // Act
        const label = service.label(error);

        // Assert — `VALIDATION_ERROR` passe par l'affinage, qui retombe sur le
        // meme libelle en l'absence de `details`.
        expect(label).toBe(expected);
        expect(label).not.toContain('texte serveur arbitraire');
      },
    );

    it('should_never_expose_the_server_message_when_code_is_known', () => {
      // Arrange
      const error = httpError(404, { error: 'NOT_FOUND', message: 'Transaction non trouvee' });

      // Act & Assert
      expect(service.label(error)).toBe(ERROR_MESSAGES['NOT_FOUND']);
    });
  });

  describe('code inconnu', () => {
    it('should_return_fallback_and_warn_when_code_is_absent_from_catalogue', () => {
      // Arrange
      const error = httpError(418, { error: 'BREWING_COFFEE', message: 'serveur recent' });

      // Act
      const label = service.label(error, 'Repli contextuel');

      // Assert
      expect(label).toBe('Repli contextuel');
      expect(logger.warn).toHaveBeenCalledWith(
        'Unknown API error code',
        'BREWING_COFFEE',
        'serveur recent',
      );
      expect(logger.error).not.toHaveBeenCalled();
    });

    it('should_use_generic_message_when_no_fallback_is_given', () => {
      // Arrange
      const error = httpError(418, { error: 'BREWING_COFFEE' });

      // Act & Assert
      expect(service.label(error)).toBe(GENERIC_ERROR_MESSAGE);
    });
  });

  describe('corps non conforme', () => {
    it.each([
      ['null', null],
      ['undefined', undefined],
      ['une chaine HTML de reverse proxy', '<html>502 Bad Gateway</html>'],
      ['un tableau', [{ error: 'NOT_FOUND' }]],
      ['un objet sans champ error', { message: 'Transaction non trouvee' }],
      ['un champ error non-chaine', { error: 42 }],
      ['un champ error vide', { error: '' }],
    ])('should_return_fallback_when_body_is_%s', (_label, body) => {
      // Arrange
      const error = httpError(500, body);

      // Act & Assert
      expect(service.label(error, 'Repli contextuel')).toBe('Repli contextuel');
      expect(logger.warn).not.toHaveBeenCalled();
    });

    it('should_return_fallback_when_error_is_not_an_http_error_response', () => {
      // Act & Assert
      expect(service.label(new Error('boom'), 'Repli contextuel')).toBe('Repli contextuel');
      expect(service.label(undefined, 'Repli contextuel')).toBe('Repli contextuel');
    });
  });

  describe('indisponibilite reseau', () => {
    it('should_return_network_message_when_status_is_0', () => {
      // Arrange — sur un statut 0 il n'y a pas de corps du tout.
      const error = httpError(0, null);

      // Act
      const label = service.label(error, 'Repli contextuel');

      // Assert — distinct du libelle generique : l'utilisateur peut agir dessus.
      expect(label).toBe(NETWORK_ERROR_MESSAGE);
      expect(label).not.toBe(GENERIC_ERROR_MESSAGE);
    });
  });

  describe('VALIDATION_ERROR', () => {
    it('should_keep_password_length_message_when_detail_is_recognised', () => {
      // Arrange
      const error = httpError(400, {
        error: 'VALIDATION_ERROR',
        message: 'password: size must be between 12 and 100',
        details: [{ field: 'password', code: 'SIZE', message: 'size must be between 12 and 100' }],
      });

      // Act & Assert — precision heritee de KKS-351, conservee a l'identique.
      expect(service.label(error)).toBe(PASSWORD_MIN_LENGTH_MESSAGE);
    });

    it('should_return_generic_validation_message_when_no_detail_is_recognised', () => {
      // Arrange
      const error = httpError(400, {
        error: 'VALIDATION_ERROR',
        message: 'email: must not be blank',
        details: [{ field: 'email', code: 'NOT_BLANK', message: 'must not be blank' }],
      });

      // Act & Assert
      expect(service.label(error)).toBe(VALIDATION_ERROR_MESSAGE);
    });

    it.each([
      ['absent', undefined],
      ['vide', []],
      ['non tableau', { field: 'password' }],
    ])('should_return_generic_validation_message_when_details_is_%s', (_label, details) => {
      // Arrange — `details` est absent du JSON quand il est vide
      // (`@JsonInclude(NON_EMPTY)` cote serveur).
      const error = httpError(400, { error: 'VALIDATION_ERROR', details });

      // Act & Assert
      expect(service.label(error)).toBe(VALIDATION_ERROR_MESSAGE);
    });
  });

  describe('overrides du site appelant', () => {
    it('should_prefer_override_over_catalogue_when_code_matches', () => {
      // Arrange — sur `/auth/login`, `BAD_REQUEST` ne signifie qu'une chose.
      const error = httpError(400, {
        error: 'BAD_REQUEST',
        message: 'Email ou mot de passe incorrect',
      });

      // Act
      const label = service.label(error, GENERIC_ERROR_MESSAGE, LOGIN_ERROR_OVERRIDES);

      // Assert
      expect(label).toBe('Email ou mot de passe incorrect');
      expect(label).not.toBe(ERROR_MESSAGES['BAD_REQUEST']);
    });

    it('should_fall_back_to_catalogue_when_code_is_not_overridden', () => {
      // Arrange
      const error = httpError(429, { error: 'TOO_MANY_REQUESTS' });

      // Act & Assert
      expect(service.label(error, GENERIC_ERROR_MESSAGE, LOGIN_ERROR_OVERRIDES)).toBe(
        ERROR_MESSAGES['TOO_MANY_REQUESTS'],
      );
    });
  });
});
