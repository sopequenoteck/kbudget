import { TestBed } from '@angular/core/testing';
import { Router, UrlTree } from '@angular/router';
import { Subject } from 'rxjs';

import { AuthService } from '../services/auth';
import { ApiService } from '../services/api';
import { AuthResponse } from '../models/auth.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';
import { authGuard } from './auth.guard';

describe('authGuard', () => {
  let authService: { isAuthenticated: ReturnType<typeof vi.fn> };
  let router: { createUrlTree: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    authService = {
      isAuthenticated: vi.fn(),
    };

    const mockUrlTree = {} as UrlTree;
    router = {
      createUrlTree: vi.fn().mockReturnValue(mockUrlTree),
    };

    TestBed.configureTestingModule({
      providers: [
        { provide: AuthService, useValue: authService },
        { provide: Router, useValue: router },
      ],
    });
  });

  function runGuard(url: string): boolean | UrlTree {
    return TestBed.runInInjectionContext(() => authGuard({} as never, { url } as never));
  }

  it('should_allow_access_when_authenticated', () => {
    // Arrange
    authService.isAuthenticated.mockReturnValue(true);

    // Act
    const result = runGuard('/dashboard');

    // Assert
    expect(result).toBe(true);
  });

  it('should_redirect_to_auth_when_not_authenticated', () => {
    // Arrange
    authService.isAuthenticated.mockReturnValue(false);

    // Act
    runGuard('/dashboard');

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/auth'], {
      queryParams: { returnUrl: '/dashboard' },
    });
  });

  it('should_include_returnUrl_when_redirecting', () => {
    // Arrange
    authService.isAuthenticated.mockReturnValue(false);

    // Act
    runGuard('/transactions');

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/auth'], {
      queryParams: { returnUrl: '/transactions' },
    });
  });

  it('should_reject_external_returnUrl_http', () => {
    // Arrange
    authService.isAuthenticated.mockReturnValue(false);

    // Act
    runGuard('http://evil.com');

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/auth']);
  });

  it('should_reject_external_returnUrl_https', () => {
    // Arrange
    authService.isAuthenticated.mockReturnValue(false);

    // Act
    runGuard('https://evil.com');

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/auth']);
  });

  it('should_reject_external_returnUrl_protocol_relative', () => {
    // Arrange
    authService.isAuthenticated.mockReturnValue(false);

    // Act
    runGuard('//evil.com');

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/auth']);
  });

  it('should_redirect_when_token_expired', () => {
    // Arrange
    authService.isAuthenticated.mockReturnValue(false);

    // Act
    runGuard('/debts');

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/auth'], {
      queryParams: { returnUrl: '/debts' },
    });
  });
});

describe('authGuard — session optimiste (KKS-448)', () => {
  afterEach(() => {
    localStorage.clear();
  });

  it('should_allow_access_without_redirect_when_refresh_is_pending_at_launch', async () => {
    // Arrange — access token expire, refresh token et utilisateur memorises,
    // refresh de demarrage jamais termine
    const header = btoa(JSON.stringify({ alg: 'HS256' }));
    const body = btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) - 3600 }))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
    localStorage.setItem('budget_token', `${header}.${body}.sig`);
    localStorage.setItem('budget_refresh_token', 'valid-refresh');
    localStorage.setItem(
      'budget_user',
      JSON.stringify({ name: 'Stored', email: 'stored@test.com', mustResetCredentials: false }),
    );
    vi.spyOn(console, 'error').mockReturnValue(undefined);
    const router = { navigate: vi.fn(), createUrlTree: vi.fn() };
    TestBed.configureTestingModule({
      providers: [
        provideTranslocoTesting(),
        {
          provide: ApiService,
          useValue: { post: vi.fn().mockReturnValue(new Subject<AuthResponse>()) },
        },
        { provide: Router, useValue: router },
      ],
    });
    TestBed.inject(AuthService);
    await Promise.resolve();

    // Act
    const result = TestBed.runInInjectionContext(() =>
      authGuard({} as never, { url: '/transactions' } as never),
    );

    // Assert
    expect(result).toBe(true);
    expect(router.createUrlTree).not.toHaveBeenCalled();
  });
});
