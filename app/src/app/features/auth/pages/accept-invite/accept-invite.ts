import { ChangeDetectionStrategy, Component, OnInit, inject, input, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { provideIcons } from '@ng-icons/core';
import {
  phosphorEnvelope,
  phosphorLock,
  phosphorUser,
  phosphorCoin,
  phosphorGlobe,
} from '@ng-icons/phosphor-icons/regular';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';

import { InvitationService } from '../../../../core/services/invitation.service';
import { AuthService } from '../../../../core/services/auth';
import { ApiErrorService } from '../../../../core/services/api-error';
import { FormField } from '../../../../shared/components/form-field/form-field';
import { AuthShell } from '../../components/auth-shell/auth-shell';
import {
  PASSWORD_MAX_LENGTH,
  PASSWORD_MIN_LENGTH,
} from '../../../../core/constants/password.constants';

@Component({
  selector: 'app-accept-invite',
  standalone: true,
  imports: [ReactiveFormsModule, FormField, AuthShell, TranslocoPipe],
  viewProviders: [
    provideIcons({ phosphorEnvelope, phosphorLock, phosphorUser, phosphorCoin, phosphorGlobe }),
  ],
  templateUrl: './accept-invite.html',
  styleUrl: './accept-invite.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AcceptInvite implements OnInit {
  private readonly invitationService = inject(InvitationService);
  private readonly authService = inject(AuthService);
  private readonly apiError = inject(ApiErrorService);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);
  private readonly transloco = inject(TranslocoService);

  readonly token = input.required<string>();

  readonly loading = signal(false);
  readonly email = signal<string | null>(null);
  readonly error = signal<string | null>(null);

  readonly timezones = [
    'Europe/Paris',
    'Europe/London',
    'Europe/Berlin',
    'Europe/Madrid',
    'Europe/Rome',
    'Europe/Brussels',
    'Africa/Casablanca',
    'Africa/Lome',
    'Africa/Tunis',
    'Africa/Lagos',
    'Africa/Abidjan',
    'America/New_York',
    'America/Chicago',
    'America/Los_Angeles',
    'Asia/Tokyo',
    'Asia/Shanghai',
  ];

  readonly currencies = [
    { code: 'EUR', label: '€ - Euro' },
    { code: 'XOF', label: 'CFA - Franc CFA (BCEAO)' },
    { code: 'USD', label: '$ - Dollar américain' },
    { code: 'GBP', label: '£ - Livre sterling' },
    { code: 'CHF', label: 'CHF - Franc suisse' },
    { code: 'CAD', label: 'CA$ - Dollar canadien' },
    { code: 'MAD', label: 'MAD - Dirham marocain' },
  ];

  readonly passwordMinLength = PASSWORD_MIN_LENGTH;

  readonly form = this.fb.nonNullable.group({
    password: [
      '',
      [
        Validators.required,
        Validators.minLength(PASSWORD_MIN_LENGTH),
        Validators.maxLength(PASSWORD_MAX_LENGTH),
      ],
    ],
    displayName: ['', [Validators.required, Validators.maxLength(100)]],
    currency: ['EUR', [Validators.required]],
    timezone: [this.detectTimezone(), [Validators.required]],
  });

  async ngOnInit(): Promise<void> {
    this.loading.set(true);
    try {
      const result = await firstValueFrom(this.invitationService.lookup(this.token()));
      this.email.set(result.email);
    } catch {
      this.error.set(this.transloco.translate('auth.feedback.invalidLink'));
    } finally {
      this.loading.set(false);
    }
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.loading.set(true);
    const { password, displayName, currency, timezone } = this.form.getRawValue();

    try {
      const response = await firstValueFrom(
        this.invitationService.accept({
          token: this.token(),
          password,
          displayName,
          currency,
          timezone,
        }),
      );
      // Stockage JWT via AuthService
      this.authService.saveAuthResponse(response);
      this.router.navigate(['/']);
    } catch (err: unknown) {
      const httpErr = err as { status?: number; error?: { message?: string } };
      if (httpErr?.status === 404) {
        this.error.set(this.transloco.translate('auth.feedback.invalidLink'));
      } else if (httpErr?.status === 400) {
        this.error.set(this.apiError.label(httpErr, this.transloco.translate('auth.feedback.invalidFormData')));
      } else {
        this.error.set(this.transloco.translate('auth.feedback.genericError'));
      }
      this.loading.set(false);
    }
  }

  private detectTimezone(): string {
    try {
      return Intl.DateTimeFormat().resolvedOptions().timeZone || 'Europe/Paris';
    } catch {
      return 'Europe/Paris';
    }
  }
}
