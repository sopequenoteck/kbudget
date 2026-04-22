import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { AuthService } from '../../core/services/auth';
import { FormField } from '../../shared/components/form-field/form-field';
import { AuthShell } from './components/auth-shell/auth-shell';

@Component({
  selector: 'app-auth',
  standalone: true,
  imports: [ReactiveFormsModule, FormField, AuthShell],
  templateUrl: './auth.html',
  styleUrl: './auth.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Auth {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);

  readonly loading = signal(false);
  readonly errorMessage = signal('');

  readonly loginForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

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
      if (this.authService.mustResetCredentials()) {
        this.router.navigateByUrl('/first-login-reset');
      } else {
        const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl') || '/';
        this.router.navigateByUrl(returnUrl);
      }
    } catch (message) {
      this.errorMessage.set(message as string);
      this.loading.set(false);
    }
  }
}
