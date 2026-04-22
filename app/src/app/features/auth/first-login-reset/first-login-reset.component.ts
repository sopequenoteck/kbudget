import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { AbstractControl, ReactiveFormsModule, FormBuilder, ValidationErrors, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { AuthService } from '../../../core/services/auth';
import { FormField } from '../../../shared/components/form-field/form-field';

function passwordMatchValidator(control: AbstractControl): ValidationErrors | null {
  const form = control.parent;
  if (!form) return null;
  const password = form.get('password')?.value;
  return control.value === password ? null : { passwordMismatch: true };
}

@Component({
  selector: 'app-first-login-reset',
  standalone: true,
  imports: [ReactiveFormsModule, FormField],
  templateUrl: './first-login-reset.component.html',
  styleUrl: './first-login-reset.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FirstLoginResetComponent {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);

  readonly isSubmitting = signal(false);
  readonly errorMessage = signal<string | null>(null);

  readonly form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email, Validators.maxLength(255)]],
    password: ['', [Validators.required, Validators.minLength(8), Validators.maxLength(100)]],
    passwordConfirm: ['', [Validators.required, passwordMatchValidator]],
    displayName: ['', [Validators.required, Validators.maxLength(100)]],
  });

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.isSubmitting.set(true);
    this.errorMessage.set(null);

    const { email, password, displayName } = this.form.getRawValue();

    try {
      await firstValueFrom(this.authService.firstLoginReset({ email, password, displayName }));
      this.router.navigateByUrl('/');
    } catch (err) {
      this.errorMessage.set(err as string);
      this.isSubmitting.set(false);
    }
  }
}
