import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  output,
  signal,
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { DecimalPipe } from '@angular/common';
import { firstValueFrom } from 'rxjs';

import { FormField } from '../../../../shared/components/form-field/form-field';
import { ProductService } from '../../../../core/services/product';
import { ModalService } from '../../../../core/services/modal.service';
import { Product } from '../../../../core/models/product.model';
import { isFieldInvalid, validateForm } from '../../../../shared/utils/form.utils';

@Component({
  selector: 'app-sell-dialog',
  imports: [ReactiveFormsModule, DecimalPipe, FormField],
  templateUrl: './sell-dialog.html',
  styleUrl: './sell-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SellDialog {
  private readonly fb = inject(FormBuilder);
  private readonly productService = inject(ProductService);
  private readonly modalService = inject(ModalService);

  readonly confirmed = output<void>();
  readonly cancelled = output<void>();

  readonly products = signal<Product[]>([]);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');

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

  constructor() {
    this.loadProducts();
  }

  private async loadProducts(): Promise<void> {
    const all = await firstValueFrom(this.productService.getAll(true));
    this.products.set(all);
  }

  onProductChange(): void {
    const id = this.form.get('productId')!.value;
    this.selectedProductId.set(id);
    this.form.get('quantity')!.setValue(1);
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    const raw = this.form.getRawValue();
    const max = this.maxStock();
    if (raw.quantity > max) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    try {
      await firstValueFrom(this.productService.sell(raw.productId, raw.quantity));
      this.modalService.closeModal();
      this.confirmed.emit();
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors de la vente');
    } finally {
      this.submitting.set(false);
    }
  }

  onCancel(): void {
    this.modalService.closeModal();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }
}
