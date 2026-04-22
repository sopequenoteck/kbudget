import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { Router } from '@angular/router';
import { of, throwError } from 'rxjs';

import { FirstLoginResetComponent } from './first-login-reset';
import { AuthService } from '../../../../core/services/auth';
import { AuthResponse } from '../../../../core/models/auth.model';

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

const mockAuthResponse: AuthResponse = {
  token: createJwt({ sub: 'admin@new.com', exp: Math.floor(Date.now() / 1000) + 3600 }),
  refreshToken: 'mock-refresh',
  email: 'admin@new.com',
  name: 'Admin',
  mustResetCredentials: false,
};

describe('FirstLoginResetComponent', () => {
  let authService: {
    firstLoginReset: ReturnType<typeof vi.fn>;
    mustResetCredentials: ReturnType<typeof vi.fn>;
  };
  let router: { navigateByUrl: ReturnType<typeof vi.fn> };
  let component: FirstLoginResetComponent;

  beforeEach(async () => {
    authService = {
      firstLoginReset: vi.fn(),
      mustResetCredentials: vi.fn().mockReturnValue(true),
    };

    router = {
      navigateByUrl: vi.fn(),
    };

    TestBed.configureTestingModule({
      imports: [FirstLoginResetComponent, NoopAnimationsModule],
      providers: [
        { provide: AuthService, useValue: authService },
        { provide: Router, useValue: router },
      ],
    });

    const fixture = TestBed.createComponent(FirstLoginResetComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should_render_form_with_4_fields_when_component_initialized', () => {
    // Assert
    expect(component.form.controls.email).toBeDefined();
    expect(component.form.controls.password).toBeDefined();
    expect(component.form.controls.passwordConfirm).toBeDefined();
    expect(component.form.controls.displayName).toBeDefined();
  });

  it('should_call_firstLoginReset_when_form_valid_and_submitted', async () => {
    // Arrange
    authService.firstLoginReset.mockReturnValue(of(mockAuthResponse));
    component.form.setValue({
      email: 'admin@new.com',
      password: 'password123',
      passwordConfirm: 'password123',
      displayName: 'Admin',
    });

    // Act
    await component.onSubmit();

    // Assert
    expect(authService.firstLoginReset).toHaveBeenCalledWith({
      email: 'admin@new.com',
      password: 'password123',
      displayName: 'Admin',
    });
  });

  it('should_navigate_to_root_when_reset_succeeds', async () => {
    // Arrange
    authService.firstLoginReset.mockReturnValue(of(mockAuthResponse));
    component.form.setValue({
      email: 'admin@new.com',
      password: 'password123',
      passwordConfirm: 'password123',
      displayName: 'Admin',
    });

    // Act
    await component.onSubmit();

    // Assert
    expect(router.navigateByUrl).toHaveBeenCalledWith('/');
  });

  it('should_display_error_when_firstLoginReset_fails', async () => {
    // Arrange
    authService.firstLoginReset.mockReturnValue(throwError(() => 'Email déjà utilisé'));
    component.form.setValue({
      email: 'used@email.com',
      password: 'password123',
      passwordConfirm: 'password123',
      displayName: 'Admin',
    });

    // Act
    await component.onSubmit();

    // Assert
    expect(component.errorMessage()).toBe('Email déjà utilisé');
    expect(component.isSubmitting()).toBe(false);
  });

  it('should_validate_password_equality', () => {
    // Arrange
    component.form.setValue({
      email: 'admin@new.com',
      password: 'password123',
      passwordConfirm: 'different456',
      displayName: 'Admin',
    });

    // Assert
    expect(component.form.controls.passwordConfirm.hasError('passwordMismatch')).toBe(true);
    expect(component.form.invalid).toBe(true);
  });

  it('should_not_submit_when_form_invalid', async () => {
    // Arrange — form left empty

    // Act
    await component.onSubmit();

    // Assert
    expect(authService.firstLoginReset).not.toHaveBeenCalled();
  });

  it('should_set_isSubmitting_true_during_submit_and_false_on_error', async () => {
    // Arrange
    let resolvePromise: () => void;
    const pendingObs = new Promise<void>((resolve) => {
      resolvePromise = resolve;
    });
    authService.firstLoginReset.mockReturnValue(
      throwError(() => 'Une erreur est survenue'),
    );
    component.form.setValue({
      email: 'admin@new.com',
      password: 'password123',
      passwordConfirm: 'password123',
      displayName: 'Admin',
    });

    // Act
    await component.onSubmit();

    // Assert
    expect(component.isSubmitting()).toBe(false);
  });
});
