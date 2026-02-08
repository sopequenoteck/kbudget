import { getTestBed, TestBed } from '@angular/core/testing';
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting,
} from '@angular/platform-browser-dynamic/testing';
import { Router, UrlTree } from '@angular/router';

import { AuthService } from '../services/auth';
import { authGuard } from './auth.guard';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserDynamicTestingModule, platformBrowserDynamicTesting());
}

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
    return TestBed.runInInjectionContext(() =>
      authGuard({} as never, { url } as never),
    );
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
