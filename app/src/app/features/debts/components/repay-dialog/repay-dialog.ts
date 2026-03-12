import {
  ChangeDetectionStrategy,
  Component,
  effect,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { FormField } from '../../../../shared/components/form-field/form-field';
import { DebtService } from '../../../../core/services/debt';
import { AccountService } from '../../../../core/services/account';
import { Debt, DebtRepayRequest } from '../../../../core/models/debt.model';
import { Account } from '../../../../core/models/account.model';
import { isFieldInvalid, validateForm } from '../../../../shared/utils/form.utils';

@Component({
  selector: 'app-repay-dialog',
  imports: [ReactiveFormsModule, FormField],
  templateUrl: './repay-dialog.html',
  styleUrl: './repay-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RepayDialog {
  private readonly fb = inject(FormBuilder);
  private readonly debtService = inject(DebtService);
  private readonly accountService = inject(AccountService);

  readonly debt = input.required<Debt>();
  readonly closed = output<void>();
  readonly repaid = output<Debt>();

  readonly accounts = signal<Account[]>([]);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');

  readonly form = this.fb.nonNullable.group({
    accountId: ['', [Validators.required]],
    amount: [0, [Validators.required, Validators.min(0.01)]],
  });

  constructor() {
    this.loadAccounts();

    effect(() => {
      const d = this.debt();
      const maxAmount = d.montantRestant;
      this.form.patchValue({ amount: maxAmount });
      this.form.get('amount')!.setValidators([
        Validators.required,
        Validators.min(0.01),
        Validators.max(maxAmount),
      ]);
      this.form.get('amount')!.updateValueAndValidity();
    });
  }

  private async loadAccounts(): Promise<void> {
    try {
      const all = await firstValueFrom(this.accountService.getAll());
      const active = all.filter((a) => a.actif);
      this.accounts.set(active);

      const debtAccountId = this.debt().account?.id;
      const preselect = debtAccountId
        ? active.find((a) => a.id === debtAccountId)?.id ?? (active[0]?.id ?? '')
        : (active[0]?.id ?? '');
      this.form.patchValue({ accountId: preselect });
    } catch {
      // silently ignore — form will require manual selection
    }
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const request: DebtRepayRequest = {
      accountId: raw.accountId,
      amount: raw.amount,
    };

    try {
      const updatedDebt = await firstValueFrom(this.debtService.repay(this.debt().id, request));
      this.repaid.emit(updatedDebt);
    } catch (err: unknown) {
      this.errorMessage.set(
        err instanceof Error ? err.message : 'Erreur lors du remboursement',
      );
    } finally {
      this.submitting.set(false);
    }
  }

  onCancel(): void {
    this.closed.emit();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }
}
