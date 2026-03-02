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
import { CurrencyService } from '../../../../core/services/currency';
import { Account } from '../../../../core/models/account.model';
import {
  Frequency,
  Subscription,
  SubscriptionRequest,
} from '../../../../core/models/subscription.model';

@Component({
  selector: 'app-subscription-form',
  imports: [ReactiveFormsModule, FormField, CategoryPicker, SelectPicker],
  templateUrl: './subscription-form.html',
  styleUrl: './subscription-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SubscriptionForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);
  private readonly currencyService = inject(CurrencyService);

  readonly subscription = input<Subscription | null>(null);
  readonly frequence = input(Frequency.MENSUEL);
  readonly saved = output<SubscriptionRequest>();
  readonly cancelled = output<void>();
  readonly deleted = output<string>();

  readonly isEditMode = computed(() => this.subscription() !== null);

  private readonly allAccounts = toSignal(this.accountService.getAll(), {
    initialValue: [] as Account[],
  });

  readonly activeAccounts = computed(() => this.allAccounts().filter((a) => a.actif));
  readonly defaultAccount = computed(() => this.activeAccounts().find((a) => a.isDefault) ?? null);

  readonly currencyItems = this.currencyService.currencyItems;

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
    nom: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    dateDebut: [new Date().toISOString().split('T')[0], [Validators.required]],
    actif: [true],
    categoryId: [''],
    accountId: [''],
    currency: [''],
  });

  readonly showCurrencyPicker = computed(() => !this.form.get('accountId')?.value);

  constructor() {
    this.currencyService.loadIfEmpty();

    effect(() => {
      const sub = this.subscription();
      if (sub) {
        this.form.patchValue({
          nom: sub.nom,
          montant: String(sub.montant),
          dateDebut: sub.dateDebut,
          actif: sub.actif,
          categoryId: sub.category?.id ?? '',
          accountId: sub.account?.id ?? '',
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
    const request: SubscriptionRequest = {
      nom: raw.nom,
      montant: Number(raw.montant),
      frequence: this.frequence(),
      dateDebut: raw.dateDebut,
      actif: raw.actif,
      categoryId: raw.categoryId || undefined,
      accountId: raw.accountId || undefined,
      currency: raw.accountId ? undefined : raw.currency || undefined,
    };

    this.saved.emit(request);
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  onDelete(): void {
    this.deleted.emit(this.subscription()!.id);
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
