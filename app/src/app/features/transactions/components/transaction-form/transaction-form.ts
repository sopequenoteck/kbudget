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
import {
  FormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';

import { CategoryService } from '../../../../core/services/category';
import { FormField } from '../../../../shared/components/form-field/form-field';
import {
  Transaction,
  TransactionRequest,
  TransactionType,
} from '../../../../core/models/transaction.model';

@Component({
  selector: 'app-transaction-form',
  imports: [ReactiveFormsModule, FormField],
  templateUrl: './transaction-form.html',
  styleUrl: './transaction-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TransactionForm {
  private readonly fb = inject(FormBuilder);
  private readonly categoryService = inject(CategoryService);

  readonly transaction = input<Transaction | null>(null);
  readonly saved = output<TransactionRequest>();
  readonly cancelled = output<void>();

  readonly categories = toSignal(this.categoryService.getAll(), {
    initialValue: [],
  });

  readonly isEditMode = computed(() => this.transaction() !== null);

  readonly form = this.fb.nonNullable.group({
    libelle: ['', [Validators.required, Validators.maxLength(255)]],
    montant: ['', [Validators.required, Validators.min(0.01)]],
    type: [TransactionType.DEPENSE, [Validators.required]],
    date: [new Date().toISOString().split('T')[0], [Validators.required]],
    categoryId: [''],
    note: ['', [Validators.maxLength(500)]],
  });

  readonly TransactionType = TransactionType;

  constructor() {
    effect(() => {
      const tx = this.transaction();
      if (tx) {
        this.form.patchValue({
          libelle: tx.libelle,
          montant: String(tx.montant),
          type: tx.type,
          date: tx.date,
          categoryId: tx.category?.id ?? '',
          note: tx.note ?? '',
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
    const request: TransactionRequest = {
      libelle: raw.libelle,
      montant: Number(raw.montant),
      type: raw.type,
      date: raw.date,
      categoryId: raw.categoryId || undefined,
      note: raw.note || undefined,
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
