import { getTestBed, TestBed } from '@angular/core/testing';
import {
  BrowserTestingModule,
  platformBrowserTesting,
} from '@angular/platform-browser/testing';
import { provideHttpClient, withInterceptors, HttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { Router } from '@angular/router';

import { AuthService } from '../services/auth';
import { authInterceptor, _resetInterceptorState } from './auth.interceptor';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

describe('authInterceptor', () => {
  let httpClient: HttpClient;
  let httpTesting: HttpTestingController;
  let authService: { getToken: ReturnType<typeof vi.fn>; logout: ReturnType<typeof vi.fn> };
  let router: { navigate: ReturnType<typeof vi.fn>; url: string };

  beforeEach(() => {
    authService = {
      getToken: vi.fn().mockReturnValue(null),
      logout: vi.fn().mockReturnValue(undefined),
    };

    router = {
      navigate: vi.fn().mockReturnValue(undefined),
      url: '/',
    };

    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting(),
        { provide: AuthService, useValue: authService },
        { provide: Router, useValue: router },
      ],
    });

    httpClient = TestBed.inject(HttpClient);
    httpTesting = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpTesting.verify();
    _resetInterceptorState();
  });

  it('should_pass_request_through_without_modification', () => {
    // Arrange
    authService.getToken.mockReturnValue(null);

    // Act
    httpClient.get('/api/test').subscribe();

    // Assert
    const req = httpTesting.expectOne('/api/test');
    expect(req.request.headers.has('Authorization')).toBe(false);
    req.flush({});
  });

  // --- US1: Injection automatique du token ---

  it('should_add_auth_header_when_token_exists', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-jwt-token');

    // Act
    httpClient.get('/api/transactions').subscribe();

    // Assert
    const req = httpTesting.expectOne('/api/transactions');
    expect(req.request.headers.get('Authorization')).toBe('Bearer my-jwt-token');
    req.flush({});
  });

  it('should_send_request_without_header_when_no_token', () => {
    // Arrange
    authService.getToken.mockReturnValue(null);

    // Act
    httpClient.get('/api/transactions').subscribe();

    // Assert
    const req = httpTesting.expectOne('/api/transactions');
    expect(req.request.headers.has('Authorization')).toBe(false);
    req.flush({});
  });

  it('should_add_same_header_to_concurrent_requests', () => {
    // Arrange
    authService.getToken.mockReturnValue('shared-token');

    // Act
    httpClient.get('/api/transactions').subscribe();
    httpClient.get('/api/subscriptions').subscribe();

    // Assert
    const reqs = httpTesting.match((r) => r.url.startsWith('/api/'));
    expect(reqs).toHaveLength(2);
    expect(reqs[0].request.headers.get('Authorization')).toBe('Bearer shared-token');
    expect(reqs[1].request.headers.get('Authorization')).toBe('Bearer shared-token');
    reqs[0].flush({});
    reqs[1].flush({});
  });

  // --- US2 : Exclusion des routes publiques ---

  it('should_not_add_header_when_url_is_login', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');

    // Act
    httpClient.post('/api/auth/login', {}).subscribe();

    // Assert
    const req = httpTesting.expectOne('/api/auth/login');
    expect(req.request.headers.has('Authorization')).toBe(false);
    req.flush({});
  });

  it('should_not_add_header_when_url_is_register', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');

    // Act
    httpClient.post('/api/auth/register', {}).subscribe();

    // Assert
    const req = httpTesting.expectOne('/api/auth/register');
    expect(req.request.headers.has('Authorization')).toBe(false);
    req.flush({});
  });

  it('should_add_header_when_url_is_other_api_route', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');

    // Act
    httpClient.get('/api/transactions').subscribe();

    // Assert
    const req = httpTesting.expectOne('/api/transactions');
    expect(req.request.headers.get('Authorization')).toBe('Bearer my-token');
    req.flush({});
  });

  it('should_not_add_header_when_url_is_absolute_external', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');

    // Act
    httpClient.get('https://external.com/api/data').subscribe();

    // Assert
    const req = httpTesting.expectOne('https://external.com/api/data');
    expect(req.request.headers.has('Authorization')).toBe(false);
    req.flush({});
  });

  // --- US3: Déconnexion automatique sur 401 ---

  it('should_call_logout_when_401_received', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');

    // Act
    httpClient.get('/api/transactions').subscribe({
      error: () => {
        // expected
      },
    });
    const req = httpTesting.expectOne('/api/transactions');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert
    expect(authService.logout).toHaveBeenCalledOnce();
  });

  it('should_not_call_logout_when_403_received', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');
    let caughtError: unknown = null;

    // Act
    httpClient.get('/api/transactions').subscribe({
      error: (err) => {
        caughtError = err;
      },
    });
    const req = httpTesting.expectOne('/api/transactions');
    req.flush('Forbidden', { status: 403, statusText: 'Forbidden' });

    // Assert
    expect(authService.logout).not.toHaveBeenCalled();
    expect(caughtError).not.toBeNull();
  });

  it('should_call_logout_only_once_on_multiple_401', () => {
    // Arrange
    vi.useFakeTimers();
    authService.getToken.mockReturnValue('my-token');

    // Act
    const noop = vi.fn();
    httpClient.get('/api/transactions').subscribe({ error: noop });
    httpClient.get('/api/subscriptions').subscribe({ error: noop });

    const reqs = httpTesting.match((r) => r.url.startsWith('/api/'));
    reqs[0].flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });
    reqs[1].flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert
    expect(authService.logout).toHaveBeenCalledOnce();

    vi.advanceTimersByTime(1000);
    vi.useRealTimers();
  });

  it('should_propagate_error_after_logout', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');
    let caughtError: unknown = null;

    // Act
    httpClient.get('/api/transactions').subscribe({
      error: (err) => {
        caughtError = err;
      },
    });
    const req = httpTesting.expectOne('/api/transactions');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert
    expect(authService.logout).toHaveBeenCalledOnce();
    expect(caughtError).not.toBeNull();
  });

  it('should_still_call_logout_when_already_on_auth_page', () => {
    // Arrange
    vi.useFakeTimers();
    authService.getToken.mockReturnValue('my-token');
    router.url = '/auth';

    // Act
    httpClient.get('/api/transactions').subscribe({ error: vi.fn() });
    const req = httpTesting.expectOne('/api/transactions');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert
    expect(authService.logout).toHaveBeenCalledOnce();

    vi.advanceTimersByTime(1000);
    vi.useRealTimers();
  });
});
