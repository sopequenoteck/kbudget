import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';

import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { FormField } from '../../../../shared/components/form-field/form-field';
import { CategoryPicker } from '../../../../shared/components/category-picker/category-picker';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';
import { SelectPickerItem } from '../../../../shared/components/select-picker/select-picker.model';
import { AccountService } from '../../../../core/services/account';
import { TransactionService } from '../../../../core/services/transaction';
import { ModalService } from '../../../../core/services/modal.service';
import { Account } from '../../../../core/models/account.model';
import {
  Transaction,
  TransactionRequest,
  TransactionType,
} from '../../../../core/models/transaction.model';
import { isFieldInvalid, validateForm } from '../../../../shared/utils/form.utils';

@Component({
  selector: 'app-transaction-form',
  imports: [ReactiveFormsModule, FormField, CategoryPicker, SelectPicker],
  templateUrl: './transaction-form.html',
  styleUrl: './transaction-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TransactionForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);
  private readonly transactionService = inject(TransactionService);
  private readonly modalService = inject(ModalService);

  readonly transaction = computed(() => this.modalService.editingEntity() as Transaction | null);
  readonly type = input(TransactionType.DEPENSE);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly isEditMode = computed(() => this.transaction() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');

  private readonly allAccounts = toSignal(this.accountService.getAll(), {
    initialValue: [] as Account[],
  });

  readonly activeAccounts = computed(() => this.allAccounts().filter((a) => a.actif));
  readonly hasAccounts = computed(() => this.activeAccounts().length > 0);
  readonly defaultAccount = computed(() => this.activeAccounts().find((a) => a.isDefault) ?? null);

  readonly accountItems = computed<SelectPickerItem[]>(() =>
    this.activeAccounts().map((a) => ({
      id: a.id,
      label: a.nom,
      icon: a.icone,
      secondaryText: `${a.solde.toFixed(2)} ${a.currency}`,
      color: a.couleur,
    })),
  );

  readonly form = this.fb.nonNullable.group({
    libelle: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    date: [new Date().toISOString().split('T')[0], [Validators.required]],
    categoryId: [''],
    note: ['', [Validators.maxLength(500)]],
    accountId: [''],
  });

  constructor() {
    effect(() => {
      const tx = this.transaction();
      if (tx) {
        this.form.patchValue({
          libelle: tx.libelle,
          montant: String(tx.montant),
          date: tx.date,
          categoryId: tx.category?.id ?? '',
          note: tx.note ?? '',
          accountId: tx.account?.id ?? '',
        });
      } else {
        const def = this.defaultAccount();
        if (def) {
          this.form.patchValue({ accountId: def.id });
        }
      }
    });
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const request: TransactionRequest = {
      libelle: raw.libelle,
      montant: Number(raw.montant),
      type: this.type(),
      date: raw.date,
      categoryId: raw.categoryId || undefined,
      note: raw.note || undefined,
      accountId: raw.accountId || undefined,
    };

    try {
      const tx = this.transaction();
      if (tx) {
        await firstValueFrom(this.transactionService.update(tx.id, request));
      } else {
        await firstValueFrom(this.transactionService.create(request));
      }
      this.modalService.closeModal();
      this.saved.emit();
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors de la sauvegarde');
    } finally {
      this.submitting.set(false);
    }
  }

  async onDelete(): Promise<void> {
    const tx = this.transaction();
    if (!tx) return;
    try {
      await firstValueFrom(this.transactionService.delete(tx.id));
      this.modalService.closeModal();
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors de la suppression');
    }
  }

  onCancel(): void {
    this.modalService.closeModal();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }
}
