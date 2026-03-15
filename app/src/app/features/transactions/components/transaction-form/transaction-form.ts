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
import { RecurringTransactionService } from '../../../../core/services/recurring-transaction';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { ModalService } from '../../../../core/services/modal.service';
import { Account } from '../../../../core/models/account.model';
import {
  Transaction,
  TransactionRequest,
  TransactionType,
} from '../../../../core/models/transaction.model';
import { RecurringTransactionRequest } from '../../../../core/models/recurring-transaction.model';
import { Frequency } from '../../../../core/models/subscription.model';
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
  private readonly recurringTransactionService = inject(RecurringTransactionService);
  private readonly toastService = inject(ToastService);
  private readonly modalService = inject(ModalService);

  readonly transaction = computed(() => this.modalService.editingEntity() as Transaction | null);
  readonly type = input(TransactionType.DEPENSE);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly isEditing = computed(() => this.transaction() !== null && !this.modalService.asRecurring());
  readonly submitting = signal(false);
  readonly errorMessage = signal('');

  readonly frequencyOptions: SelectPickerItem[] = [
    { id: Frequency.HEBDOMADAIRE, label: 'Hebdomadaire', icon: null, secondaryText: null, color: null },
    { id: Frequency.MENSUEL, label: 'Mensuel', icon: null, secondaryText: null, color: null },
    { id: Frequency.ANNUEL, label: 'Annuel', icon: null, secondaryText: null, color: null },
  ];

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
      iconUrl: a.bankLogoUrl ?? a.bankCustomLogo ?? null,
    })),
  );

  readonly form = this.fb.nonNullable.group({
    libelle: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    date: [new Date().toISOString().split('T')[0], [Validators.required]],
    categoryId: [''],
    note: ['', [Validators.maxLength(500)]],
    accountId: [''],
    isRecurring: [false],
    frequency: [{ value: Frequency.MENSUEL, disabled: true }],
    nextOccurrence: [{ value: '', disabled: true }],
  });

  readonly today = new Date().toISOString().split('T')[0];

  private readonly isRecurringSignal = toSignal(this.form.get('isRecurring')!.valueChanges, {
    initialValue: false,
  });

  constructor() {
    effect(() => {
      const isRecurring = this.isRecurringSignal();
      if (isRecurring) {
        this.form.get('frequency')!.enable();
        this.form.get('nextOccurrence')!.enable();
        this.form.get('date')!.disable();
      } else {
        this.form.get('frequency')!.disable();
        this.form.get('nextOccurrence')!.disable();
        this.form.get('date')!.enable();
      }
    });

    effect(() => {
      const tx = this.transaction();
      const asRecurring = this.modalService.asRecurring();

      if (asRecurring && tx) {
        this.form.patchValue({
          libelle: tx.libelle,
          montant: String(tx.montant),
          categoryId: tx.category?.id ?? '',
          note: tx.note ?? '',
          accountId: tx.account?.id ?? '',
          isRecurring: true,
          frequency: Frequency.MENSUEL,
          nextOccurrence: this.today,
        });
        this.form.get('frequency')!.enable();
        this.form.get('nextOccurrence')!.enable();
        this.form.get('date')!.disable();
      } else if (tx) {
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

    try {
      if (raw.isRecurring) {
        const request: RecurringTransactionRequest = {
          libelle: raw.libelle,
          montant: Number(raw.montant),
          type: this.type(),
          frequency: raw.frequency as Frequency,
          nextOccurrence: raw.nextOccurrence,
          categoryId: raw.categoryId || undefined,
          note: raw.note || undefined,
          accountId: raw.accountId || undefined,
        };
        await firstValueFrom(this.recurringTransactionService.create(request));
        this.toastService.success('Transaction récurrente créée');
      } else {
        const request: TransactionRequest = {
          libelle: raw.libelle,
          montant: Number(raw.montant),
          type: this.type(),
          date: raw.date,
          categoryId: raw.categoryId || undefined,
          note: raw.note || undefined,
          accountId: raw.accountId || undefined,
        };
        const tx = this.transaction();
        if (tx && !this.modalService.asRecurring()) {
          await firstValueFrom(this.transactionService.update(tx.id, request));
        } else {
          await firstValueFrom(this.transactionService.create(request));
        }
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
