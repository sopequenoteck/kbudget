import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { of, throwError } from 'rxjs';

import { AuthService } from './auth';
import { ApiService } from './api';
import { AuthResponse } from '../models/auth.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

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
  email: 'test@test.com',
  name: 'Test User',
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

  // T009 — Tests login()
  describe('login()', () => {
    it('should_store_token_and_update_signals_when_login_succeeds', () => {
      // Arrange
      const response: AuthResponse = { ...mockAuthResponse, token: validToken() };
      apiService.post.mockReturnValue(of(response));

      // Act
      service.login({ email: 'test@test.com', password: 'password123' }).subscribe();

      // Assert
      expect(localStorage.getItem('budget_token')).toBe(response.token);
      expect(JSON.parse(localStorage.getItem('budget_user')!)).toEqual({
        name: 'Test User',
        email: 'test@test.com',
      });
      expect(service.currentUser()).toEqual({ name: 'Test User', email: 'test@test.com' });
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

  // T010 — Tests register()
  describe('register()', () => {
    it('should_store_token_and_auto_connect_when_register_succeeds', () => {
      // Arrange
      const response: AuthResponse = { ...mockAuthResponse, token: validToken() };
      apiService.post.mockReturnValue(of(response));

      // Act
      service
        .register({ name: 'New User', email: 'new@test.com', password: 'password123' })
        .subscribe();

      // Assert
      expect(localStorage.getItem('budget_token')).toBe(response.token);
      expect(JSON.parse(localStorage.getItem('budget_user')!)).toEqual({
        name: 'Test User',
        email: 'test@test.com',
      });
      expect(service.currentUser()).toEqual({ name: 'Test User', email: 'test@test.com' });
      expect(service.isAuthenticated()).toBe(true);
    });

    it('should_return_email_taken_message_when_register_returns_400', () => {
      // Arrange
      const httpError = new HttpErrorResponse({
        status: 400,
        error: { message: 'Email déjà utilisé' },
      });
      apiService.post.mockReturnValue(throwError(() => httpError));

      // Act & Assert
      service.register({ email: 'taken@test.com', password: 'password123' }).subscribe({
        error: (msg: string) => {
          expect(msg).toBe('Email déjà utilisé');
        },
      });
    });

    it('should_return_validation_message_when_register_returns_bean_validation_error', () => {
      // Arrange
      const httpError = new HttpErrorResponse({
        status: 400,
        error: { message: 'password: size must be between 6 and 2147483647' },
      });
      apiService.post.mockReturnValue(throwError(() => httpError));

      // Act & Assert
      service.register({ email: 'new@test.com', password: '123' }).subscribe({
        error: (msg: string) => {
          expect(msg).toBe('password: size must be between 6 and 2147483647');
        },
      });
    });

    it('should_return_network_error_when_register_status_is_0', () => {
      // Arrange
      const httpError = new HttpErrorResponse({ status: 0 });
      apiService.post.mockReturnValue(throwError(() => httpError));
      vi.spyOn(console, 'error').mockReturnValue(undefined);

      // Act & Assert
      service.register({ email: 'new@test.com', password: 'password123' }).subscribe({
        error: (msg: string) => {
          expect(msg).toBe('Impossible de contacter le serveur');
        },
      });
    });

    it('should_return_generic_error_when_register_status_is_500', () => {
      // Arrange
      const httpError = new HttpErrorResponse({ status: 500 });
      apiService.post.mockReturnValue(throwError(() => httpError));

      // Act & Assert
      service.register({ email: 'new@test.com', password: 'password123' }).subscribe({
        error: (msg: string) => {
          expect(msg).toBe('Une erreur est survenue');
        },
      });
    });
  });

  // T011 — Tests logout()
  describe('logout()', () => {
    it('should_clear_storage_and_signals_and_navigate_when_logout', () => {
      // Arrange — simulate logged in state
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem(
        'budget_user',
        JSON.stringify({ name: 'Test User', email: 'test@test.com' }),
      );

      // Act
      service.logout();

      // Assert
      expect(localStorage.getItem('budget_token')).toBeNull();
      expect(localStorage.getItem('budget_user')).toBeNull();
      expect(service.currentUser()).toBeNull();
      expect(service.isAuthenticated()).toBe(false);
      expect(router.navigate).toHaveBeenCalledWith(['/auth']);
    });
  });

  // T012 — Tests getToken()
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

    it('should_return_null_and_clear_when_token_is_expired', () => {
      // Arrange
      localStorage.setItem('budget_token', expiredToken());
      localStorage.setItem('budget_user', JSON.stringify({ name: 'Test', email: 'test@test.com' }));

      // Act
      const result = service.getToken();

      // Assert
      expect(result).toBeNull();
      expect(localStorage.getItem('budget_token')).toBeNull();
      expect(localStorage.getItem('budget_user')).toBeNull();
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
  });

  // T013 — Tests constructeur
  describe('constructor', () => {
    it('should_restore_session_when_valid_token_in_localStorage', () => {
      // Arrange
      const token = validToken();
      localStorage.setItem('budget_token', token);
      localStorage.setItem(
        'budget_user',
        JSON.stringify({ name: 'Restored User', email: 'restored@test.com' }),
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
      });
      expect(newService.isAuthenticated()).toBe(true);
    });

    it('should_clear_session_when_expired_token_in_localStorage', () => {
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
});
