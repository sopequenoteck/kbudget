import {
  ChangeDetectionStrategy,
  Component,
  HostListener,
  inject,
  signal,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { CdkTrapFocus } from '@angular/cdk/a11y';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorX,
  phosphorLock,
  phosphorEye,
  phosphorEyeSlash,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { UserService } from '../../../core/services/user';
import { AuthResponse } from '../../../core/models/auth.model';

function passwordMatchValidator(control: AbstractControl): ValidationErrors | null {
  const form = control.parent;
  if (!form) return null;
  const newPassword = form.get('newPassword')?.value;
  return control.value === newPassword ? null : { passwordMismatch: true };
}

@Component({
  selector: 'app-change-password-dialog',
  standalone: true,
  imports: [ReactiveFormsModule, CdkTrapFocus, NgIcon],
  providers: [
    provideIcons({
      phosphorX,
      phosphorLock,
      phosphorEye,
      phosphorEyeSlash,
    }),
  ],
  templateUrl: './change-password-dialog.component.html',
  styleUrl: './change-password-dialog.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ChangePasswordDialogComponent {
  private readonly userService = inject(UserService);
  private readonly fb = inject(FormBuilder);

  readonly isOpen = signal(false);
  readonly isSubmitting = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly showCurrentPassword = signal(false);
  readonly showNewPassword = signal(false);
  readonly showConfirmPassword = signal(false);

  private resolveCallback: ((result: AuthResponse | null) => void) | null = null;

  readonly form = this.fb.nonNullable.group({
    currentPassword: ['', Validators.required],
    newPassword: ['', [Validators.required, Validators.minLength(12)]],
    confirmPassword: ['', [Validators.required, passwordMatchValidator]],
  });

  open(): Promise<AuthResponse | null> {
    this.form.reset();
    this.errorMessage.set(null);
    this.isOpen.set(true);
    return new Promise<AuthResponse | null>((resolve) => {
      this.resolveCallback = resolve;
    });
  }

  private close(result: AuthResponse | null): void {
    this.isOpen.set(false);
    this.resolveCallback?.(result);
    this.resolveCallback = null;
  }

  onCancel(): void {
    if (!this.isSubmitting()) {
      this.close(null);
    }
  }

  onOverlayClick(): void {
    this.onCancel();
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    if (this.isOpen()) {
      this.onCancel();
    }
  }

  async onSubmit(): Promise<void> {
    // Re-run confirm validator after newPassword change
    this.form.controls.confirmPassword.updateValueAndValidity();

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const { currentPassword, newPassword } = this.form.getRawValue();

    this.isSubmitting.set(true);
    this.errorMessage.set(null);

    try {
      const response = await firstValueFrom(
        this.userService.changePassword({ currentPassword, newPassword }),
      );
      this.close(response);
    } catch (err: unknown) {
      const error = err as { status?: number; error?: { error?: string } };
      if (error.status === 401) {
        const code = error.error?.error;
        if (code === 'PASSWORD_INCORRECT') {
          this.errorMessage.set('Mot de passe actuel incorrect.');
        } else {
          this.errorMessage.set('Une erreur est survenue. Veuillez réessayer.');
        }
      } else if (error.status === 400) {
        const code = error.error?.error;
        if (code === 'PASSWORD_UNCHANGED') {
          this.errorMessage.set('Le nouveau mot de passe doit être différent de l\'actuel.');
        } else {
          this.errorMessage.set('Données invalides. Veuillez vérifier les champs.');
        }
      } else {
        this.errorMessage.set('Une erreur est survenue. Veuillez réessayer.');
      }
    } finally {
      this.isSubmitting.set(false);
    }
  }

  toggleCurrentPassword(): void {
    this.showCurrentPassword.set(!this.showCurrentPassword());
  }

  toggleNewPassword(): void {
    this.showNewPassword.set(!this.showNewPassword());
  }

  toggleConfirmPassword(): void {
    this.showConfirmPassword.set(!this.showConfirmPassword());
  }
}
