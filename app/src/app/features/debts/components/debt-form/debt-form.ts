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

import { CategoryService } from '../../../../core/services/category';
import { FormField } from '../../../../shared/components/form-field/form-field';
import { Debt, DebtRequest, DebtType } from '../../../../core/models/debt.model';

@Component({
  selector: 'app-debt-form',
  imports: [ReactiveFormsModule, FormField],
  templateUrl: './debt-form.html',
  styleUrl: './debt-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DebtForm {
  private readonly fb = inject(FormBuilder);
  private readonly categoryService = inject(CategoryService);

  readonly debt = input<Debt | null>(null);
  readonly saved = output<DebtRequest>();
  readonly cancelled = output<void>();

  readonly categories = toSignal(this.categoryService.getAll(), {
    initialValue: [],
  });

  readonly isEditMode = computed(() => this.debt() !== null);

  readonly form = this.fb.nonNullable.group({
    personne: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    sens: [DebtType.JE_DOIS, [Validators.required]],
    date: [new Date().toISOString().split('T')[0], [Validators.required]],
    rembourse: [false],
    categoryId: [''],
  });

  readonly DebtType = DebtType;

  constructor() {
    effect(() => {
      const d = this.debt();
      if (d) {
        this.form.patchValue({
          personne: d.personne,
          montant: String(d.montant),
          sens: d.sens,
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
      sens: raw.sens,
      date: raw.date,
      rembourse: raw.rembourse,
      categoryId: raw.categoryId || undefined,
    };

    this.saved.emit(request);
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
