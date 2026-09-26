import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

import { ChangePasswordDialogComponent } from './change-password-dialog.component';
import { UserService } from '../../../core/services/user';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

describe('ChangePasswordDialogComponent', () => {
  let userServiceMock: { changePassword: ReturnType<typeof vi.fn> };

  function render() {
    userServiceMock = { changePassword: vi.fn() };

    TestBed.configureTestingModule({
      imports: [ChangePasswordDialogComponent],
      providers: [
        provideTranslocoTesting(),
        { provide: UserService, useValue: userServiceMock },
      ],
    });

    const fixture = TestBed.createComponent(ChangePasswordDialogComponent);
    fixture.componentInstance.open();
    fixture.detectChanges();
    return fixture;
  }

  function fillValidForm(fixture: ReturnType<typeof render>): void {
    fixture.componentInstance.form.setValue({
      currentPassword: 'ActuelSecurise123',
      newPassword: 'NouveauSecurise123',
      confirmPassword: 'NouveauSecurise123',
    });
  }

  it('should_render_the_password_minimum_length_message_in_french', () => {
    // La constante `PASSWORD_MIN_LENGTH` (KKS-379) alimente desormais le
    // parametre ICU de la cle `auth.form.passwordMinLength` plutot qu'un
    // texte fige — verifie que le rendu francais reste identique.
    const fixture = render();
    fixture.componentInstance.form.controls.newPassword.setValue('court1');
    fixture.componentInstance.form.controls.newPassword.markAsTouched();
    fixture.detectChanges();

    const error = fixture.nativeElement.querySelector('.cpd-error');

    expect(error?.textContent?.trim()).toBe('12 caractères minimum');
  });

  describe('onSubmit()', () => {
    it('should_close_with_the_response_when_the_password_change_succeeds', async () => {
      const fixture = render();
      const response = { accessToken: 'token', refreshToken: 'refresh' };
      userServiceMock.changePassword.mockReturnValue(of(response));
      fillValidForm(fixture);

      await fixture.componentInstance.onSubmit();

      expect(userServiceMock.changePassword).toHaveBeenCalledWith({
        currentPassword: 'ActuelSecurise123',
        newPassword: 'NouveauSecurise123',
      });
      expect(fixture.componentInstance.isOpen()).toBe(false);
    });

    it('should_not_submit_when_the_form_is_invalid', async () => {
      const fixture = render();

      await fixture.componentInstance.onSubmit();

      expect(userServiceMock.changePassword).not.toHaveBeenCalled();
      expect(fixture.componentInstance.form.controls.currentPassword.touched).toBe(true);
    });

    it('should_set_the_current_password_incorrect_message_on_401_with_PASSWORD_INCORRECT', async () => {
      const fixture = render();
      fillValidForm(fixture);
      userServiceMock.changePassword.mockReturnValue(
        throwError(() => new HttpErrorResponse({ status: 401, error: { error: 'PASSWORD_INCORRECT' } })),
      );

      await fixture.componentInstance.onSubmit();

      expect(fixture.componentInstance.errorMessage()).toBe('Mot de passe actuel incorrect.');
      expect(fixture.componentInstance.isSubmitting()).toBe(false);
    });

    it('should_set_a_generic_message_on_401_with_an_unknown_code', async () => {
      const fixture = render();
      fillValidForm(fixture);
      userServiceMock.changePassword.mockReturnValue(
        throwError(() => new HttpErrorResponse({ status: 401, error: { error: 'OTHER' } })),
      );

      await fixture.componentInstance.onSubmit();

      expect(fixture.componentInstance.errorMessage()).toBe('Une erreur est survenue. Veuillez réessayer.');
    });

    it('should_set_the_password_unchanged_message_on_400_with_PASSWORD_UNCHANGED', async () => {
      const fixture = render();
      fillValidForm(fixture);
      userServiceMock.changePassword.mockReturnValue(
        throwError(() => new HttpErrorResponse({ status: 400, error: { error: 'PASSWORD_UNCHANGED' } })),
      );

      await fixture.componentInstance.onSubmit();

      expect(fixture.componentInstance.errorMessage()).toBe(
        'Le nouveau mot de passe doit être différent de l\'actuel.',
      );
    });

    it('should_set_an_invalid_data_message_on_400_with_an_unknown_code', async () => {
      const fixture = render();
      fillValidForm(fixture);
      userServiceMock.changePassword.mockReturnValue(
        throwError(() => new HttpErrorResponse({ status: 400, error: { error: 'OTHER' } })),
      );

      await fixture.componentInstance.onSubmit();

      expect(fixture.componentInstance.errorMessage()).toBe(
        'Données invalides. Veuillez vérifier les champs.',
      );
    });

    it('should_set_a_generic_message_on_other_failures', async () => {
      const fixture = render();
      fillValidForm(fixture);
      userServiceMock.changePassword.mockReturnValue(
        throwError(() => new HttpErrorResponse({ status: 500 })),
      );

      await fixture.componentInstance.onSubmit();

      expect(fixture.componentInstance.errorMessage()).toBe('Une erreur est survenue. Veuillez réessayer.');
    });
  });

  describe('password visibility toggles', () => {
    it('should_toggle_current_new_and_confirm_password_visibility', () => {
      const fixture = render();
      const component = fixture.componentInstance;

      component.toggleCurrentPassword();
      component.toggleNewPassword();
      component.toggleConfirmPassword();

      expect(component.showCurrentPassword()).toBe(true);
      expect(component.showNewPassword()).toBe(true);
      expect(component.showConfirmPassword()).toBe(true);
    });
  });

  describe('onCancel() / onEscape() / onOverlayClick()', () => {
    it('should_close_with_null_when_cancelled', async () => {
      const fixture = render();
      const promise = fixture.componentInstance.open();

      fixture.componentInstance.onCancel();

      expect(await promise).toBeNull();
      expect(fixture.componentInstance.isOpen()).toBe(false);
    });

    it('should_not_close_while_submitting', () => {
      const fixture = render();
      fixture.componentInstance.isSubmitting.set(true);

      fixture.componentInstance.onCancel();

      expect(fixture.componentInstance.isOpen()).toBe(true);
    });

    it('should_close_on_overlay_click', async () => {
      const fixture = render();
      const promise = fixture.componentInstance.open();

      fixture.componentInstance.onOverlayClick();

      expect(await promise).toBeNull();
    });

    it('should_close_on_escape_when_open', async () => {
      const fixture = render();
      const promise = fixture.componentInstance.open();

      fixture.componentInstance.onEscape();

      expect(await promise).toBeNull();
    });
  });
});
