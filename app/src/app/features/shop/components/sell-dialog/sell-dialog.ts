import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { DecimalPipe } from '@angular/common';
import { FormField } from '../../../../shared/components/form-field/form-field';
import { Product } from '../../../../core/models/product.model';

@Component({
  selector: 'app-sell-dialog',
  imports: [ReactiveFormsModule, DecimalPipe, FormField],
  templateUrl: './sell-dialog.html',
  styleUrl: './sell-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SellDialog {
  private readonly fb = inject(FormBuilder);

  readonly products = input<Product[]>([]);
  readonly confirmed = output<{ productId: string; quantity: number }>();
  readonly cancelled = output<void>();

  readonly selectedProductId = signal<string>('');
  readonly selectedProduct = computed(() => {
    const id = this.selectedProductId();
    return this.products().find((p) => p.id === id) ?? null;
  });

  readonly maxStock = computed(() => this.selectedProduct()?.stock ?? 1);

  readonly form = this.fb.nonNullable.group({
    productId: ['', [Validators.required]],
    quantity: [1, [Validators.required, Validators.min(1)]],
  });

  readonly sellableProducts = computed(() => this.products().filter((p) => p.actif && p.stock > 0));

  onProductChange(): void {
    const id = this.form.get('productId')!.value;
    this.selectedProductId.set(id);
    this.form.get('quantity')!.setValue(1);
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const raw = this.form.getRawValue();
    const max = this.maxStock();
    if (raw.quantity > max) return;

    this.confirmed.emit({
      productId: raw.productId,
      quantity: raw.quantity,
    });
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
