import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  output,
  Signal,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorChartPie,
  phosphorTag,
  phosphorRepeat,
  phosphorCoins,
  phosphorWarning,
  phosphorTrash,
  phosphorCheckCircle,
  phosphorCircle,
} from '@ng-icons/phosphor-icons/regular';

import { CategoryService } from '../../../../core/services/category';
import { BudgetService } from '../../../../core/services/budget';
import { PreferenceService } from '../../../../core/services/preference';
import { ModalService } from '../../../../core/services/modal.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { Budget, BudgetRequest, FREQUENCIES } from '../../../../core/models/budget.model';
import { Category } from '../../../../core/models/category.model';
import { isFieldInvalid, validateForm, normalizeDecimal, decimalMin } from '../../../../shared/utils/form.utils';
import { createAmountWidth } from '../../../../shared/utils/amount-width.utils';

type ExpandableSection = 'category' | 'frequency' | 'currency' | 'threshold' | null;

@Component({
  selector: 'app-budget-form',
  imports: [ReactiveFormsModule, NgIcon],
  providers: [
    provideIcons({
      phosphorChartPie,
      phosphorTag,
      phosphorRepeat,
      phosphorCoins,
      phosphorWarning,
      phosphorTrash,
      phosphorCheckCircle,
      phosphorCircle,
    }),
  ],
  templateUrl: './budget-form.html',
  styleUrl: './budget-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetForm {
  private readonly categoryService = inject(CategoryService);
  private readonly budgetService = inject(BudgetService);
  private readonly preferenceService = inject(PreferenceService);
  private readonly modalService = inject(ModalService);
  private readonly confirmService = inject(ConfirmService);

  readonly budget = computed(() => this.modalService.editingEntity() as Budget | null);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly isEditing = computed(() => this.budget() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');
  readonly expandedSection = signal<ExpandableSection>(null);
  readonly amountWidth: Signal<string>;

  readonly categories = signal<Category[]>([]);
  readonly existingBudgets = signal<Budget[]>([]);

  readonly availableCategories = computed(() => {
    const budget = this.budget();
    const all = this.categories();
    const existing = this.existingBudgets();

    if (budget) {
      const usedCategoryIds = existing
        .filter((b) => b.id !== budget.id)
        .map((b) => b.category.id);
      return all.filter((cat) => !usedCategoryIds.includes(cat.id));
    }

    const usedCategoryIds = existing.map((b) => b.category.id);
    return all.filter((cat) => !usedCategoryIds.includes(cat.id));
  });

  readonly noAvailableCategories = computed(() => this.availableCategories().length === 0);

  readonly currencies = this.preferenceService.currencies;
  readonly frequencies = FREQUENCIES;

  readonly form = new FormGroup({
    categoryId: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    montant: new FormControl('', { nonNullable: true, validators: [Validators.required, decimalMin(0.01)] }),
    frequence: new FormControl('MENSUEL', { nonNullable: true, validators: [Validators.required] }),
    currency: new FormControl('EUR', { nonNullable: true }),
    seuilNotification: new FormControl(80, {
      nonNullable: true,
      validators: [Validators.min(0), Validators.max(100)],
    }),
    actif: new FormControl(true, { nonNullable: true }),
  });

  readonly actif = toSignal(this.form.get('actif')!.valueChanges, { initialValue: true });

  readonly selectedCategory = computed(() => {
    const categoryId = this.form.get('categoryId')?.value;
    if (!categoryId) return null;
    return this.categories().find((c) => c.id === categoryId) ?? null;
  });

  readonly selectedCategoryName = computed(() => {
    const cat = this.selectedCategory();
    if (!cat) return null;
    return `${cat.icone} ${cat.nom}`;
  });

  readonly selectedCategoryColor = computed(() => this.selectedCategory()?.couleur ?? null);

  readonly frequencyLabel = computed(() => {
    const val = this.form.get('frequence')?.value ?? 'MENSUEL';
    return this.frequencies.find((f) => f.value === val)?.label ?? val;
  });

  readonly currencySymbol = computed(() => {
    const currency = this.form.get('currency')?.value || 'EUR';
    return (0)
      .toLocaleString('fr-FR', { style: 'currency', currency, minimumFractionDigits: 0, maximumFractionDigits: 0 })
      .replace('0', '')
      .trim();
  });

  constructor() {
    this.loadCategories();
    this.loadExistingBudgets();
    this.amountWidth = createAmountWidth(this.form.get('montant')!, 30);

    effect(() => {
      const b = this.budget();
      if (b) {
        this.form.patchValue({
          categoryId: b.category.id,
          montant: b.montant.toFixed(2),
          frequence: b.frequence,
          currency: b.currency,
          seuilNotification: b.seuilNotification,
          actif: b.actif,
        });
        this.form.get('categoryId')?.disable();
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

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const montant = normalizeDecimal(raw.montant);

    if (isNaN(montant) || montant < 0.01) {
      this.errorMessage.set('Montant invalide');
      this.submitting.set(false);
      return;
    }

    const request: BudgetRequest = {
      categoryId: raw.categoryId,
      montant,
      frequence: raw.frequence,
      currency: raw.currency || undefined,
      seuilNotification: raw.seuilNotification,
      actif: raw.actif,
    };

    try {
      const b = this.budget();
      if (b) {
        await firstValueFrom(this.budgetService.update(b.id, request));
      } else {
        await firstValueFrom(this.budgetService.create(request));
      }
      this.modalService.closeModal();
      this.saved.emit();
    } catch (err: unknown) {
      this.errorMessage.set(
        err instanceof HttpErrorResponse
          ? (err.error?.message ?? 'Erreur serveur')
          : err instanceof Error
            ? err.message
            : 'Erreur lors de la sauvegarde',
      );
    } finally {
      this.submitting.set(false);
    }
  }

  async onDelete(): Promise<void> {
    const b = this.budget();
    if (!b) return;
    const amount = b.montant.toLocaleString('fr-FR', { style: 'currency', currency: b.currency });
    const ok = await this.confirmService.confirm({
      title: `${b.category.nom} — ${amount}`,
      message: 'Voulez-vous vraiment supprimer ce budget ?',
      confirmLabel: 'Supprimer',
      variant: 'danger',
      icon: 'phosphorChartPie',
    });
    if (!ok) return;
    try {
      await firstValueFrom(this.budgetService.delete(b.id));
      this.modalService.closeModal();
    } catch (err: unknown) {
      this.errorMessage.set(
        err instanceof HttpErrorResponse
          ? (err.error?.message ?? 'Erreur serveur')
          : err instanceof Error
            ? err.message
            : 'Erreur lors de la suppression',
      );
    }
  }

  onCancel(): void {
    this.modalService.closeModal();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }

  private async loadCategories(): Promise<void> {
    const cats = await firstValueFrom(this.categoryService.getAll());
    this.categories.set(cats);
  }

  private async loadExistingBudgets(): Promise<void> {
    const budgets = await firstValueFrom(this.budgetService.getAll(true));
    this.existingBudgets.set(budgets);
  }
}
