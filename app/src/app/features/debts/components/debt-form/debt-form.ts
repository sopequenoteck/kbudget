import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  input,
  output,
  Pipe,
  PipeTransform,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCalendarBlank,
  phosphorWallet,
  phosphorHandCoins,
  phosphorTag,
  phosphorTrash,
  phosphorBell,
  phosphorToggleLeft,
  phosphorToggleRight,
} from '@ng-icons/phosphor-icons/regular';

import { CategoryPicker } from '../../../../shared/components/category-picker/category-picker';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';
import { SelectPickerItem } from '../../../../shared/components/select-picker/select-picker.model';
import { AccountService } from '../../../../core/services/account';
import { CategoryService } from '../../../../core/services/category';
import { CurrencyService } from '../../../../core/services/currency';
import { DebtService } from '../../../../core/services/debt';
import { ModalService } from '../../../../core/services/modal.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { Account } from '../../../../core/models/account.model';
import { Debt, DebtRequest, DebtType } from '../../../../core/models/debt.model';
import { isFieldInvalid, validateForm, normalizeDecimal, decimalMin } from '../../../../shared/utils/form.utils';

type ExpandableSection = 'date' | 'category' | 'account' | 'currency' | 'reminder' | null;

@Pipe({ name: 'shortDate', standalone: true })
export class ShortDatePipe implements PipeTransform {
  transform(value: string): string {
    if (!value) return '';
    const date = new Date(value + 'T00:00:00');
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diff = date.getTime() - today.getTime();
    const days = Math.round(diff / 86400000);
    if (days === 0) return "Aujourd'hui";
    if (days === -1) return 'Hier';
    if (days === 1) return 'Demain';
    return date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
  }
}

@Component({
  selector: 'app-debt-form',
  imports: [ReactiveFormsModule, CategoryPicker, SelectPicker, NgIcon, ShortDatePipe],
  providers: [
    provideIcons({
      phosphorCalendarBlank,
      phosphorWallet,
      phosphorHandCoins,
      phosphorTag,
      phosphorTrash,
      phosphorBell,
      phosphorToggleLeft,
      phosphorToggleRight,
    }),
  ],
  templateUrl: './debt-form.html',
  styleUrl: './debt-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DebtForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);
  private readonly categoryService = inject(CategoryService);
  private readonly currencyService = inject(CurrencyService);
  private readonly debtService = inject(DebtService);
  private readonly modalService = inject(ModalService);
  private readonly confirmService = inject(ConfirmService);

  readonly debt = computed(() => this.modalService.editingEntity() as Debt | null);
  readonly sens = input(DebtType.EMPRUNT);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly DebtType = DebtType;
  readonly currentSens = signal(DebtType.EMPRUNT);
  readonly isEditing = computed(() => this.debt() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');
  readonly expandedSection = signal<ExpandableSection>(null);

  readonly amountWidth = signal('2ch');

  private readonly allAccounts = toSignal(this.accountService.getAll(), {
    initialValue: [] as Account[],
  });

  readonly activeAccounts = computed(() => this.allAccounts().filter((a) => a.actif));
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

  readonly selectedAccount = computed(() => {
    const accountId = this.form.get('accountId')?.value;
    if (!accountId) return null;
    return this.activeAccounts().find((a) => a.id === accountId) ?? null;
  });

  readonly selectedAccountName = computed(() => this.selectedAccount()?.nom ?? null);
  readonly selectedAccountColor = computed(() => this.selectedAccount()?.couleur ?? null);

  readonly currencySymbol = computed(() => {
    const currency = this.selectedAccount()?.currency ?? (this.form.get('currency')?.value || 'EUR');
    return (0)
      .toLocaleString('fr-FR', { style: 'currency', currency, minimumFractionDigits: 0, maximumFractionDigits: 0 })
      .replace('0', '')
      .trim();
  });

  private readonly allCategories = toSignal(this.categoryService.getAll(), { initialValue: [] });

  readonly selectedCategory = computed(() => {
    const categoryId = this.form.get('categoryId')?.value;
    if (!categoryId) return null;
    return this.allCategories().find((c) => c.id === categoryId) ?? null;
  });

  readonly selectedCategoryName = computed(() => this.selectedCategory()?.nom ?? null);
  readonly selectedCategoryColor = computed(() => this.selectedCategory()?.couleur ?? null);

  readonly currencyItems = this.currencyService.currencyItems;
  readonly showCurrencyPicker = computed(() => !this.form.get('accountId')?.value);

  readonly form = this.fb.nonNullable.group({
    personne: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, decimalMin(0.01)]],
    date: [this.localDate(), [Validators.required]],
    rembourse: [false],
    categoryId: [''],
    currency: [''],
    accountId: [''],
    includeInBalance: [false],
    reminderDate: [''],
    reminderTime: [''],
  });

  readonly rembourse = toSignal(this.form.get('rembourse')!.valueChanges, { initialValue: false });

  private readonly reminderDateValue = toSignal(this.form.get('reminderDate')!.valueChanges, { initialValue: '' });
  readonly hasReminderDate = computed(() => !!this.reminderDateValue());

  private localDate(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  constructor() {
    this.currencyService.loadIfEmpty();

    // Largeur adaptative du montant
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d')!;
    ctx.font = 'bold 40px Inter, sans-serif';
    this.form.get('montant')!.valueChanges.subscribe((val) => {
      const text = val || '0';
      const measured = ctx.measureText(text).width;
      this.amountWidth.set(`${Math.ceil(measured) + 4}px`);
    });

    effect(() => {
      const d = this.debt();
      if (d) {
        this.currentSens.set(d.sens);
        this.form.patchValue({
          personne: d.personne,
          montant: d.montant.toFixed(2),
          date: d.date,
          rembourse: d.rembourse,
          categoryId: d.category?.id ?? '',
          currency: d.currency || '',
          accountId: d.account?.id ?? '',
          includeInBalance: d.includeInBalance,
          reminderDate: d.reminderDate ?? '',
          reminderTime: d.reminderTime ?? '',
        });
      } else {
        this.currentSens.set(this.sens());
        const def = this.defaultAccount();
        if (def) {
          this.form.patchValue({ accountId: def.id });
        }
      }
    });

    this.form.get('accountId')?.valueChanges.subscribe((accountId) => {
      if (accountId) {
        const account = this.activeAccounts().find((a) => a.id === accountId);
        if (account) {
          this.form.patchValue({ currency: account.currency, includeInBalance: true });
        }
      }
    });
  }

  toggleSection(section: ExpandableSection): void {
    this.expandedSection.update((current) => (current === section ? null : section));
  }

  onSensChange(s: DebtType): void {
    this.currentSens.set(s);
  }

  toggleRembourse(): void {
    const current = this.form.get('rembourse')?.value ?? false;
    this.form.patchValue({ rembourse: !current });
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const montant = normalizeDecimal(raw.montant);

    if (isNaN(montant) || montant < 0.01) {
      this.errorMessage.set('Montant invalide');
      this.submitting.set(false);
      return;
    }

    const request: DebtRequest = {
      personne: raw.personne,
      montant,
      sens: this.currentSens(),
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
    const currency = d.account?.currency ?? d.currency ?? 'EUR';
    const amount = d.montant.toLocaleString('fr-FR', { style: 'currency', currency });
    const ok = await this.confirmService.confirm({
      title: `${d.personne} — ${amount}`,
      message: 'Voulez-vous vraiment supprimer cette dette ?',
      confirmLabel: 'Supprimer',
      variant: 'danger',
      icon: 'phosphorHandCoins',
    });
    if (!ok) return;
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
