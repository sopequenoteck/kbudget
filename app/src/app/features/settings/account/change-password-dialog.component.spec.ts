import { TestBed } from '@angular/core/testing';

import { ChangePasswordDialogComponent } from './change-password-dialog.component';
import { UserService } from '../../../core/services/user';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

describe('ChangePasswordDialogComponent', () => {
  function render() {
    TestBed.configureTestingModule({
      imports: [ChangePasswordDialogComponent],
      providers: [
        provideTranslocoTesting(),
        { provide: UserService, useValue: { changePassword: vi.fn() } },
      ],
    });

    const fixture = TestBed.createComponent(ChangePasswordDialogComponent);
    fixture.componentInstance.open();
    fixture.detectChanges();
    return fixture;
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
});
