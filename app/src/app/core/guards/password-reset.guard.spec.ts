import { TestBed } from '@angular/core/testing';
import { Router, UrlTree } from '@angular/router';

import { AuthService } from '../services/auth';
import { passwordResetGuard } from './password-reset.guard';

describe('passwordResetGuard', () => {
  let authService: { mustResetCredentials: ReturnType<typeof vi.fn> };
  let router: { createUrlTree: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    authService = {
      mustResetCredentials: vi.fn(),
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

  function runGuard(): boolean | UrlTree {
    return TestBed.runInInjectionContext(() => passwordResetGuard({} as never, {} as never));
  }

  it('should_redirect_to_first_login_reset_when_flag_true', () => {
    // Arrange
    authService.mustResetCredentials.mockReturnValue(true);

    // Act
    const result = runGuard();

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/first-login-reset']);
    expect(result).toEqual({});
  });

  it('should_return_true_when_flag_false', () => {
    // Arrange
    authService.mustResetCredentials.mockReturnValue(false);

    // Act
    const result = runGuard();

    // Assert
    expect(result).toBe(true);
    expect(router.createUrlTree).not.toHaveBeenCalled();
  });
});
