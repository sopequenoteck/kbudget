import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { of, throwError } from 'rxjs';

import { AuthService } from './auth';
import { ApiService } from './api';
import { AuthResponse } from '../models/auth.model';

function createJwt(payload: Record<string, unknown>): string {
  const header = btoa(JSON.stringify({ alg: 'HS256' }));
  const body = btoa(JSON.stringify(payload))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
  return `${header}.${body}.fakesignature`;
}

function validToken(): string {
  return createJwt({ sub: 'test@test.com', exp: Math.floor(Date.now() / 1000) + 3600 });
}

function expiredToken(): string {
  return createJwt({ sub: 'test@test.com', exp: Math.floor(Date.now() / 1000) - 3600 });
}

const mockAuthResponse: AuthResponse = {
  token: validToken(),
  refreshToken: 'mock-refresh-token',
  email: 'test@test.com',
  name: 'Test User',
  mustResetCredentials: false,
};

describe('AuthService', () => {
  let service: AuthService;
  let apiService: { post: ReturnType<typeof vi.fn> };
  let router: { navigate: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    localStorage.clear();

    apiService = {
      post: vi.fn(),
    };

    router = {
      navigate: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [
        AuthService,
        { provide: ApiService, useValue: apiService },
        { provide: Router, useValue: router },
      ],
    });

    service = TestBed.inject(AuthService);
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('login()', () => {
    it('should_store_token_and_refresh_token_when_login_succeeds', () => {
      // Arrange
      const response: AuthResponse = { ...mockAuthResponse, token: validToken() };
      apiService.post.mockReturnValue(of(response));

      // Act
      service.login({ email: 'test@test.com', password: 'password123' }).subscribe();

      // Assert
      expect(localStorage.getItem('budget_token')).toBe(response.token);
      expect(localStorage.getItem('budget_refresh_token')).toBe(response.refreshToken);
      expect(JSON.parse(localStorage.getItem('budget_user')!)).toEqual({
        name: 'Test User',
        email: 'test@test.com',
        mustResetCredentials: false,
      });
      expect(service.currentUser()).toEqual({
        name: 'Test User',
        email: 'test@test.com',
        mustResetCredentials: false,
      });
      expect(service.isAuthenticated()).toBe(true);
    });

    it('should_return_error_message_when_login_returns_400', () => {
      // Arrange
      const httpError = new HttpErrorResponse({
        status: 400,
        error: { message: 'Email ou mot de passe incorrect' },
      });
      apiService.post.mockReturnValue(throwError(() => httpError));

      // Act & Assert
      service.login({ email: 'test@test.com', password: 'wrong' }).subscribe({
        error: (msg: string) => {
          expect(msg).toBe('Email ou mot de passe incorrect');
        },
      });
    });

    it('should_return_network_error_when_status_is_0', () => {
      // Arrange
      const httpError = new HttpErrorResponse({ status: 0 });
      apiService.post.mockReturnValue(throwError(() => httpError));
      vi.spyOn(console, 'error').mockReturnValue(undefined);

      // Act & Assert
      service.login({ email: 'test@test.com', password: 'pass' }).subscribe({
        error: (msg: string) => {
          expect(msg).toBe('Impossible de contacter le serveur');
        },
      });
    });

    it('should_return_generic_error_when_status_is_500', () => {
      // Arrange
      const httpError = new HttpErrorResponse({ status: 500 });
      apiService.post.mockReturnValue(throwError(() => httpError));

      // Act & Assert
      service.login({ email: 'test@test.com', password: 'pass' }).subscribe({
        error: (msg: string) => {
          expect(msg).toBe('Une erreur est survenue');
        },
      });
    });
  });

  describe('logout()', () => {
    it('should_clear_storage_and_signals_and_navigate_when_logout', () => {
      // Arrange — simulate logged in state
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem('budget_refresh_token', 'some-refresh-token');
      localStorage.setItem(
        'budget_user',
        JSON.stringify({ name: 'Test User', email: 'test@test.com' }),
      );
      apiService.post.mockReturnValue(of(null));

      // Act
      service.logout();

      // Assert
      expect(localStorage.getItem('budget_token')).toBeNull();
      expect(localStorage.getItem('budget_refresh_token')).toBeNull();
      expect(localStorage.getItem('budget_user')).toBeNull();
      expect(service.currentUser()).toBeNull();
      expect(service.isAuthenticated()).toBe(false);
      expect(router.navigate).toHaveBeenCalledWith(['/auth']);
    });

    it('should_call_logout_api_with_refresh_token', () => {
      // Arrange
      localStorage.setItem('budget_refresh_token', 'revoke-me');
      apiService.post.mockReturnValue(of(null));

      // Act
      service.logout();

      // Assert
      expect(apiService.post).toHaveBeenCalledWith('/auth/logout', {
        refreshToken: 'revoke-me',
      });
    });

    it('should_clear_local_even_when_api_fails', () => {
      // Arrange
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem('budget_refresh_token', 'token-to-revoke');
      apiService.post.mockReturnValue(throwError(() => new HttpErrorResponse({ status: 0 })));

      // Act
      service.logout();

      // Assert — fire-and-forget: local cleanup happens regardless
      expect(localStorage.getItem('budget_token')).toBeNull();
      expect(localStorage.getItem('budget_refresh_token')).toBeNull();
      expect(router.navigate).toHaveBeenCalledWith(['/auth']);
    });

    it('should_not_call_api_when_no_refresh_token', () => {
      // Act
      service.logout();

      // Assert
      expect(apiService.post).not.toHaveBeenCalled();
      expect(router.navigate).toHaveBeenCalledWith(['/auth']);
    });
  });

  describe('getToken()', () => {
    it('should_return_token_when_token_is_valid', () => {
      // Arrange
      const token = validToken();
      localStorage.setItem('budget_token', token);

      // Act
      const result = service.getToken();

      // Assert
      expect(result).toBe(token);
    });

    it('should_return_null_without_clearing_when_token_is_expired', () => {
      // Arrange
      localStorage.setItem('budget_token', expiredToken());
      localStorage.setItem('budget_refresh_token', 'refresh-token-still-valid');

      // Act
      const result = service.getToken();

      // Assert
      expect(result).toBeNull();
      // getToken() ne doit PAS supprimer le refresh token (nécessaire pour le renouvellement)
      expect(localStorage.getItem('budget_refresh_token')).toBe('refresh-token-still-valid');
    });

    it('should_return_null_when_token_is_corrupted', () => {
      // Arrange
      localStorage.setItem('budget_token', 'not.a.valid.jwt');
      vi.spyOn(console, 'error').mockReturnValue(undefined);

      // Act
      const result = service.getToken();

      // Assert
      expect(result).toBeNull();
    });

    it('should_return_null_when_no_token', () => {
      // Act
      const result = service.getToken();

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('getRefreshToken()', () => {
    it('should_return_refresh_token_when_present', () => {
      // Arrange
      localStorage.setItem('budget_refresh_token', 'my-refresh-token');

      // Act
      const result = service.getRefreshToken();

      // Assert
      expect(result).toBe('my-refresh-token');
    });

    it('should_return_null_when_no_refresh_token', () => {
      // Act
      const result = service.getRefreshToken();

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('refreshAccessToken()', () => {
    it('should_save_new_tokens_when_refresh_succeeds', () => {
      // Arrange
      localStorage.setItem('budget_refresh_token', 'old-refresh-token');
      const newToken = validToken();
      const response: AuthResponse = {
        token: newToken,
        refreshToken: 'new-refresh-token',
        email: 'test@test.com',
        name: 'Test User',
        mustResetCredentials: false,
      };
      apiService.post.mockReturnValue(of(response));

      // Act
      service.refreshAccessToken().subscribe();

      // Assert
      expect(apiService.post).toHaveBeenCalledWith('/auth/refresh', {
        refreshToken: 'old-refresh-token',
      });
      expect(localStorage.getItem('budget_token')).toBe(newToken);
      expect(localStorage.getItem('budget_refresh_token')).toBe('new-refresh-token');
      expect(service.currentUser()).toEqual({
        name: 'Test User',
        email: 'test@test.com',
        mustResetCredentials: false,
      });
    });

    it('should_throw_401_when_no_refresh_token', () => {
      // Act & Assert
      service.refreshAccessToken().subscribe({
        error: (err: HttpErrorResponse) => {
          expect(err.status).toBe(401);
        },
      });
      expect(apiService.post).not.toHaveBeenCalled();
    });

    it('should_propagate_error_when_refresh_api_fails', () => {
      // Arrange
      localStorage.setItem('budget_refresh_token', 'expired-refresh-token');
      const httpError = new HttpErrorResponse({ status: 401 });
      apiService.post.mockReturnValue(throwError(() => httpError));

      // Act & Assert
      service.refreshAccessToken().subscribe({
        error: (err: HttpErrorResponse) => {
          expect(err.status).toBe(401);
        },
      });
    });
  });

  describe('constructor / restoreSession', () => {
    it('should_restore_session_when_valid_token_in_localStorage', () => {
      // Arrange
      const token = validToken();
      localStorage.setItem('budget_token', token);
      localStorage.setItem(
        'budget_user',
        JSON.stringify({ name: 'Restored User', email: 'restored@test.com', mustResetCredentials: false }),
      );

      // Act — recreate service to trigger constructor
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert
      expect(newService.currentUser()).toEqual({
        name: 'Restored User',
        email: 'restored@test.com',
        mustResetCredentials: false,
      });
      expect(newService.isAuthenticated()).toBe(true);
    });

    it('should_clear_session_when_expired_token_and_no_refresh_token', () => {
      // Arrange
      localStorage.setItem('budget_token', expiredToken());
      localStorage.setItem('budget_user', JSON.stringify({ name: 'Old', email: 'old@test.com' }));

      // Act
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert
      expect(newService.currentUser()).toBeNull();
      expect(newService.isAuthenticated()).toBe(false);
      expect(localStorage.getItem('budget_token')).toBeNull();
    });

    it('should_auto_refresh_when_expired_token_with_valid_refresh_token', () => {
      // Arrange
      localStorage.setItem('budget_token', expiredToken());
      localStorage.setItem('budget_refresh_token', 'valid-refresh');
      const newToken = validToken();
      const refreshResponse = {
        token: newToken,
        refreshToken: 'rotated-refresh',
        email: 'restored@test.com',
        name: 'Restored User',
        mustResetCredentials: false,
      };
      apiService.post.mockReturnValue(of(refreshResponse));
      vi.spyOn(console, 'log').mockReturnValue(undefined);

      // Act
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert — session restored via refresh
      expect(apiService.post).toHaveBeenCalledWith('/auth/refresh', {
        refreshToken: 'valid-refresh',
      });
      expect(newService.currentUser()).toEqual({
        name: 'Restored User',
        email: 'restored@test.com',
        mustResetCredentials: false,
      });
      expect(newService.isAuthenticated()).toBe(true);
      expect(localStorage.getItem('budget_refresh_token')).toBe('rotated-refresh');
    });

    it('should_clear_auth_when_expired_token_and_refresh_fails', () => {
      // Arrange
      localStorage.setItem('budget_token', expiredToken());
      localStorage.setItem('budget_refresh_token', 'expired-refresh');
      apiService.post.mockReturnValue(throwError(() => new HttpErrorResponse({ status: 401 })));
      vi.spyOn(console, 'log').mockReturnValue(undefined);

      // Act
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert — clearAuth called, no redirect (auth guard handles it)
      expect(newService.currentUser()).toBeNull();
      expect(newService.isAuthenticated()).toBe(false);
      expect(localStorage.getItem('budget_token')).toBeNull();
      expect(localStorage.getItem('budget_refresh_token')).toBeNull();
    });

    it('should_not_refresh_when_valid_token_exists', () => {
      // Arrange
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem('budget_refresh_token', 'some-refresh');
      localStorage.setItem('budget_user', JSON.stringify({ name: 'User', email: 'user@test.com', mustResetCredentials: false }));

      // Act
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert — no refresh call, session restored from localStorage
      expect(apiService.post).not.toHaveBeenCalled();
      expect(newService.isAuthenticated()).toBe(true);
    });

    it('should_handle_localStorage_unavailable_without_crash', () => {
      // Arrange
      vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
        throw new Error('localStorage disabled');
      });
      vi.spyOn(console, 'error').mockReturnValue(undefined);

      // Act
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert — no crash, state is disconnected
      expect(newService.currentUser()).toBeNull();
      expect(newService.isAuthenticated()).toBe(false);

      // Cleanup
      vi.restoreAllMocks();
    });

    it('should_clear_both_keys_when_budget_user_is_corrupted', () => {
      // Arrange
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem('budget_user', 'not-valid-json{{{');
      vi.spyOn(console, 'error').mockReturnValue(undefined);

      // Act
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert
      expect(newService.currentUser()).toBeNull();
      expect(newService.isAuthenticated()).toBe(false);
      expect(localStorage.getItem('budget_token')).toBeNull();
      expect(localStorage.getItem('budget_user')).toBeNull();
    });
  });

  describe('mustResetCredentials — persistance localStorage (T-049)', () => {
    it('should_persist_must_reset_credentials_in_localStorage_after_saveAuth', () => {
      // Arrange
      const response: AuthResponse = {
        token: validToken(),
        refreshToken: 'mock-refresh-token',
        email: 'admin@localhost',
        name: 'Admin',
        mustResetCredentials: true,
      };
      apiService.post.mockReturnValue(of(response));

      // Act
      service.login({ email: 'admin@localhost', password: 'temp-pass' }).subscribe();

      // Assert
      const stored = JSON.parse(localStorage.getItem('budget_user')!);
      expect(stored.mustResetCredentials).toBe(true);
      expect(service.mustResetCredentials()).toBe(true);
    });

    it('should_restore_must_reset_credentials_from_localStorage_on_restoreSession', () => {
      // Arrange
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem(
        'budget_user',
        JSON.stringify({
          name: 'Admin',
          email: 'admin@localhost',
          mustResetCredentials: true,
        }),
      );

      // Act — recreate service to trigger restoreSession
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert
      expect(newService.mustResetCredentials()).toBe(true);
      expect(newService.currentUser()?.mustResetCredentials).toBe(true);
    });

    it('should_default_must_reset_credentials_to_false_when_absent_from_localStorage', () => {
      // Arrange — legacy localStorage entry without mustResetCredentials
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem(
        'budget_user',
        JSON.stringify({ name: 'Legacy User', email: 'legacy@test.com' }),
      );

      // Act
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          AuthService,
          { provide: ApiService, useValue: apiService },
          { provide: Router, useValue: router },
        ],
      });
      const newService = TestBed.inject(AuthService);

      // Assert — fallback to false for retro-compatibility
      expect(newService.mustResetCredentials()).toBe(false);
    });
  });
});
