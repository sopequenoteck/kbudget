import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Signal,
  computed,
  effect,
  inject,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { DecimalPipe } from '@angular/common';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorPackage,
  phosphorCamera,
  phosphorNoteBlank,
  phosphorTag,
  phosphorTrendUp,
  phosphorTrendDown,
  phosphorCube,
  phosphorTrash,
  phosphorCheckCircle,
  phosphorCircle,
} from '@ng-icons/phosphor-icons/regular';

import { ProductService } from '../../../../core/services/product';
import { ModalService } from '../../../../core/services/modal.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { PreferenceService } from '../../../../core/services/preference';
import {
  Product,
  ProductRequest,
  ProductUpdateRequest,
} from '../../../../core/models/product.model';
import { isFieldInvalid, validateForm, normalizeDecimal, decimalMin } from '../../../../shared/utils/form.utils';
import { compressImage } from '../../../../shared/utils/image.utils';
import { createAmountWidth } from '../../../../shared/utils/amount-width.utils';
import { expandCollapse } from '../../../../shared/animations/expand-collapse';

type ExpandableSection = 'prixAchat' | 'description' | 'stock' | null;

@Component({
  selector: 'app-product-form',
  imports: [ReactiveFormsModule, NgIcon, DecimalPipe],
  providers: [
    provideIcons({
      phosphorPackage,
      phosphorCamera,
      phosphorNoteBlank,
      phosphorTag,
      phosphorTrendUp,
      phosphorTrendDown,
      phosphorCube,
      phosphorTrash,
      phosphorCheckCircle,
      phosphorCircle,
    }),
  ],
  templateUrl: './product-form.html',
  styleUrl: './product-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [expandCollapse],
})
export class ProductForm {
  private readonly fb = inject(FormBuilder);
  private readonly productService = inject(ProductService);
  private readonly modalService = inject(ModalService);
  private readonly confirmService = inject(ConfirmService);
  private readonly preferenceService = inject(PreferenceService);

  readonly product = computed(() => this.modalService.editingEntity() as Product | null);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly isEditing = computed(() => this.product() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');
  readonly expandedSection = signal<ExpandableSection>(null);
  readonly amountWidth: Signal<string>;

  readonly fileInput = viewChild<ElementRef<HTMLInputElement>>('fileInput');
  readonly imagePreview = signal<string | null>(null);

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(100)]],
    description: ['', [Validators.maxLength(500)]],
    prixAchat: ['', [decimalMin(0.01)]],
    prixVente: ['', [Validators.required, decimalMin(0.01)]],
    stock: [0, [Validators.required, Validators.min(0)]],
    actif: [true],
  });

  private readonly prixAchatVal = signal(0);
  private readonly prixVenteVal = signal(0);

  readonly actif = toSignal(this.form.get('actif')!.valueChanges, { initialValue: true });

  readonly marge = computed(() => this.prixVenteVal() - this.prixAchatVal());
  readonly margePositive = computed(() => this.marge() >= 0);

  readonly prixAchatDisplay = computed(() => {
    const v = this.prixAchatVal();
    return v > 0 ? (v | 0) === v ? `${v}` : v.toFixed(2) : '—';
  });

  readonly currencySymbol = computed(() => {
    const currency = this.preferenceService.primaryCurrency();
    return (0).toLocaleString('fr-FR', { style: 'currency', currency, minimumFractionDigits: 0, maximumFractionDigits: 0 }).replace('0', '').trim();
  });

  readonly margeDisplay = computed(() => {
    const m = this.marge();
    const abs = Math.abs(m);
    const str = (abs | 0) === abs ? `${abs}` : abs.toFixed(2);
    return `${m >= 0 ? '+' : '-'}${str}${this.currencySymbol()}`;
  });

  constructor() {
    this.amountWidth = createAmountWidth(this.form.get('prixVente')!, 26);

    const prixAchatSignal = toSignal(this.form.controls.prixAchat.valueChanges, { initialValue: '' });
    const prixVenteSignal = toSignal(this.form.controls.prixVente.valueChanges, { initialValue: '' });

    effect(() => {
      const achat = normalizeDecimal(prixAchatSignal() ?? '');
      this.prixAchatVal.set(isNaN(achat) ? 0 : achat);
    });

    effect(() => {
      const vente = normalizeDecimal(prixVenteSignal() ?? '');
      this.prixVenteVal.set(isNaN(vente) ? 0 : vente);
    });

    effect(() => {
      const p = this.product();
      if (p) {
        this.form.patchValue({
          nom: p.nom,
          description: p.description ?? '',
          prixAchat: p.prixAchat.toFixed(2),
          prixVente: p.prixVente.toFixed(2),
          stock: p.stock,
          actif: p.actif,
        });
        this.prixAchatVal.set(p.prixAchat);
        this.prixVenteVal.set(p.prixVente);
        const url = p.imageUrl;
        this.imagePreview.set(url && (url.startsWith('http') || url.startsWith('data:')) ? url : null);
      }
    });
  }

  toggleSection(section: ExpandableSection): void {
    this.expandedSection.update((current) => (current === section ? null : section));
  }

  toggleActif(): void {
    const current = this.form.get('actif')?.value ?? true;
    this.form.patchValue({ actif: !current });
  }

  onImagePicked(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    compressImage(file).then((dataUri) => {
      this.imagePreview.set(dataUri);
    });
  }

  removeImage(): void {
    this.imagePreview.set(null);
    const el = this.fileInput()?.nativeElement;
    if (el) el.value = '';
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const prixVente = normalizeDecimal(raw.prixVente);
    const prixAchat = normalizeDecimal(raw.prixAchat);

    if (isNaN(prixVente) || prixVente < 0.01) {
      this.errorMessage.set('Prix de vente invalide');
      this.submitting.set(false);
      return;
    }

    try {
      const p = this.product();
      if (p) {
        const request: ProductUpdateRequest = {
          nom: raw.nom,
          description: raw.description || undefined,
          icone: p.icone ?? undefined,
          imageUrl: this.imagePreview() ?? undefined,
          prixAchat: isNaN(prixAchat) ? 0 : prixAchat,
          prixVente,
          stock: p.stock,
          actif: raw.actif,
        };
        await firstValueFrom(this.productService.update(p.id, request));
      } else {
        const request: ProductRequest = {
          nom: raw.nom,
          description: raw.description || undefined,
          imageUrl: this.imagePreview() ?? undefined,
          prixAchat: isNaN(prixAchat) ? 0 : prixAchat,
          prixVente,
          stock: raw.stock,
        };
        await firstValueFrom(this.productService.create(request));
      }
      this.modalService.closeModal();
      this.saved.emit();
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors de la sauvegarde');
    } finally {
      this.submitting.set(false);
    }
  }

  async onDelete(): Promise<void> {
    const p = this.product();
    if (!p) return;
    const ok = await this.confirmService.confirm({
      title: `${p.nom} — ${p.stock} en stock`,
      message: 'Voulez-vous vraiment supprimer ce produit ?',
      confirmLabel: 'Supprimer',
      variant: 'danger',
      icon: 'phosphorPackage',
    });
    if (!ok) return;
    try {
      await firstValueFrom(this.productService.delete(p.id));
      this.modalService.closeModal();
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors de la suppression');
    }
  }

  onCancel(): void {
    this.modalService.closeModal();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }
}
