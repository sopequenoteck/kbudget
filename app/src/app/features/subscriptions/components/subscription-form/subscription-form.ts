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
import { AccountPicker } from '../../../../shared/components/account-picker/account-picker';
import { AccountService } from '../../../../core/services/account';
import { Account } from '../../../../core/models/account.model';
import {
  Frequency,
  Subscription,
  SubscriptionRequest,
} from '../../../../core/models/subscription.model';

@Component({
  selector: 'app-subscription-form',
  imports: [ReactiveFormsModule, FormField, CategoryPicker, AccountPicker],
  templateUrl: './subscription-form.html',
  styleUrl: './subscription-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SubscriptionForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);

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

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    dateDebut: [new Date().toISOString().split('T')[0], [Validators.required]],
    actif: [true],
    categoryId: [''],
    accountId: [''],
  });

  constructor() {
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

  onAccountSelected(accountId: string | null): void {
    this.form.patchValue({ accountId: accountId ?? '' });
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
