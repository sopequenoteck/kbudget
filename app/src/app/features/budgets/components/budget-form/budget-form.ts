import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  output,
  signal,
} from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { CategoryService } from '../../../../core/services/category';
import { BudgetService } from '../../../../core/services/budget';
import { PreferenceService } from '../../../../core/services/preference';
import { ModalService } from '../../../../core/services/modal.service';
import { Budget, BudgetRequest, FREQUENCIES } from '../../../../core/models/budget.model';
import { Category } from '../../../../core/models/category.model';
import { FormField } from '../../../../shared/components/form-field/form-field';
import { isFieldInvalid, validateForm } from '../../../../shared/utils/form.utils';

@Component({
  selector: 'app-budget-form',
  imports: [ReactiveFormsModule, FormField],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()" class="budget-form">
      @if (errorMessage()) {
        <div class="form-error-banner">{{ errorMessage() }}</div>
      }

      @if (noAvailableCategories() && !isEditMode()) {
        <p class="budget-form__empty">Toutes les categories ont deja un budget.</p>
      } @else {
        <app-form-field
          label="Categorie"
          fieldId="categoryId"
          [showError]="isInvalid('categoryId')"
          [errorMessage]="'Categorie requise'"
        >
          <select id="categoryId" formControlName="categoryId">
            <option value="" disabled>Choisir une categorie</option>
            @for (cat of availableCategories(); track cat.id) {
              <option [value]="cat.id">{{ cat.icone }} {{ cat.nom }}</option>
            }
          </select>
        </app-form-field>

        <div class="form-row">
          <app-form-field
            label="Montant"
            fieldId="montant"
            [showError]="isInvalid('montant')"
            [errorMessage]="'Montant requis (> 0)'"
          >
            <input id="montant" type="number" formControlName="montant" step="0.01" min="0.01" />
          </app-form-field>

          <app-form-field label="Devise" fieldId="currency">
            <select id="currency" formControlName="currency">
              @for (cur of currencies(); track cur) {
                <option [value]="cur">{{ cur }}</option>
              }
            </select>
          </app-form-field>
        </div>

        <app-form-field label="Frequence" fieldId="frequence">
          <select id="frequence" formControlName="frequence">
            @for (freq of frequencies; track freq.value) {
              <option [value]="freq.value">{{ freq.label }}</option>
            }
          </select>
        </app-form-field>

        <app-form-field label="Seuil d'alerte (%)" fieldId="seuilNotification">
          <input
            id="seuilNotification"
            type="number"
            formControlName="seuilNotification"
            min="0"
            max="100"
          />
        </app-form-field>

        <label class="checkbox-field">
          <input type="checkbox" formControlName="actif" />
          Budget actif
        </label>

        <div class="form-actions">
          @if (isEditMode()) {
            <button type="button" class="btn-danger" (click)="onDelete()">Supprimer</button>
          }
          <button type="button" class="btn-outline" (click)="onCancel()">Annuler</button>
          <button type="submit" class="btn-primary" [disabled]="form.invalid || submitting()">
            {{ submitting() ? 'Enregistrement...' : isEditMode() ? 'Modifier' : 'Enregistrer' }}
          </button>
        </div>
      }
    </form>
  `,
  styles: `
    .budget-form {
      display: flex;
      flex-direction: column;
      gap: var(--space-4);
    }

    .budget-form__empty {
      color: var(--text-secondary);
      font-size: var(--font-size-sm);
      text-align: center;
      padding: var(--space-4) 0;
    }

    .form-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: var(--space-3);
    }

    .checkbox-field {
      display: flex;
      align-items: center;
      gap: var(--space-2);
      font-size: var(--font-size-sm);
      color: var(--text-primary);
      cursor: pointer;
    }

    .form-actions {
      display: flex;
      justify-content: flex-end;
      gap: var(--space-3);
      padding-top: var(--space-3);

      .btn-danger {
        margin-right: auto;
      }
    }

    .form-error-banner {
      background: var(--bg-danger, #fef2f2);
      color: var(--text-danger, #dc2626);
      padding: var(--space-3);
      border-radius: var(--radius-md);
      font-size: var(--font-size-sm);
    }

    @media (max-width: 400px) {
      .form-row {
        grid-template-columns: 1fr;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetForm {
  private readonly categoryService = inject(CategoryService);
  private readonly budgetService = inject(BudgetService);
  private readonly preferenceService = inject(PreferenceService);
  private readonly modalService = inject(ModalService);

  readonly budget = computed(() => this.modalService.editingEntity() as Budget | null);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly isEditMode = computed(() => this.budget() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');

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
    montant: new FormControl<number | null>(null, [Validators.required, Validators.min(0.01)]),
    frequence: new FormControl('MENSUEL', { nonNullable: true, validators: [Validators.required] }),
    currency: new FormControl('EUR', { nonNullable: true }),
    seuilNotification: new FormControl(80, {
      nonNullable: true,
      validators: [Validators.min(0), Validators.max(100)],
    }),
    actif: new FormControl(true, { nonNullable: true }),
  });

  constructor() {
    this.loadCategories();
    this.loadExistingBudgets();

    effect(() => {
      const b = this.budget();
      if (b) {
        this.form.patchValue({
          categoryId: b.category.id,
          montant: b.montant,
          frequence: b.frequence,
          currency: b.currency,
          seuilNotification: b.seuilNotification,
          actif: b.actif,
        });
        this.form.get('categoryId')?.disable();
      }
    });
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const request: BudgetRequest = {
      categoryId: raw.categoryId,
      montant: Number(raw.montant),
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
    if (!confirm('Supprimer ce budget ?')) return;
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
