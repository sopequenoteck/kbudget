import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import {
  ReactiveFormsModule,
  FormBuilder,
  Validators,
  AbstractControl,
  ValidationErrors,
} from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { AuthService } from '../../core/services/auth';
import { FormField } from '../../shared/components/form-field/form-field';

@Component({
  selector: 'app-auth',
  imports: [ReactiveFormsModule, FormField],
  templateUrl: './auth.html',
  styleUrl: './auth.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Auth {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);

  readonly mode = signal<'login' | 'register'>('login');
  readonly loading = signal(false);
  readonly errorMessage = signal('');

  readonly loginForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  readonly currencies = [
    { code: 'EUR', label: '€ - Euro' },
    { code: 'XOF', label: 'CFA - Franc CFA (BCEAO)' },
    { code: 'USD', label: '$ - Dollar américain' },
    { code: 'GBP', label: '£ - Livre sterling' },
    { code: 'CHF', label: 'CHF - Franc suisse' },
    { code: 'CAD', label: 'CA$ - Dollar canadien' },
    { code: 'MAD', label: 'MAD - Dirham marocain' },
  ];

  readonly registerForm = this.fb.nonNullable.group(
    {
      name: [''],
      currency: ['EUR'],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', [Validators.required]],
    },
    { validators: [this.passwordMatchValidator] },
  );

  toggleMode(): void {
    this.mode.update((m) => (m === 'login' ? 'register' : 'login'));
    this.loginForm.reset();
    this.registerForm.reset();
    this.errorMessage.set('');
  }

  async onLogin(): Promise<void> {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    this.loading.set(true);
    this.errorMessage.set('');

    const { email, password } = this.loginForm.getRawValue();

    try {
      await firstValueFrom(this.authService.login({ email, password }));
      const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl') || '/';
      this.router.navigateByUrl(returnUrl);
    } catch (message) {
      this.errorMessage.set(message as string);
      this.loading.set(false);
    }
  }

  async onRegister(): Promise<void> {
    if (this.registerForm.invalid) {
      this.registerForm.markAllAsTouched();
      return;
    }

    this.loading.set(true);
    this.errorMessage.set('');

    const { name, currency, email, password } = this.registerForm.getRawValue();

    let timezone = 'Europe/Paris';
    try {
      timezone = Intl.DateTimeFormat().resolvedOptions().timeZone || 'Europe/Paris';
    } catch {
      timezone = 'Europe/Paris';
    }

    try {
      await firstValueFrom(this.authService.register({ name: name || undefined, currency, email, password, timezone }));
      this.router.navigateByUrl('/');
    } catch (message) {
      this.errorMessage.set(message as string);
      this.loading.set(false);
    }
  }

  private passwordMatchValidator(control: AbstractControl): ValidationErrors | null {
    const password = control.get('password')?.value;
    const confirmPassword = control.get('confirmPassword')?.value;
    if (password && confirmPassword && password !== confirmPassword) {
      return { passwordMismatch: true };
    }
    return null;
  }
}
