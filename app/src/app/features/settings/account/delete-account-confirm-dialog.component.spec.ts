import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

import { DeleteAccountConfirmDialogComponent } from './delete-account-confirm-dialog.component';
import { UserService } from '../../../core/services/user';
import { AuthService } from '../../../core/services/auth';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

describe('DeleteAccountConfirmDialogComponent', () => {
  let userServiceMock: { deleteAccount: ReturnType<typeof vi.fn> };
  let authServiceMock: { logout: ReturnType<typeof vi.fn> };

  const setup = () => {
    userServiceMock = {
      deleteAccount: vi.fn().mockReturnValue(of(undefined)),
    };
    authServiceMock = {
      logout: vi.fn(),
    };

    TestBed.configureTestingModule({
      imports: [DeleteAccountConfirmDialogComponent],
      providers: [
        { provide: UserService, useValue: userServiceMock },
        { provide: AuthService, useValue: authServiceMock },
      ],
    });
  };

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('form validation', () => {
    it('should_disable_submit_when_password_is_empty_and_confirmed_is_false', () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: '', confirmed: false });

      expect(component.isSubmitDisabled).toBe(true);
    });

    it('should_disable_submit_when_password_is_set_but_confirmed_is_false', () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: 'MonMdpSecurisé123', confirmed: false });

      expect(component.isSubmitDisabled).toBe(true);
    });

    it('should_disable_submit_when_confirmed_is_true_but_password_is_empty', () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: '', confirmed: true });

      expect(component.isSubmitDisabled).toBe(true);
    });

    it('should_enable_submit_when_password_and_confirmed_are_both_set', () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: 'MonMdpSecurisé123', confirmed: true });

      expect(component.isSubmitDisabled).toBe(false);
    });
  });

  describe('onSubmit()', () => {
    it('should_call_deleteAccount_and_logout_when_submission_succeeds', async () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: 'MonMdpSecurisé123', confirmed: true });

      await component.onSubmit();

      expect(userServiceMock.deleteAccount).toHaveBeenCalledWith({
        currentPassword: 'MonMdpSecurisé123',
        confirmed: true,
      });
      expect(authServiceMock.logout).toHaveBeenCalled();
    });

    it('should_set_error_message_when_password_is_incorrect_401', async () => {
      setup();
      const error = new HttpErrorResponse({
        status: 401,
        error: { error: 'PASSWORD_INCORRECT' },
      });
      userServiceMock.deleteAccount.mockReturnValue(throwError(() => error));

      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: 'mauvaisMdp', confirmed: true });

      await component.onSubmit();

      expect(component.errorMessage()).toBe('Mot de passe incorrect.');
      expect(authServiceMock.logout).not.toHaveBeenCalled();
    });

    it('should_set_error_message_when_last_admin_deletion_forbidden_403', async () => {
      setup();
      const error = new HttpErrorResponse({
        status: 403,
        error: { error: 'LAST_ADMIN_DELETION_FORBIDDEN' },
      });
      userServiceMock.deleteAccount.mockReturnValue(throwError(() => error));

      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: 'MonMdpSecurisé123', confirmed: true });

      await component.onSubmit();

      expect(component.errorMessage()).toContain('dernier administrateur');
      expect(authServiceMock.logout).not.toHaveBeenCalled();
    });

    it('should_set_generic_error_message_when_unknown_error', async () => {
      setup();
      userServiceMock.deleteAccount.mockReturnValue(throwError(() => new Error('Unknown')));

      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: 'MonMdpSecurisé123', confirmed: true });

      await component.onSubmit();

      expect(component.errorMessage()).toBe('Erreur lors de la suppression. Veuillez réessayer.');
      expect(authServiceMock.logout).not.toHaveBeenCalled();
    });

    it('should_not_call_deleteAccount_when_submit_is_disabled', async () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      // password empty + confirmed false → disabled
      component.form.patchValue({ currentPassword: '', confirmed: false });

      await component.onSubmit();

      expect(userServiceMock.deleteAccount).not.toHaveBeenCalled();
    });
  });

  describe('open() / close', () => {
    it('should_open_dialog_and_resolve_false_when_cancelled', async () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      const promise = component.open();

      expect(component.isOpen()).toBe(true);

      component.onCancel();

      const result = await promise;
      expect(result).toBe(false);
      expect(component.isOpen()).toBe(false);
    });
  });
});
