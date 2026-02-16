import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  isDevMode,
  output,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import {
  AbstractControl,
  FormBuilder,
  ReactiveFormsModule,
  ValidationErrors,
  Validators,
} from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { DecimalPipe } from '@angular/common';

import { FormField } from '../form-field/form-field';
import { AccountService } from '../../../core/services/account';
import { Account, TransferRequest, TransferResponse } from '../../../core/models/account.model';

@Component({
  selector: 'app-transfer-form',
  imports: [ReactiveFormsModule, FormField, DecimalPipe],
  templateUrl: './transfer-form.html',
  styleUrl: './transfer-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TransferForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);

  readonly saved = output<TransferResponse>();
  readonly cancelled = output<void>();

  private readonly allAccounts = toSignal(this.accountService.getAll(), {
    initialValue: [] as Account[],
  });

  readonly activeAccounts = computed(() => this.allAccounts().filter((a) => a.actif));
  readonly hasEnoughAccounts = computed(() => this.activeAccounts().length >= 2);

  readonly submitting = signal(false);
  readonly errorMessage = signal('');

  readonly form = this.fb.nonNullable.group(
    {
      fromAccountId: ['', [Validators.required]],
      toAccountId: ['', [Validators.required]],
      montant: ['', [Validators.required, Validators.min(0.01)]],
      note: ['', [Validators.maxLength(500)]],
    },
    { validators: [TransferForm.differentAccountsValidator] },
  );

  static differentAccountsValidator(control: AbstractControl): ValidationErrors | null {
    const from = control.get('fromAccountId')?.value;
    const to = control.get('toAccountId')?.value;
    if (from && to && from === to) {
      return { sameAccount: true };
    }
    return null;
  }

  getAccountName(id: string): string {
    return this.activeAccounts().find((a) => a.id === id)?.nom ?? '';
  }

  getAccountIcon(id: string): string {
    return this.activeAccounts().find((a) => a.id === id)?.icone ?? '';
  }

  getAccountSolde(id: string): number {
    return this.activeAccounts().find((a) => a.id === id)?.solde ?? 0;
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const request: TransferRequest = {
      fromAccountId: raw.fromAccountId,
      toAccountId: raw.toAccountId,
      montant: Number(raw.montant),
      note: raw.note || undefined,
    };

    try {
      const result = await firstValueFrom(this.accountService.transfer(request));
      this.saved.emit(result);
    } catch (err: unknown) {
      const httpErr = err as { error?: { message?: string } };
      const message = httpErr?.error?.message ?? 'Erreur lors du virement';
      this.errorMessage.set(message);
      if (isDevMode()) {
        console.error('Transfer failed:', err);
      }
    } finally {
      this.submitting.set(false);
    }
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
