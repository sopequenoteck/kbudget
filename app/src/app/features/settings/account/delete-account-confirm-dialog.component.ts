import {
  ChangeDetectionStrategy,
  Component,
  HostListener,
  inject,
  signal,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { CdkTrapFocus } from '@angular/cdk/a11y';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorX,
  phosphorWarning,
  phosphorEye,
  phosphorEyeSlash,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { UserService } from '../../../core/services/user';
import { AuthService } from '../../../core/services/auth';

@Component({
  selector: 'app-delete-account-confirm-dialog',
  standalone: true,
  imports: [ReactiveFormsModule, CdkTrapFocus, NgIcon],
  providers: [
    provideIcons({
      phosphorX,
      phosphorWarning,
      phosphorEye,
      phosphorEyeSlash,
    }),
  ],
  templateUrl: './delete-account-confirm-dialog.component.html',
  styleUrl: './delete-account-confirm-dialog.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DeleteAccountConfirmDialogComponent {
  private readonly userService = inject(UserService);
  private readonly authService = inject(AuthService);

  readonly isOpen = signal(false);
  readonly isSubmitting = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly showPassword = signal(false);

  private resolveCallback: ((result: boolean) => void) | null = null;

  readonly form = inject(FormBuilder).nonNullable.group({
    currentPassword: ['', Validators.required],
    confirmed: [false, Validators.requiredTrue],
  });

  get isSubmitDisabled(): boolean {
    const { currentPassword, confirmed } = this.form.getRawValue();
    return !currentPassword || !confirmed || this.isSubmitting();
  }

  open(): Promise<boolean> {
    this.form.reset({ currentPassword: '', confirmed: false });
    this.errorMessage.set(null);
    this.isOpen.set(true);
    return new Promise<boolean>((resolve) => {
      this.resolveCallback = resolve;
    });
  }

  private close(result: boolean): void {
    this.isOpen.set(false);
    this.resolveCallback?.(result);
    this.resolveCallback = null;
  }

  onCancel(): void {
    if (!this.isSubmitting()) {
      this.close(false);
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
    if (this.isSubmitDisabled) {
      this.form.markAllAsTouched();
      return;
    }

    const { currentPassword } = this.form.getRawValue();

    this.isSubmitting.set(true);
    this.errorMessage.set(null);

    try {
      await firstValueFrom(
        this.userService.deleteAccount({ currentPassword, confirmed: true }),
      );
      this.close(true);
      this.authService.logout();
    } catch (err: unknown) {
      const error = err as { status?: number; error?: { error?: string } };
      if (error.status === 401) {
        const code = error.error?.error;
        if (code === 'PASSWORD_INCORRECT') {
          this.errorMessage.set('Mot de passe incorrect.');
        } else {
          this.errorMessage.set('Une erreur est survenue. Veuillez réessayer.');
        }
      } else if (error.status === 403) {
        const code = error.error?.error;
        if (code === 'LAST_ADMIN_DELETION_FORBIDDEN') {
          this.errorMessage.set(
            'Vous êtes le dernier administrateur. Veuillez nommer un autre administrateur avant de supprimer votre compte.',
          );
        } else {
          this.errorMessage.set('Action non autorisée.');
        }
      } else {
        this.errorMessage.set('Erreur lors de la suppression. Veuillez réessayer.');
      }
    } finally {
      this.isSubmitting.set(false);
    }
  }

  togglePassword(): void {
    this.showPassword.set(!this.showPassword());
  }
}
