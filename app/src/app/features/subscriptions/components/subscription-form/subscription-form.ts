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
  Signal,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCalendarBlank,
  phosphorWallet,
  phosphorRepeat,
  phosphorTag,
  phosphorTrash,
  phosphorToggleLeft,
  phosphorToggleRight,
} from '@ng-icons/phosphor-icons/regular';

import { CategoryPicker } from '../../../../shared/components/category-picker/category-picker';
import { InlineDatePicker } from '../../../../shared/components/inline-date-picker/inline-date-picker';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';
import { SelectPickerItem } from '../../../../shared/components/select-picker/select-picker.model';
import { AccountService } from '../../../../core/services/account';
import { CategoryService } from '../../../../core/services/category';
import { SubscriptionService } from '../../../../core/services/subscription';
import { CurrencyService } from '../../../../core/services/currency';
import { ModalService } from '../../../../core/services/modal.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { Account } from '../../../../core/models/account.model';
import {
  Frequency,
  Subscription,
  SubscriptionRequest,
} from '../../../../core/models/subscription.model';
import { isFieldInvalid, validateForm, normalizeDecimal, decimalMin } from '../../../../shared/utils/form.utils';
import { createAmountWidth } from '../../../../shared/utils/amount-width.utils';
import { expandCollapse } from '../../../../shared/animations/expand-collapse';
import { APP_LOCALE } from '../../../../core/constants/locale.constants';

type ExpandableSection = 'date' | 'category' | 'account' | 'currency' | null;

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
  selector: 'app-subscription-form',
  imports: [ReactiveFormsModule, CategoryPicker, InlineDatePicker, SelectPicker, NgIcon, ShortDatePipe],
  providers: [
    provideIcons({
      phosphorCalendarBlank,
      phosphorWallet,
      phosphorRepeat,
      phosphorTag,
      phosphorTrash,
      phosphorToggleLeft,
      phosphorToggleRight,
    }),
  ],
  templateUrl: './subscription-form.html',
  styleUrl: './subscription-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [expandCollapse],
})
export class SubscriptionForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);
  private readonly categoryService = inject(CategoryService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly currencyService = inject(CurrencyService);
  private readonly modalService = inject(ModalService);
  private readonly confirmService = inject(ConfirmService);

  readonly subscription = computed(() => this.modalService.editingEntity() as Subscription | null);
  readonly frequence = input(Frequency.MENSUEL);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly Frequency = Frequency;
  readonly currentFrequency = signal(Frequency.MENSUEL);
  readonly isEditing = computed(() => this.subscription() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');
  readonly expandedSection = signal<ExpandableSection>(null);

  readonly amountWidth: Signal<string>;

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

  readonly currencyItems = this.currencyService.currencyItems;

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, decimalMin(0.01)]],
    dateDebut: [this.localDate(), [Validators.required]],
    actif: [true],
    categoryId: [''],
    accountId: [''],
    currency: [''],
  });

  readonly actif = toSignal(this.form.get('actif')!.valueChanges, { initialValue: true });

  readonly dateDebutSignal = toSignal(
    this.form.get('dateDebut')!.valueChanges,
    { initialValue: this.form.get('dateDebut')!.value }
  );

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
    return (0)
      .toLocaleString(APP_LOCALE, { style: 'currency', currency, minimumFractionDigits: 0, maximumFractionDigits: 0 })
      .replace('0', '')
      .trim();
  });

  readonly showCurrencyPicker = computed(() => !this.accountIdSignal());

  private readonly allCategories = toSignal(this.categoryService.getAll(), { initialValue: [] });

  readonly selectedCategory = computed(() => {
    const categoryId = this.form.get('categoryId')?.value;
    if (!categoryId) return null;
    return this.allCategories().find((c) => c.id === categoryId) ?? null;
  });

  readonly selectedCategoryName = computed(() => this.selectedCategory()?.nom ?? null);
  readonly selectedCategoryColor = computed(() => this.selectedCategory()?.couleur ?? null);

  private localDate(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  constructor() {
    this.currencyService.loadIfEmpty();
    this.amountWidth = createAmountWidth(this.form.get('montant')!, 30);

    effect(() => {
      const sub = this.subscription();
      if (sub) {
        this.currentFrequency.set(sub.frequence);
        this.form.patchValue({
          nom: sub.nom,
          montant: sub.montant.toFixed(2),
          dateDebut: sub.dateDebut,
          actif: sub.actif,
          categoryId: sub.category?.id ?? '',
          accountId: sub.account?.id ?? '',
        });
      } else {
        this.currentFrequency.set(this.frequence());
        const def = this.defaultAccount();
        if (def) {
          this.form.patchValue({ accountId: def.id });
        }
      }
    });
  }

  toggleSection(section: ExpandableSection): void {
    this.expandedSection.update((current) => (current === section ? null : section));
  }

  onDateSelected(isoDate: string): void {
    this.form.patchValue({ dateDebut: isoDate });
  }

  onFrequencyChange(freq: Frequency): void {
    this.currentFrequency.set(freq);
  }

  toggleActif(): void {
    const current = this.form.get('actif')?.value ?? true;
    this.form.patchValue({ actif: !current });
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

    const request: SubscriptionRequest = {
      nom: raw.nom,
      montant,
      frequence: this.currentFrequency(),
      dateDebut: raw.dateDebut,
      actif: raw.actif,
      categoryId: raw.categoryId || undefined,
      accountId: raw.accountId || undefined,
      currency: raw.accountId ? undefined : raw.currency || undefined,
    };

    try {
      const sub = this.subscription();
      if (sub) {
        await firstValueFrom(this.subscriptionService.update(sub.id, request));
      } else {
        await firstValueFrom(this.subscriptionService.create(request));
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
    const sub = this.subscription();
    if (!sub) return;
    const currency = sub.account?.currency ?? sub.currency ?? 'EUR';
    const amount = sub.montant.toLocaleString(APP_LOCALE, { style: 'currency', currency });
    const ok = await this.confirmService.confirm({
      title: `${sub.nom} — ${amount}`,
      message: 'Voulez-vous vraiment supprimer cet abonnement ?',
      confirmLabel: 'Supprimer',
      variant: 'danger',
      icon: 'phosphorRepeat',
    });
    if (!ok) return;
    try {
      await firstValueFrom(this.subscriptionService.delete(sub.id));
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
