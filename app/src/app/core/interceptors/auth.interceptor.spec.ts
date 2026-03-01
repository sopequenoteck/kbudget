import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { provideHttpClient, withInterceptors, HttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { of, Subject, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

import { AuthService } from '../services/auth';
import { authInterceptor, _resetInterceptorState } from './auth.interceptor';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

describe('authInterceptor', () => {
  let httpClient: HttpClient;
  let httpTesting: HttpTestingController;
  let authService: {
    getToken: ReturnType<typeof vi.fn>;
    getRefreshToken: ReturnType<typeof vi.fn>;
    refreshAccessToken: ReturnType<typeof vi.fn>;
    logout: ReturnType<typeof vi.fn>;
  };
  let router: { navigate: ReturnType<typeof vi.fn>; url: string };

  beforeEach(() => {
    authService = {
      getToken: vi.fn().mockReturnValue(null),
      getRefreshToken: vi.fn().mockReturnValue(null),
      refreshAccessToken: vi.fn(),
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

  // --- Token injection ---

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

  // --- Public routes exclusion ---

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

  it('should_not_add_header_when_url_is_refresh', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');

    // Act
    httpClient.post('/api/auth/refresh', {}).subscribe();

    // Assert
    const req = httpTesting.expectOne('/api/auth/refresh');
    expect(req.request.headers.has('Authorization')).toBe(false);
    req.flush({});
  });

  it('should_not_add_header_when_url_is_logout', () => {
    // Arrange
    authService.getToken.mockReturnValue('my-token');

    // Act
    httpClient.post('/api/auth/logout', {}).subscribe();

    // Assert
    const req = httpTesting.expectOne('/api/auth/logout');
    expect(req.request.headers.has('Authorization')).toBe(false);
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

  // --- Refresh on 401 ---

  it('should_refresh_and_replay_when_401_received', () => {
    // Arrange
    authService.getToken.mockReturnValue('expired-token');
    const newToken = 'new-valid-token';
    authService.refreshAccessToken.mockReturnValue(
      of({ token: newToken, refreshToken: 'new-refresh', email: 'a@b.com', name: 'A' }),
    );
    vi.spyOn(console, 'log').mockReturnValue(undefined);

    // Act
    let result: unknown = null;
    httpClient.get('/api/transactions').subscribe((r) => (result = r));

    // First request returns 401
    const firstReq = httpTesting.expectOne('/api/transactions');
    firstReq.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Interceptor retries with new token
    const retryReq = httpTesting.expectOne('/api/transactions');
    expect(retryReq.request.headers.get('Authorization')).toBe(`Bearer ${newToken}`);
    expect(retryReq.request.headers.has('_retry')).toBe(true);
    retryReq.flush({ data: 'success' });

    // Assert
    expect(authService.refreshAccessToken).toHaveBeenCalledOnce();
    expect(result).toEqual({ data: 'success' });
  });

  it('should_serialize_concurrent_401_with_single_refresh', () => {
    // Arrange — use Subject to simulate async refresh
    authService.getToken.mockReturnValue('expired-token');
    const newToken = 'refreshed-token';
    const refreshSubject = new Subject<{
      token: string;
      refreshToken: string;
      email: string;
      name: string;
    }>();
    vi.spyOn(console, 'log').mockReturnValue(undefined);

    authService.refreshAccessToken.mockReturnValue(refreshSubject.asObservable());

    // Act — 2 concurrent requests
    let result1: unknown = null;
    let result2: unknown = null;
    httpClient.get('/api/transactions').subscribe((r) => (result1 = r));
    httpClient.get('/api/subscriptions').subscribe((r) => (result2 = r));

    // Both get 401
    const reqs = httpTesting.match((r) => r.url.startsWith('/api/') && !r.headers.has('_retry'));
    expect(reqs).toHaveLength(2);
    reqs[0].flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });
    reqs[1].flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Resolve the refresh (async) — getToken returns new token after refresh
    authService.getToken.mockReturnValue(newToken);
    refreshSubject.next({
      token: newToken,
      refreshToken: 'new-r',
      email: 'a@b.com',
      name: 'A',
    });
    refreshSubject.complete();

    // Both retried — flush by URL to match subscribers
    const retryReqs = httpTesting.match((r) => r.headers.has('_retry'));
    expect(retryReqs).toHaveLength(2);
    for (const r of retryReqs) {
      if (r.request.url.includes('transactions')) r.flush({ data: 'tx' });
      else r.flush({ data: 'sub' });
    }

    // Assert — only ONE refresh call, both requests succeeded
    expect(authService.refreshAccessToken).toHaveBeenCalledOnce();
    expect(result1).toEqual({ data: 'tx' });
    expect(result2).toEqual({ data: 'sub' });
  });

  it('should_not_retry_refresh_on_retry_request', () => {
    // Arrange — a request already marked with _retry that gets 401
    authService.getToken.mockReturnValue('token');
    let caughtError: unknown = null;

    // Act
    httpClient
      .get('/api/transactions', { headers: { _retry: 'true' } })
      .subscribe({ error: (err) => (caughtError = err) });
    const req = httpTesting.expectOne('/api/transactions');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert — no refresh attempt, error propagated
    expect(authService.refreshAccessToken).not.toHaveBeenCalled();
    expect(caughtError).not.toBeNull();
  });

  it('should_not_refresh_on_401_from_public_path', () => {
    // Arrange
    authService.getToken.mockReturnValue(null);
    let caughtError: unknown = null;

    // Act
    httpClient.post('/api/auth/login', {}).subscribe({ error: (err) => (caughtError = err) });
    const req = httpTesting.expectOne('/api/auth/login');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert
    expect(authService.refreshAccessToken).not.toHaveBeenCalled();
    expect(caughtError).not.toBeNull();
  });

  it('should_refresh_and_replay_when_403_received', () => {
    // Arrange — 403 triggers refresh (expired token sent without header)
    authService.getToken.mockReturnValue('my-token');
    const newToken = 'new-valid-token';
    authService.refreshAccessToken.mockReturnValue(
      of({ token: newToken, refreshToken: 'new-refresh', email: 'a@b.com', name: 'A' }),
    );
    vi.spyOn(console, 'log').mockReturnValue(undefined);

    // Act
    let result: unknown = null;
    httpClient.get('/api/transactions').subscribe((r) => (result = r));

    const firstReq = httpTesting.expectOne('/api/transactions');
    firstReq.flush('Forbidden', { status: 403, statusText: 'Forbidden' });

    // Interceptor retries with new token
    const retryReq = httpTesting.expectOne('/api/transactions');
    expect(retryReq.request.headers.get('Authorization')).toBe(`Bearer ${newToken}`);
    retryReq.flush({ data: 'success' });

    // Assert
    expect(authService.refreshAccessToken).toHaveBeenCalledOnce();
    expect(result).toEqual({ data: 'success' });
  });

  it('should_not_refresh_on_403_from_public_path', () => {
    // Arrange
    authService.getToken.mockReturnValue(null);
    let caughtError: unknown = null;

    // Act
    httpClient.post('/api/auth/login', {}).subscribe({ error: (err) => (caughtError = err) });
    const req = httpTesting.expectOne('/api/auth/login');
    req.flush('Forbidden', { status: 403, statusText: 'Forbidden' });

    // Assert
    expect(authService.refreshAccessToken).not.toHaveBeenCalled();
    expect(caughtError).not.toBeNull();
  });

  // --- Refresh failure scenarios (T009/T010) ---

  it('should_logout_when_refresh_returns_401', () => {
    // Arrange
    authService.getToken.mockReturnValue('expired-token');
    authService.refreshAccessToken.mockReturnValue(
      throwError(() => new HttpErrorResponse({ status: 401 })),
    );
    vi.spyOn(console, 'log').mockReturnValue(undefined);
    vi.spyOn(console, 'error').mockReturnValue(undefined);
    let caughtError: unknown = null;

    // Act
    httpClient.get('/api/transactions').subscribe({ error: (err) => (caughtError = err) });
    const req = httpTesting.expectOne('/api/transactions');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert
    expect(authService.logout).toHaveBeenCalledOnce();
    expect(caughtError).not.toBeNull();
  });

  it('should_not_logout_when_refresh_fails_with_network_error', () => {
    // Arrange
    authService.getToken.mockReturnValue('expired-token');
    authService.refreshAccessToken.mockReturnValue(
      throwError(() => new HttpErrorResponse({ status: 0 })),
    );
    vi.spyOn(console, 'log').mockReturnValue(undefined);
    vi.spyOn(console, 'error').mockReturnValue(undefined);
    let caughtError: unknown = null;

    // Act
    httpClient.get('/api/transactions').subscribe({ error: (err) => (caughtError = err) });
    const req = httpTesting.expectOne('/api/transactions');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert — network error: no logout, error propagated
    expect(authService.logout).not.toHaveBeenCalled();
    expect(caughtError).not.toBeNull();
  });

  it('should_logout_immediately_when_no_refresh_token_available', () => {
    // Arrange — refreshAccessToken() throws 401 when no refresh token
    authService.getToken.mockReturnValue('expired-token');
    authService.refreshAccessToken.mockReturnValue(
      throwError(() => new HttpErrorResponse({ status: 401, statusText: 'No refresh token' })),
    );
    vi.spyOn(console, 'log').mockReturnValue(undefined);
    vi.spyOn(console, 'error').mockReturnValue(undefined);
    let caughtError: unknown = null;

    // Act
    httpClient.get('/api/transactions').subscribe({ error: (err) => (caughtError = err) });
    const req = httpTesting.expectOne('/api/transactions');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    // Assert
    expect(authService.logout).toHaveBeenCalledOnce();
    expect(caughtError).not.toBeNull();
  });
});
