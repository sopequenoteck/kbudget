import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { ActivatedRoute, Router } from '@angular/router';
import { of } from 'rxjs';

import { Auth } from './auth';
import { AuthService } from '../../core/services/auth';
import { AuthResponse } from '../../core/models/auth.model';

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

const mockAuthResponseNormal: AuthResponse = {
  token: createJwt({ sub: 'user@test.com', exp: Math.floor(Date.now() / 1000) + 3600 }),
  refreshToken: 'refresh-token',
  email: 'user@test.com',
  name: 'User',
  mustResetCredentials: false,
};

const mockAuthResponseReset: AuthResponse = {
  token: createJwt({ sub: 'admin@localhost', exp: Math.floor(Date.now() / 1000) + 3600 }),
  refreshToken: 'refresh-token',
  email: 'admin@localhost',
  name: 'Admin',
  mustResetCredentials: true,
};

describe('Auth (LoginComponent)', () => {
  let authService: {
    login: ReturnType<typeof vi.fn>;
    mustResetCredentials: ReturnType<typeof vi.fn>;
  };
  let router: { navigateByUrl: ReturnType<typeof vi.fn> };
  let component: Auth;

  beforeEach(async () => {
    authService = {
      login: vi.fn(),
      mustResetCredentials: vi.fn().mockReturnValue(false),
    };

    router = {
      navigateByUrl: vi.fn(),
    };

    TestBed.configureTestingModule({
      imports: [Auth, NoopAnimationsModule],
      providers: [
        { provide: AuthService, useValue: authService },
        { provide: Router, useValue: router },
        {
          provide: ActivatedRoute,
          useValue: {
            snapshot: {
              queryParamMap: {
                get: vi.fn().mockReturnValue(null),
              },
            },
          },
        },
      ],
    });

    const fixture = TestBed.createComponent(Auth);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should_redirect_to_first_login_reset_when_must_reset_credentials_is_true_after_login', async () => {
    // Arrange
    authService.login.mockReturnValue(of(mockAuthResponseReset));
    authService.mustResetCredentials.mockReturnValue(true);
    component.loginForm.setValue({
      email: 'admin@localhost',
      password: 'generated-password',
    });

    // Act
    await component.onLogin();

    // Assert
    expect(router.navigateByUrl).toHaveBeenCalledWith('/first-login-reset');
  });

  it('should_redirect_to_return_url_when_must_reset_credentials_is_false_after_login', async () => {
    // Arrange
    authService.login.mockReturnValue(of(mockAuthResponseNormal));
    authService.mustResetCredentials.mockReturnValue(false);
    component.loginForm.setValue({
      email: 'user@test.com',
      password: 'my-password',
    });

    // Act
    await component.onLogin();

    // Assert
    expect(router.navigateByUrl).toHaveBeenCalledWith('/');
  });
});
