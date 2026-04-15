import {
  ChangeDetectionStrategy,
  Component,
  computed,
  DestroyRef,
  effect,
  ElementRef,
  inject,
  input,
  output,
  Pipe,
  PipeTransform,
  Signal,
  signal,
  viewChild,
} from '@angular/core';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCalendarBlank,
  phosphorWallet,
  phosphorRepeat,
  phosphorNoteBlank,
  phosphorTag,
  phosphorTrash,
  phosphorReceipt,
} from '@ng-icons/phosphor-icons/regular';

import { Autocomplete } from '../../../../shared/components/autocomplete/autocomplete';
import { CategoryPicker } from '../../../../shared/components/category-picker/category-picker';
import { InlineDatePicker } from '../../../../shared/components/inline-date-picker/inline-date-picker';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';
import { SelectPickerItem } from '../../../../shared/components/select-picker/select-picker.model';
import { AccountService } from '../../../../core/services/account';
import { CategoryService } from '../../../../core/services/category';
import { TransactionService } from '../../../../core/services/transaction';
import { TransactionLibelleService } from '../../services/transaction-libelle.service';
import { RecurringTransactionService } from '../../../../core/services/recurring-transaction';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { ModalService } from '../../../../core/services/modal.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { Account } from '../../../../core/models/account.model';
import {
  Transaction,
  TransactionRequest,
  TransactionType,
} from '../../../../core/models/transaction.model';
import { RecurringTransactionRequest } from '../../../../core/models/recurring-transaction.model';
import { Frequency } from '../../../../core/models/subscription.model';
import { isFieldInvalid, validateForm, normalizeDecimal, decimalMin } from '../../../../shared/utils/form.utils';
import { createAmountWidth } from '../../../../shared/utils/amount-width.utils';
import { expandCollapse } from '../../../../shared/animations/expand-collapse';
import { APP_LOCALE } from '../../../../core/constants/locale.constants';

type ExpandableSection = 'category' | 'date' | 'account' | 'recurring' | 'note' | null;

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
    return date.toLocaleDateString(APP_LOCALE, { day: 'numeric', month: 'short' });
  }
}

