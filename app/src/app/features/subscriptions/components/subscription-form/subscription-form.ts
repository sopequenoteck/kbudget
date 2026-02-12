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

import { FormField } from '../../../../shared/components/form-field/form-field';
import { CategoryPicker } from '../../../../shared/components/category-picker/category-picker';
import {
  Frequency,
  Subscription,
  SubscriptionRequest,
} from '../../../../core/models/subscription.model';

@Component({
  selector: 'app-subscription-form',
  imports: [ReactiveFormsModule, FormField, CategoryPicker],
  templateUrl: './subscription-form.html',
  styleUrl: './subscription-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SubscriptionForm {
  private readonly fb = inject(FormBuilder);

  readonly subscription = input<Subscription | null>(null);
  readonly saved = output<SubscriptionRequest>();
  readonly cancelled = output<void>();
  readonly deleted = output<string>();

  readonly showDeleteConfirm = signal(false);

  readonly isEditMode = computed(() => this.subscription() !== null);

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    frequence: [Frequency.MENSUEL, [Validators.required]],
    dateDebut: [new Date().toISOString().split('T')[0], [Validators.required]],
    actif: [true],
    categoryId: [''],
  });

  readonly Frequency = Frequency;

  constructor() {
    effect(() => {
      const sub = this.subscription();
      if (sub) {
        this.form.patchValue({
          nom: sub.nom,
          montant: String(sub.montant),
          frequence: sub.frequence,
          dateDebut: sub.dateDebut,
          actif: sub.actif,
          categoryId: sub.category?.id ?? '',
        });
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
      frequence: raw.frequence,
      dateDebut: raw.dateDebut,
      actif: raw.actif,
      categoryId: raw.categoryId || undefined,
    };

    this.saved.emit(request);
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  onDelete(): void {
    this.showDeleteConfirm.set(true);
  }

  onConfirmDelete(): void {
    this.deleted.emit(this.subscription()!.id);
    this.showDeleteConfirm.set(false);
  }

  onCancelDelete(): void {
    this.showDeleteConfirm.set(false);
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
