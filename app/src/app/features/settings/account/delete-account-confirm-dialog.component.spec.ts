import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

import { DeleteAccountConfirmDialogComponent } from './delete-account-confirm-dialog.component';
import { UserService } from '../../../core/services/user';
import { AuthService } from '../../../core/services/auth';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';
import { goBack, resetHistory } from '../../../../testing/history-testing';
import en from '../../../../../public/i18n/en.json';
import fr from '../../../../../public/i18n/fr.json';

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
        provideTranslocoTesting(),
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

    it('should_set_generic_error_message_when_401_with_an_unknown_code', async () => {
      setup();
      const error = new HttpErrorResponse({
        status: 401,
        error: { error: 'OTHER' },
      });
      userServiceMock.deleteAccount.mockReturnValue(throwError(() => error));

      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: 'MonMdpSecurisé123', confirmed: true });

      await component.onSubmit();

      expect(component.errorMessage()).toBe('Une erreur est survenue. Veuillez réessayer.');
      expect(authServiceMock.logout).not.toHaveBeenCalled();
    });

    it('should_set_action_not_allowed_message_when_403_with_an_unknown_code', async () => {
      setup();
      const error = new HttpErrorResponse({
        status: 403,
        error: { error: 'OTHER' },
      });
      userServiceMock.deleteAccount.mockReturnValue(throwError(() => error));

      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.form.patchValue({ currentPassword: 'MonMdpSecurisé123', confirmed: true });

      await component.onSubmit();

      expect(component.errorMessage()).toBe('Action non autorisée.');
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

  describe('textes (KKS-417)', () => {
    it('should_state_that_data_is_kept_and_not_announce_an_erasure_when_dialog_is_open', () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      void fixture.componentInstance.open();
      fixture.detectChanges();

      const text = (fixture.nativeElement as HTMLElement).textContent ?? '';

      expect(text).toContain('Vous ne pourrez plus vous connecter.');
      expect(text).toContain('pas effacées');
      expect(text).toContain('elles restent sur cette instance');
      expect(text).toContain('un administrateur peut réactiver votre accès');
      expect(text).toContain('Je comprends que je ne pourrai plus me connecter');
      expect(text).not.toMatch(/irréversible|définitiv|supprimés/i);
    });

    it('should_not_announce_an_erasure_when_reading_the_deletion_keys_of_both_catalogues', () => {
      const keys = [
        (c: typeof en) => c.users.dialog.deleteAccountMessage,
        (c: typeof en) => c.users.form.deleteAccountConfirm,
        (c: typeof en) => c.users.list.deleteAccountHint,
      ];

      for (const catalogue of [en, fr]) {
        for (const read of keys) {
          expect(read(catalogue)).not.toMatch(/irreversible|irréversible|permanent|définitiv/i);
        }
      }
      expect(en.users.dialog.deleteAccountMessage).toContain('<strong>not erased</strong>');
      expect(fr.users.dialog.deleteAccountMessage).toContain('<strong>pas effacées</strong>');
    });

    it('should_render_the_not_erased_emphasis_when_dialog_is_open', () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      void fixture.componentInstance.open();
      fixture.detectChanges();

      const strong = (fixture.nativeElement as HTMLElement).querySelector('.dacd-warning strong');

      expect(strong?.textContent).toBe('pas effacées');
    });
  });

  describe('retour arriere (KKS-447)', () => {
    beforeEach(resetHistory);

    it('should_resolve_false_when_back_is_pressed_while_open', async () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      const answer = fixture.componentInstance.open();
      fixture.detectChanges();

      await goBack();

      expect(await answer).toBe(false);
    });

    it('should_stay_open_when_back_is_pressed_during_the_deletion', async () => {
      setup();
      const fixture = TestBed.createComponent(DeleteAccountConfirmDialogComponent);
      const answer = fixture.componentInstance.open();
      fixture.detectChanges();
      fixture.componentInstance.isSubmitting.set(true);

      await goBack();
      const stayedOpen = fixture.componentInstance.isOpen();
      fixture.componentInstance.isSubmitting.set(false);
      fixture.componentInstance.onCancel();

      expect(stayedOpen).toBe(true);
      expect(await answer).toBe(false);
    });
  });
});
