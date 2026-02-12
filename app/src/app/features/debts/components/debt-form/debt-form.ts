import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  input,
  output,
} from '@angular/core';

import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { FormField } from '../../../../shared/components/form-field/form-field';
import { CategoryPicker } from '../../../../shared/components/category-picker/category-picker';
import { Debt, DebtRequest, DebtType } from '../../../../core/models/debt.model';

@Component({
  selector: 'app-debt-form',
  imports: [ReactiveFormsModule, FormField, CategoryPicker],
  templateUrl: './debt-form.html',
  styleUrl: './debt-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DebtForm {
  private readonly fb = inject(FormBuilder);

  readonly debt = input<Debt | null>(null);
  readonly sens = input(DebtType.EMPRUNT);
  readonly saved = output<DebtRequest>();
  readonly cancelled = output<void>();
  readonly deleted = output<string>();

  readonly isEditMode = computed(() => this.debt() !== null);

  readonly form = this.fb.nonNullable.group({
    personne: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    date: [new Date().toISOString().split('T')[0], [Validators.required]],
    rembourse: [false],
    categoryId: [''],
  });

  constructor() {
    effect(() => {
      const d = this.debt();
      if (d) {
        this.form.patchValue({
          personne: d.personne,
          montant: String(d.montant),
          date: d.date,
          rembourse: d.rembourse,
          categoryId: d.category?.id ?? '',
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
    const request: DebtRequest = {
      personne: raw.personne,
      montant: Number(raw.montant),
      sens: this.sens(),
      date: raw.date,
      rembourse: raw.rembourse,
      categoryId: raw.categoryId || undefined,
    };

    this.saved.emit(request);
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  onDelete(): void {
    this.deleted.emit(this.debt()!.id);
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
