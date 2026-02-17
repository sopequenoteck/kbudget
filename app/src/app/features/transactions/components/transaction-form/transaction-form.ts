import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  input,
  output,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';

import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { FormField } from '../../../../shared/components/form-field/form-field';
import { CategoryPicker } from '../../../../shared/components/category-picker/category-picker';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';
import { SelectPickerItem } from '../../../../shared/components/select-picker/select-picker.model';
import { AccountService } from '../../../../core/services/account';
import { Account } from '../../../../core/models/account.model';
import {
  Transaction,
  TransactionRequest,
  TransactionType,
} from '../../../../core/models/transaction.model';

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

  readonly transaction = input<Transaction | null>(null);
  readonly type = input(TransactionType.DEPENSE);
  readonly saved = output<TransactionRequest>();
  readonly cancelled = output<void>();
  readonly deleted = output<string>();

  readonly isEditMode = computed(() => this.transaction() !== null);

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
      secondaryText: `${a.solde.toFixed(2)} \u20AC`,
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

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

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

    this.saved.emit(request);
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  onDelete(): void {
    this.deleted.emit(this.transaction()!.id);
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
