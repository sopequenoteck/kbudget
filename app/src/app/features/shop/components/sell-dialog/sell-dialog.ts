import {
  ChangeDetectionStrategy,
  Component,
  Signal,
  computed,
  effect,
  inject,
  output,
  signal,
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorShoppingBag, phosphorPackage, phosphorHash } from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { ProductService } from '../../../../core/services/product';
import { ModalService } from '../../../../core/services/modal.service';
import { PreferenceService } from '../../../../core/services/preference';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Product } from '../../../../core/models/product.model';
import { SelectPickerItem } from '../../../../shared/components/select-picker/select-picker.model';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';
import { isFieldInvalid, validateForm, normalizeDecimal } from '../../../../shared/utils/form.utils';
import { createAmountWidth } from '../../../../shared/utils/amount-width.utils';
import { expandCollapse } from '../../../../shared/animations/expand-collapse';

type ExpandableSection = 'product' | 'quantity' | null;

@Component({
  selector: 'app-sell-dialog',
  imports: [ReactiveFormsModule, NgIcon, SelectPicker],
  providers: [provideIcons({ phosphorShoppingBag, phosphorPackage, phosphorHash })],
  templateUrl: './sell-dialog.html',
  styleUrl: './sell-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [expandCollapse],
})
export class SellDialog {
  private readonly fb = inject(FormBuilder);
  private readonly productService = inject(ProductService);
  private readonly modalService = inject(ModalService);
  private readonly preferenceService = inject(PreferenceService);
  private readonly toastService = inject(ToastService);

  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly submitting = signal(false);
  readonly errorMessage = signal('');
  readonly expandedSection = signal<ExpandableSection>(null);
  readonly amountWidth: Signal<string>;

  private readonly products = signal<Product[]>([]);

  readonly sellableProducts = computed(() => this.products().filter((p) => p.actif && p.stock > 0));

  readonly selectedProductId = signal('');

  readonly selectedProduct = computed(() => {
    const id = this.selectedProductId();
    if (!id) return null;
    return this.sellableProducts().find((p) => p.id === id) ?? null;
  });

  readonly maxStock = computed(() => this.selectedProduct()?.stock ?? 1);

  readonly currencySymbol = computed(() => {
    const currency = this.preferenceService.primaryCurrency();
    return (0)
      .toLocaleString('fr-FR', { style: 'currency', currency, minimumFractionDigits: 0, maximumFractionDigits: 0 })
      .replace('0', '')
      .trim();
  });

  readonly totalAmount = computed(() => {
    const product = this.selectedProduct();
    const quantity = this.form.get('quantity')?.value ?? 1;
    if (!product) return '0';
    return (product.prixVente * quantity).toFixed(2);
  });

  readonly productItems = computed<SelectPickerItem[]>(() =>
    this.sellableProducts().map((p) => ({
      id: p.id,
      label: p.nom,
      icon: p.icone,
      secondaryText: `stock: ${p.stock}`,
      color: null,
      iconUrl: p.imageUrl ?? null,
    })),
  );

  readonly form = this.fb.nonNullable.group({
    productId: ['', [Validators.required]],
    quantity: [1, [Validators.required, Validators.min(1)]],
    totalPrice: ['', [Validators.required]],
  });

  constructor() {
    this.loadProducts();
    this.amountWidth = createAmountWidth(this.form.get('totalPrice')!, 22);

    this.form.get('productId')!.valueChanges.subscribe((id) => {
      this.selectedProductId.set(id);
      this.form.get('quantity')!.setValue(1);
      this.updateTotalPrice();
    });

    this.form.get('quantity')!.valueChanges.subscribe(() => {
      this.updateTotalPrice();
    });

    effect(() => {
      const max = this.maxStock();
      this.form.get('quantity')!.setValidators([
        Validators.required,
        Validators.min(1),
        Validators.max(max),
      ]);
      this.form.get('quantity')!.updateValueAndValidity({ emitEvent: false });
    });

    // Pré-sélection quand ouvert depuis shop-detail avec un produit
    effect(() => {
      const entity = this.modalService.editingEntity() as Product | null;
      if (!entity?.id) return;
      const available = this.sellableProducts();
      if (available.length === 0) return;
      if (available.find((p) => p.id === entity.id)) {
        this.form.patchValue({ productId: entity.id });
      }
    }, { allowSignalWrites: true });
  }

  private updateTotalPrice(): void {
    const product = this.selectedProduct();
    const quantity = this.form.get('quantity')?.value ?? 1;
    if (!product) return;
    const total = product.prixVente * quantity;
    const formatted = total % 1 === 0 ? String(total) : total.toFixed(2);
    this.form.get('totalPrice')!.setValue(formatted, { emitEvent: true });
  }

  private async loadProducts(): Promise<void> {
    const all = await firstValueFrom(this.productService.getAll(true));
    this.products.set(all);
  }

  toggleSection(section: ExpandableSection): void {
    this.expandedSection.update((current) => (current === section ? null : section));
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    const raw = this.form.getRawValue();
    if (raw.quantity > this.maxStock()) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    try {
      await firstValueFrom(this.productService.sell(raw.productId, raw.quantity));
      this.modalService.closeModal();
      this.saved.emit();
      this.toastService.success('Vente enregistrée');
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors de la vente');
    } finally {
      this.submitting.set(false);
    }
  }

  onCancel(): void {
    this.modalService.closeModal();
    this.cancelled.emit();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }
}
