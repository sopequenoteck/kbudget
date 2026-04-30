import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of, throwError } from 'rxjs';
import { firstValueFrom } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

import { UserService } from './user';
import { ApiService } from './api';
import { AuthService } from './auth';
import { DeleteAccountRequest } from '../models/delete-account-request.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

describe('UserService', () => {
  let service: UserService;
  let apiService: { delete: ReturnType<typeof vi.fn>; deleteWithBody: ReturnType<typeof vi.fn>; get: ReturnType<typeof vi.fn>; post: ReturnType<typeof vi.fn>; put: ReturnType<typeof vi.fn> };
  let authService: { saveAuthResponse: ReturnType<typeof vi.fn>; patchUserInfo: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
      deleteWithBody: vi.fn(),
    };

    authService = {
      saveAuthResponse: vi.fn(),
      patchUserInfo: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [
        UserService,
        { provide: ApiService, useValue: apiService },
        { provide: AuthService, useValue: authService },
      ],
    });

    service = TestBed.inject(UserService);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('deleteAccount()', () => {
    const req: DeleteAccountRequest = {
      currentPassword: 'MonMdpSecurisé123',
      confirmed: true,
    };

    it('should_call_DELETE_users_me_with_body_when_deleteAccount_called', async () => {
      apiService.deleteWithBody.mockReturnValue(of(undefined));

      await firstValueFrom(service.deleteAccount(req));

      expect(apiService.deleteWithBody).toHaveBeenCalledWith('/users/me', req);
    });

    it('should_complete_without_error_when_server_returns_204', async () => {
      apiService.deleteWithBody.mockReturnValue(of(undefined));

      await expect(firstValueFrom(service.deleteAccount(req))).resolves.toBeUndefined();
    });

    it('should_propagate_401_error_when_password_is_incorrect', async () => {
      const error = new HttpErrorResponse({
        status: 401,
        error: { error: 'PASSWORD_INCORRECT' },
      });
      apiService.deleteWithBody.mockReturnValue(throwError(() => error));

      await expect(firstValueFrom(service.deleteAccount(req))).rejects.toMatchObject({ status: 401 });
    });

    it('should_propagate_403_error_when_last_admin_deletion_forbidden', async () => {
      const error = new HttpErrorResponse({
        status: 403,
        error: { error: 'LAST_ADMIN_DELETION_FORBIDDEN' },
      });
      apiService.deleteWithBody.mockReturnValue(throwError(() => error));

      await expect(firstValueFrom(service.deleteAccount(req))).rejects.toMatchObject({ status: 403 });
    });
  });
});