@Component({
  selector: 'app-transaction-form',
  imports: [ReactiveFormsModule, Autocomplete, CategoryPicker, InlineDatePicker, SelectPicker, NgIcon, ShortDatePipe],
  providers: [
    provideIcons({
      phosphorCalendarBlank,
      phosphorWallet,
      phosphorRepeat,
      phosphorNoteBlank,
      phosphorTag,
      phosphorTrash,
      phosphorReceipt,
    }),
  ],
  templateUrl: './transaction-form.html',
  styleUrl: './transaction-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [expandCollapse],
})
export class TransactionForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);
  private readonly categoryService = inject(CategoryService);
  private readonly transactionService = inject(TransactionService);
  private readonly recurringTransactionService = inject(RecurringTransactionService);
  private readonly libelleService = inject(TransactionLibelleService);
  private readonly toastService = inject(ToastService);
  private readonly modalService = inject(ModalService);
  private readonly confirmService = inject(ConfirmService);
  private readonly destroyRef = inject(DestroyRef);

  readonly TransactionType = TransactionType;

  readonly transaction = computed(() => this.modalService.editingEntity() as Transaction | null);
  readonly type = input(TransactionType.DEPENSE);
  readonly saved = output<void>();
  readonly cancelled = output<void>();
  readonly typeChanged = output<TransactionType>();

  readonly amountInput = viewChild<ElementRef<HTMLInputElement>>('amountInput');

  readonly isEditing = computed(() => this.transaction() !== null && !this.modalService.asRecurring());
  readonly submitting = signal(false);
  readonly errorMessage = signal('');
  readonly libelleSuggestions = signal<string[]>([]);
  readonly expandedSection = signal<ExpandableSection>(null);

  readonly amountWidth: Signal<string>;

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
    montant: ['', [Validators.required, decimalMin(0.01)]],
    date: [this.localDate(), [Validators.required]],
    categoryId: [''],
    note: ['', [Validators.maxLength(500)]],
    accountId: [''],
    isRecurring: [false],
    frequency: [{ value: Frequency.MENSUEL, disabled: true }],
    nextOccurrence: [{ value: '', disabled: true }],
  });

  private readonly accountIdSignal = toSignal(
    this.form.get('accountId')!.valueChanges,
    { initialValue: this.form.get('accountId')!.value }
  );

  readonly selectedAccount = computed(() => {
    const accountId = this.accountIdSignal();
    if (!accountId) return null;
    return this.activeAccounts().find((a) => a.id === accountId) ?? null;
  });

  readonly selectedAccountName = computed(() => this.selectedAccount()?.nom ?? null);
  readonly selectedAccountColor = computed(() => this.selectedAccount()?.couleur ?? null);
  readonly currencySymbol = computed(() => {
    const currency = this.selectedAccount()?.currency ?? 'EUR';
    return (0).toLocaleString(APP_LOCALE, { style: 'currency', currency, minimumFractionDigits: 0, maximumFractionDigits: 0 }).replace('0', '').trim();
  });

  private readonly allCategories = toSignal(this.categoryService.getAll(), { initialValue: [] });

  readonly selectedCategory = computed(() => {
    const categoryId = this.form.get('categoryId')?.value;
    if (!categoryId) return null;
    return this.allCategories().find((c) => c.id === categoryId) ?? null;
  });

  readonly selectedCategoryName = computed(() => this.selectedCategory()?.nom ?? null);
  readonly selectedCategoryColor = computed(() => this.selectedCategory()?.couleur ?? null);

  readonly today = this.localDate();

  readonly dateSignal = toSignal(
    this.form.get('date')!.valueChanges,
    { initialValue: this.form.get('date')!.value }
  );

  readonly nextOccurrenceSignal = toSignal(
    this.form.get('nextOccurrence')!.valueChanges,
    { initialValue: this.form.get('nextOccurrence')!.value }
  );

  onDateSelected(isoDate: string): void {
    this.form.patchValue({ date: isoDate });
  }

  onNextOccurrenceSelected(isoDate: string): void {
    this.form.patchValue({ nextOccurrence: isoDate });
  }

  private localDate(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  private readonly isRecurringSignal = toSignal(this.form.get('isRecurring')!.valueChanges, {
    initialValue: false,
  });

  constructor() {
    this.amountWidth = createAmountWidth(this.form.get('montant')!, 30);

    // Toggle récurrence
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

    // Charge les données en mode édition
    effect(() => {
      const tx = this.transaction();
      const asRecurring = this.modalService.asRecurring();

      if (asRecurring && tx) {
        this.form.patchValue({
          libelle: tx.libelle,
          montant: tx.montant.toFixed(2),
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
          montant: tx.montant.toFixed(2),
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

    // Focus sur le montant à l'ouverture
    effect(() => {
      const input = this.amountInput();
      if (input && !this.isEditing()) {
        setTimeout(() => input.nativeElement.focus(), 100);
      }
    });
  }

  onLibelleQuery(q: string): void {
    this.libelleService
      .search(q)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((suggestions) => {
        this.libelleSuggestions.set(suggestions);
      });
  }

  onTypeChange(type: TransactionType): void {
    this.typeChanged.emit(type);
  }

  toggleSection(section: ExpandableSection): void {
    this.expandedSection.update((current) => (current === section ? null : section));
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

    try {
      if (raw.isRecurring) {
        const request: RecurringTransactionRequest = {
          libelle: raw.libelle,
          montant,
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
          montant,
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
    const currency = tx.account?.currency ?? 'EUR';
    const amount = tx.montant.toLocaleString(APP_LOCALE, { style: 'currency', currency });
    let message = 'Voulez-vous vraiment supprimer cette transaction ?';
    if (tx.transferId) {
      message += '\nLa contrepartie du virement sera aussi supprimée.';
    }
    const ok = await this.confirmService.confirm({
      title: `${tx.libelle} — ${amount}`,
      message,
      confirmLabel: 'Supprimer',
      variant: 'danger',
      icon: 'phosphorReceipt',
    });
    if (!ok) return;
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
