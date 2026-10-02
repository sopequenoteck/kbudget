import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';

import { AuthService } from './auth';
import { AuthResponse } from '../models/auth.model';
import { authInterceptor, _resetInterceptorState } from '../interceptors/auth.interceptor';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

/**
 * KKS-448 — restauration de la session au lancement.
 *
 * Ces tests passent par un vrai `HttpClient` (HttpTestingController) et le vrai
 * intercepteur : ils prouvent le nombre de POST `/auth/refresh` reellement
 * emis, ce qu'un mock d'`ApiService` ne montre pas.
 */

function createJwt(payload: Record<string, unknown>): string {
  const header = btoa(JSON.stringify({ alg: 'HS256' }));
  const body = btoa(JSON.stringify(payload))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
  return `${header}.${body}.fakesignature`;
}

const validToken = () => createJwt({ exp: Math.floor(Date.now() / 1000) + 3600 });
const expiredToken = () => createJwt({ exp: Math.floor(Date.now() / 1000) - 3600 });

const STORED_USER = { name: 'Stored User', email: 'stored@test.com', mustResetCredentials: false };

const refreshResponse = (): AuthResponse => ({
  token: validToken(),
  refreshToken: 'rotated-refresh',
  email: 'fresh@test.com',
  name: 'Fresh User',
  mustResetCredentials: false,
});

const isRefreshCall = (r: { url: string; method: string }) =>
  r.method === 'POST' && r.url.endsWith('/auth/refresh');

