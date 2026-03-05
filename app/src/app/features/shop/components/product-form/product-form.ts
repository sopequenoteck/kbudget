import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { DecimalPipe } from '@angular/common';
import { FormField } from '../../../../shared/components/form-field/form-field';
import {
  Product,
  ProductRequest,
  ProductUpdateRequest,
} from '../../../../core/models/product.model';

@Component({
  selector: 'app-product-form',
  imports: [ReactiveFormsModule, FormField, DecimalPipe],
  templateUrl: './product-form.html',
  styleUrl: './product-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProductForm {
  private readonly fb = inject(FormBuilder);

  readonly product = input<Product | null>(null);
  readonly saved = output<ProductRequest | ProductUpdateRequest>();
  readonly cancelled = output<void>();
  readonly deleted = output<string>();

  readonly isEditMode = computed(() => this.product() !== null);

  readonly fileInput = viewChild<ElementRef<HTMLInputElement>>('fileInput');
  readonly imagePreview = signal<string | null>(null);

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(100)]],
    description: ['', [Validators.maxLength(500)]],
    prixAchat: ['', [Validators.required, Validators.min(0.01)]],
    prixVente: ['', [Validators.required, Validators.min(0.01)]],
    stock: [0, [Validators.required, Validators.min(0)]],
    actif: [true],
  });

  private readonly prixAchat = signal(0);
  private readonly prixVente = signal(0);

  readonly marge = computed(() => this.prixVente() - this.prixAchat());

  constructor() {
    effect(() => {
      const p = this.product();
      if (p) {
        this.form.patchValue({
          nom: p.nom,
          description: p.description ?? '',
          prixAchat: String(p.prixAchat),
          prixVente: String(p.prixVente),
          stock: p.stock,
          actif: p.actif,
        });
        this.prixAchat.set(p.prixAchat);
        this.prixVente.set(p.prixVente);
        const url = p.imageUrl;
        this.imagePreview.set(url && (url.startsWith('http') || url.startsWith('data:')) ? url : null);
      }
    });

    const prixAchatSignal = toSignal(this.form.controls.prixAchat.valueChanges, {
      initialValue: '',
    });
    const prixVenteSignal = toSignal(this.form.controls.prixVente.valueChanges, {
      initialValue: '',
    });

    effect(() => {
      const achat = parseFloat(prixAchatSignal() ?? '');
      this.prixAchat.set(isNaN(achat) ? 0 : achat);
    });

    effect(() => {
      const vente = parseFloat(prixVenteSignal() ?? '');
      this.prixVente.set(isNaN(vente) ? 0 : vente);
    });
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const raw = this.form.getRawValue();

    if (this.isEditMode()) {
      const request: ProductUpdateRequest = {
        nom: raw.nom,
        description: raw.description || undefined,
        icone: this.product()!.icone ?? undefined,
        imageUrl: this.imagePreview() ?? undefined,
        prixAchat: Number(raw.prixAchat),
        prixVente: Number(raw.prixVente),
        stock: this.product()!.stock,
        actif: raw.actif,
      };
      this.saved.emit(request);
    } else {
      const request: ProductRequest = {
        nom: raw.nom,
        description: raw.description || undefined,
        imageUrl: this.imagePreview() ?? undefined,
        prixAchat: Number(raw.prixAchat),
        prixVente: Number(raw.prixVente),
        stock: raw.stock,
      };
      this.saved.emit(request);
    }
  }

  onImagePicked(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    this.compressImage(file).then(dataUri => {
      this.imagePreview.set(dataUri);
    });
  }

  private compressImage(
    file: File,
    maxWidth = 1024,
    quality = 0.85,
  ): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        const img = new Image();
        img.onload = () => {
          let width = img.width;
          let height = img.height;

          if (width > maxWidth) {
            height = Math.round((height * maxWidth) / width);
            width = maxWidth;
          }

          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d')!;
          ctx.drawImage(img, 0, 0, width, height);
          resolve(canvas.toDataURL('image/jpeg', quality));
        };
        img.onerror = reject;
        img.src = reader.result as string;
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  removeImage(): void {
    this.imagePreview.set(null);
    const el = this.fileInput()?.nativeElement;
    if (el) el.value = '';
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  onDelete(): void {
    if (window.confirm('Supprimer ce produit ?')) {
      this.deleted.emit(this.product()!.id);
    }
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
