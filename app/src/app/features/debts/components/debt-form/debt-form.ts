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

import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { FormField } from '../../../../shared/components/form-field/form-field';
import { CategoryPicker } from '../../../../shared/components/category-picker/category-picker';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';
import { SelectPickerItem } from '../../../../shared/components/select-picker/select-picker.model';
import { CurrencyService } from '../../../../core/services/currency';
import { DebtService } from '../../../../core/services/debt';
import { ModalService } from '../../../../core/services/modal.service';
import { AccountService } from '../../../../core/services/account';
import { Account } from '../../../../core/models/account.model';
import { Debt, DebtRequest, DebtType } from '../../../../core/models/debt.model';
import { isFieldInvalid, validateForm } from '../../../../shared/utils/form.utils';

@Component({
  selector: 'app-debt-form',
  imports: [ReactiveFormsModule, FormField, CategoryPicker, SelectPicker],
  templateUrl: './debt-form.html',
  styleUrl: './debt-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DebtForm {
  private readonly fb = inject(FormBuilder);
  private readonly currencyService = inject(CurrencyService);
  private readonly debtService = inject(DebtService);
  private readonly modalService = inject(ModalService);
  private readonly accountService = inject(AccountService);

  readonly debt = computed(() => this.modalService.editingEntity() as Debt | null);
  readonly sens = input(DebtType.EMPRUNT);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly isEditMode = computed(() => this.debt() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');

  readonly currencyItems = this.currencyService.currencyItems;

  private readonly accounts = signal<Account[]>([]);

  readonly accountItems = computed<SelectPickerItem[]>(() =>
    this.accounts().map((a) => ({
      id: a.id,
      label: a.nom,
      icon: a.icone,
      secondaryText: null,
      color: a.couleur,
    })),
  );

  readonly form = this.fb.nonNullable.group({
    personne: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    date: [new Date().toISOString().split('T')[0], [Validators.required]],
    rembourse: [false],
    categoryId: [''],
    currency: [''],
    accountId: [''],
    includeInBalance: [false],
    reminderDate: [''],
    reminderTime: [''],
  });

  readonly selectedCurrency = computed(() => this.form.get('currency')?.value || 'EUR');

  readonly hasAccount = computed(() => !!this.form.get('accountId')?.value);

  readonly hasReminderDate = computed(() => !!this.form.get('reminderDate')?.value);

  constructor() {
    this.currencyService.loadIfEmpty();

    firstValueFrom(this.accountService.getAll()).then((accounts) => {
      this.accounts.set(accounts.filter((a) => a.actif));
    });

    effect(() => {
      const d = this.debt();
      if (d) {
        this.form.patchValue({
          personne: d.personne,
          montant: String(d.montant),
          date: d.date,
          rembourse: d.rembourse,
          categoryId: d.category?.id ?? '',
          currency: d.currency || '',
          accountId: d.account?.id ?? '',
          includeInBalance: d.includeInBalance,
          reminderDate: d.reminderDate ?? '',
          reminderTime: d.reminderTime ?? '',
        });
      }
    });

    this.form.get('accountId')?.valueChanges.subscribe((accountId) => {
      if (accountId) {
        const account = this.accounts().find((a) => a.id === accountId);
        if (account) {
          this.form.patchValue({ currency: account.currency, includeInBalance: true });
        }
      }
    });
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const request: DebtRequest = {
      personne: raw.personne,
      montant: Number(raw.montant),
      sens: this.sens(),
      date: raw.date,
      rembourse: raw.rembourse,
      categoryId: raw.categoryId || undefined,
      currency: raw.currency || undefined,
      accountId: raw.accountId || null,
      includeInBalance: raw.includeInBalance,
      reminderDate: raw.reminderDate || null,
      reminderTime: raw.reminderDate ? (raw.reminderTime || '09:00') : null,
    };

    try {
      const d = this.debt();
      if (d) {
        await firstValueFrom(this.debtService.update(d.id, request));
      } else {
        await firstValueFrom(this.debtService.create(request));
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
    const d = this.debt();
    if (!d) return;
    try {
      await firstValueFrom(this.debtService.delete(d.id));
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
