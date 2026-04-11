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

import { FormField } from '../form-field/form-field';
import { SelectPicker } from '../select-picker/select-picker';
import { SelectPickerItem } from '../select-picker/select-picker.model';
import { AccountService } from '../../../core/services/account';
import { TransactionService } from '../../../core/services/transaction';
import { ModalService } from '../../../core/services/modal.service';
import { Account, TransferRequest } from '../../../core/models/account.model';
import { isFieldInvalid, validateForm } from '../../utils/form.utils';

@Component({
  selector: 'app-transfer-form',
  standalone: true,
  imports: [ReactiveFormsModule, FormField, SelectPicker],
  templateUrl: './transfer-form.html',
  styleUrl: './transfer-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TransferForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);
  private readonly transactionService = inject(TransactionService);
  private readonly modalService = inject(ModalService);

  readonly saved = output<void>();
  readonly cancelled = output<void>();

  private readonly allAccounts = toSignal(this.accountService.getAll(), {
    initialValue: [] as Account[],
  });

  readonly activeAccounts = computed(() => this.allAccounts().filter((a) => a.actif));
  readonly hasEnoughAccounts = computed(() => this.activeAccounts().length >= 2);

  readonly accountItems = computed<SelectPickerItem[]>(() =>
    this.activeAccounts().map((a) => ({
      id: a.id,
      label: a.nom,
      icon: a.icone,
      secondaryText: `${a.solde.toFixed(2)} ${a.currency}`,
      color: a.couleur,
      iconUrl: a.bankLogoUrl ?? a.bankCustomLogo ?? null,
    })),
  );

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

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

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
      await firstValueFrom(this.accountService.transfer(request));
      this.transactionService.refreshTrigger.update((v) => v + 1);
      this.modalService.closeModal();
      this.saved.emit();
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
    this.modalService.closeModal();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }
}
