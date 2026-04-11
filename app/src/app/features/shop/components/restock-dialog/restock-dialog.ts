import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  output,
  signal,
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorPackage } from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { ModalService } from '../../../../core/services/modal.service';
import { ProductService } from '../../../../core/services/product';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Product } from '../../../../core/models/product.model';
import { validateForm } from '../../../../shared/utils/form.utils';

@Component({
  selector: 'app-restock-dialog',
  standalone: true,
  imports: [ReactiveFormsModule, NgIcon],
  providers: [provideIcons({ phosphorPackage })],
  templateUrl: './restock-dialog.html',
  styleUrl: './restock-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RestockDialog {
  private readonly fb = inject(FormBuilder);
  private readonly productService = inject(ProductService);
  private readonly toastService = inject(ToastService);
  private readonly modalService = inject(ModalService);

  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly submitting = signal(false);
  readonly errorMessage = signal('');

  private readonly product = computed(() => this.modalService.editingEntity() as Product | null);
  readonly productName = computed(() => this.product()?.nom ?? '');
  readonly productStock = computed(() => this.product()?.stock ?? 0);

  readonly form = this.fb.nonNullable.group({
    quantity: [1, [Validators.required, Validators.min(1)]],
  });

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    const p = this.product();
    if (!p) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    try {
      const updated = await firstValueFrom(
        this.productService.restock(p.id, { quantity: this.form.getRawValue().quantity }),
      );
      this.modalService.closeModal();
      this.saved.emit();
      this.toastService.success(`Stock mis à jour : ${updated.stock} unités`);
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors du restockage');
    } finally {
      this.submitting.set(false);
    }
  }

  onCancel(): void {
    this.modalService.closeModal();
    this.cancelled.emit();
  }
}