describe('AuthService — restauration de session (KKS-448)', () => {
  let router: { navigate: ReturnType<typeof vi.fn>; url: string };
  let httpTesting: HttpTestingController;

  /**
   * Cree le service puis laisse passer le tick du refresh de demarrage : il est
   * differe pour ne pas traverser l'intercepteur pendant la construction.
   */
  async function createService(): Promise<AuthService> {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      providers: [
        provideTranslocoTesting(),
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting(),
        { provide: Router, useValue: router },
      ],
    });
    httpTesting = TestBed.inject(HttpTestingController);
    const service = TestBed.inject(AuthService);
    await Promise.resolve();
    return service;
  }

  function prepareExpiredSession(user: unknown = STORED_USER): void {
    // `null` : aucun utilisateur memorise (`undefined` declencherait la valeur par defaut)
    localStorage.setItem('budget_token', expiredToken());
    localStorage.setItem('budget_refresh_token', 'old-refresh');
    if (user !== null) {
      localStorage.setItem('budget_user', typeof user === 'string' ? user : JSON.stringify(user));
    }
  }

  beforeEach(() => {
    localStorage.clear();
    _resetInterceptorState();
    router = { navigate: vi.fn().mockReturnValue(Promise.resolve(true)), url: '/transactions?x=1' };
    vi.spyOn(console, 'error').mockReturnValue(undefined);
    vi.spyOn(console, 'warn').mockReturnValue(undefined);
    vi.spyOn(console, 'info').mockReturnValue(undefined);
  });

  afterEach(() => {
    httpTesting.verify();
    localStorage.clear();
    vi.restoreAllMocks();
  });

  describe('session optimiste (access token expire + refresh token present)', () => {
    it('should_set_current_user_immediately_from_storage_when_access_token_is_expired', async () => {
      // Arrange
      prepareExpiredSession();

      // Act
      const service = await createService();

      // Assert — avant toute reponse du serveur : le guard laisse passer
      expect(service.currentUser()).toEqual(STORED_USER);
      expect(service.isAuthenticated()).toBe(true);
      expect(httpTesting.match(isRefreshCall)).toHaveLength(1);
    });

    it('should_update_tokens_and_user_when_background_refresh_succeeds', async () => {
      // Arrange
      prepareExpiredSession();
      const service = await createService();
      const response = refreshResponse();

      // Act
      httpTesting.expectOne(isRefreshCall).flush(response);

      // Assert
      expect(localStorage.getItem('budget_token')).toBe(response.token);
      expect(localStorage.getItem('budget_refresh_token')).toBe('rotated-refresh');
      expect(service.currentUser()).toEqual({
        name: 'Fresh User',
        email: 'fresh@test.com',
        mustResetCredentials: false,
      });
      expect(router.navigate).not.toHaveBeenCalled();
    });

    it('should_default_must_reset_credentials_to_false_when_optimistic_user_lacks_it', async () => {
      // Arrange
      prepareExpiredSession({ name: 'Legacy', email: 'legacy@test.com' });

      // Act
      const service = await createService();

      // Assert
      expect(service.currentUser()).toEqual({
        name: 'Legacy',
        email: 'legacy@test.com',
        mustResetCredentials: false,
      });
      httpTesting.match(isRefreshCall);
    });

    it('should_clear_auth_and_navigate_to_auth_with_return_url_when_refresh_returns_401', async () => {
      // Arrange
      prepareExpiredSession();
      const service = await createService();

      // Act
      httpTesting.expectOne(isRefreshCall).flush('Unauthorized', {
        status: 401,
        statusText: 'Unauthorized',
      });

      // Assert
      expect(service.currentUser()).toBeNull();
      expect(localStorage.getItem('budget_token')).toBeNull();
      expect(localStorage.getItem('budget_refresh_token')).toBeNull();
      expect(localStorage.getItem('budget_user')).toBeNull();
      expect(router.navigate).toHaveBeenCalledWith(['/auth'], {
        queryParams: { returnUrl: '/transactions?x=1' },
      });
    });

    it.each([400, 403, 404, 408])(
      'should_keep_tokens_and_user_when_refresh_returns_%i_from_a_proxy',
      async (status) => {
        // Arrange
        prepareExpiredSession();
        const service = await createService();

        // Act
        httpTesting.expectOne(isRefreshCall).flush('Proxy error', {
          status,
          statusText: 'Proxy error',
        });

        // Assert
        expect(service.currentUser()).toEqual(STORED_USER);
        expect(localStorage.getItem('budget_refresh_token')).toBe('old-refresh');
        expect(router.navigate).not.toHaveBeenCalled();
      },
    );

    it('should_navigate_to_auth_without_return_url_when_current_url_is_external_looking', async () => {
      // Arrange
      router.url = '//evil.com';
      prepareExpiredSession();
      await createService();

      // Act
      httpTesting.expectOne(isRefreshCall).flush('Unauthorized', {
        status: 401,
        statusText: 'Unauthorized',
      });

      // Assert
      expect(router.navigate).toHaveBeenCalledWith(['/auth']);
    });

    it('should_not_navigate_when_refresh_is_rejected_while_already_on_the_login_page', async () => {
      // Arrange
      router.url = '/auth?returnUrl=%2Fdashboard';
      prepareExpiredSession();
      const service = await createService();

      // Act
      httpTesting.expectOne(isRefreshCall).flush('Unauthorized', {
        status: 401,
        statusText: 'Unauthorized',
      });

      // Assert
      expect(service.currentUser()).toBeNull();
      expect(router.navigate).not.toHaveBeenCalled();
    });

    it('should_keep_tokens_and_user_when_refresh_is_rate_limited_with_429', async () => {
      // Arrange
      prepareExpiredSession();
      const service = await createService();

      // Act
      httpTesting.expectOne(isRefreshCall).flush('Too many requests', {
        status: 429,
        statusText: 'Too Many Requests',
      });

      // Assert
      expect(service.currentUser()).toEqual(STORED_USER);
      expect(localStorage.getItem('budget_refresh_token')).toBe('old-refresh');
      expect(router.navigate).not.toHaveBeenCalled();
    });

    it('should_keep_tokens_and_user_without_navigating_when_refresh_fails_with_network_error', async () => {
      // Arrange
      prepareExpiredSession();
      const service = await createService();

      // Act
      httpTesting.expectOne(isRefreshCall).error(new ProgressEvent('error'), { status: 0 });

      // Assert
      expect(service.currentUser()).toEqual(STORED_USER);
      expect(localStorage.getItem('budget_refresh_token')).toBe('old-refresh');
      expect(localStorage.getItem('budget_user')).not.toBeNull();
      expect(router.navigate).not.toHaveBeenCalled();
    });

    it('should_keep_tokens_and_user_without_navigating_when_refresh_fails_with_503', async () => {
      // Arrange
      prepareExpiredSession();
      const service = await createService();

      // Act
      httpTesting.expectOne(isRefreshCall).flush('Unavailable', {
        status: 503,
        statusText: 'Service Unavailable',
      });

      // Assert
      expect(service.currentUser()).toEqual(STORED_USER);
      expect(localStorage.getItem('budget_refresh_token')).toBe('old-refresh');
      expect(router.navigate).not.toHaveBeenCalled();
    });
  });

  describe('autres cas de lancement', () => {
    it('should_restore_user_without_refresh_when_access_token_is_valid', async () => {
      // Arrange
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem('budget_refresh_token', 'some-refresh');
      localStorage.setItem('budget_user', JSON.stringify(STORED_USER));

      // Act
      const service = await createService();

      // Assert
      expect(service.currentUser()).toEqual(STORED_USER);
      httpTesting.expectNone(isRefreshCall);
    });

    it('should_stay_disconnected_without_request_when_no_token_at_all', async () => {
      // Act
      const service = await createService();

      // Assert
      expect(service.currentUser()).toBeNull();
      httpTesting.expectNone(isRefreshCall);
      expect(router.navigate).not.toHaveBeenCalled();
    });

    it('should_not_set_optimistic_user_when_stored_user_is_missing', async () => {
      // Arrange
      prepareExpiredSession(null);

      // Act
      const service = await createService();

      // Assert — pas d'utilisateur a poser ; le refresh part quand meme
      expect(service.currentUser()).toBeNull();
      expect(httpTesting.match(isRefreshCall)).toHaveLength(1);
    });

    it('should_not_set_optimistic_user_when_stored_user_is_corrupted', async () => {
      // Arrange
      prepareExpiredSession('not-valid-json{{{');

      // Act
      const service = await createService();

      // Assert
      expect(service.currentUser()).toBeNull();
      expect(httpTesting.match(isRefreshCall)).toHaveLength(1);
    });

    it('should_restore_user_from_refresh_response_when_stored_user_is_missing', async () => {
      // Arrange
      prepareExpiredSession(null);
      const service = await createService();

      // Act
      httpTesting.expectOne(isRefreshCall).flush(refreshResponse());

      // Assert
      expect(service.currentUser()?.email).toBe('fresh@test.com');
    });
  });

  describe('un seul refresh en vol', () => {
    it('should_send_a_single_post_when_refresh_access_token_is_called_concurrently', async () => {
      // Arrange
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem('budget_refresh_token', 'old-refresh');
      localStorage.setItem('budget_user', JSON.stringify(STORED_USER));
      const service = await createService();
      const results: AuthResponse[] = [];

      // Act
      service.refreshAccessToken().subscribe((r) => results.push(r));
      service.refreshAccessToken().subscribe((r) => results.push(r));
      const response = refreshResponse();
      httpTesting.expectOne(isRefreshCall).flush(response);

      // Assert
      expect(results).toEqual([response, response]);
    });

    it('should_allow_a_new_refresh_once_the_previous_one_is_settled', async () => {
      // Arrange
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem('budget_refresh_token', 'old-refresh');
      localStorage.setItem('budget_user', JSON.stringify(STORED_USER));
      const service = await createService();

      // Act
      service.refreshAccessToken().subscribe();
      httpTesting.expectOne(isRefreshCall).flush(refreshResponse());
      service.refreshAccessToken().subscribe();

      // Assert
      httpTesting.expectOne(isRefreshCall).flush(refreshResponse());
    });

    it('should_allow_a_new_refresh_once_the_previous_one_has_failed', async () => {
      // Arrange
      localStorage.setItem('budget_token', validToken());
      localStorage.setItem('budget_refresh_token', 'old-refresh');
      localStorage.setItem('budget_user', JSON.stringify(STORED_USER));
      const service = await createService();

      // Act
      service.refreshAccessToken().subscribe({ error: () => undefined });
      httpTesting.expectOne(isRefreshCall).flush('Unavailable', {
        status: 503,
        statusText: 'Service Unavailable',
      });
      service.refreshAccessToken().subscribe({ error: () => undefined });

      // Assert
      httpTesting.expectOne(isRefreshCall).flush('Unavailable', {
        status: 503,
        statusText: 'Service Unavailable',
      });
    });

    it('should_send_one_refresh_and_replay_the_request_when_api_returns_401_during_startup_refresh', async () => {
      // Arrange — lancement avec access token expire : refresh de demarrage en vol
      prepareExpiredSession();
      await createService();
      const http = TestBed.inject(HttpClient);
      let result: unknown = null;
      const startupRefresh = httpTesting.expectOne(isRefreshCall);

      // Act — un appel API part sans jeton (expire) et prend un 401 pendant le refresh
      http.get('/api/v1/transactions').subscribe((r) => (result = r));
      httpTesting
        .expectOne('/api/v1/transactions')
        .flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

      // Assert — aucun second POST /auth/refresh : le meme refresh sert les deux
      httpTesting.expectNone(isRefreshCall);
      startupRefresh.flush(refreshResponse());
      const retry = httpTesting.expectOne('/api/v1/transactions');
      expect(retry.request.headers.get('Authorization')).toMatch(/^Bearer /);
      expect(retry.request.headers.has('_retry')).toBe(true);
      retry.flush({ data: 'ok' });
      expect(result).toEqual({ data: 'ok' });
    });
  });
});
