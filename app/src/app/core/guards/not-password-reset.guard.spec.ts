import { TestBed } from '@angular/core/testing';
import { Router, UrlTree } from '@angular/router';

import { AuthService } from '../services/auth';
import { notPasswordResetGuard } from './not-password-reset.guard';

describe('notPasswordResetGuard', () => {
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
    return TestBed.runInInjectionContext(() => notPasswordResetGuard({} as never, {} as never));
  }

  it('should_return_true_when_flag_true', () => {
    // Arrange
    authService.mustResetCredentials.mockReturnValue(true);

    // Act
    const result = runGuard();

    // Assert
    expect(result).toBe(true);
    expect(router.createUrlTree).not.toHaveBeenCalled();
  });

  it('should_redirect_to_root_when_flag_false', () => {
    // Arrange
    authService.mustResetCredentials.mockReturnValue(false);

    // Act
    const result = runGuard();

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/']);
    expect(result).toEqual({});
  });
});
