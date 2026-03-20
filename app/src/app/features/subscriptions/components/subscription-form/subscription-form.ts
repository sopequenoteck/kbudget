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
import { SubscriptionService } from '../../../../core/services/subscription';
import { CurrencyService } from '../../../../core/services/currency';
import { ModalService } from '../../../../core/services/modal.service';
import { Account } from '../../../../core/models/account.model';
import {
  Frequency,
  Subscription,
  SubscriptionRequest,
} from '../../../../core/models/subscription.model';
import { isFieldInvalid, validateForm } from '../../../../shared/utils/form.utils';

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
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly currencyService = inject(CurrencyService);
  private readonly modalService = inject(ModalService);

  readonly subscription = computed(() => this.modalService.editingEntity() as Subscription | null);
  readonly frequence = input(Frequency.MENSUEL);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly isEditMode = computed(() => this.subscription() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');

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
      iconUrl: a.bankLogoUrl ?? a.bankCustomLogo ?? null,
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

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

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
