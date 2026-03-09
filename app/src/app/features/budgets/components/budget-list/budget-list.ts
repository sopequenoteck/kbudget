import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { BudgetService } from '../../../../core/services/budget';
import { ModalService } from '../../../../core/services/modal.service';
import { CategoryService } from '../../../../core/services/category';
import {
  type Budget,
  type BudgetOverview,
  type BudgetHistory,
  type BudgetOverviewItem,
  type BudgetItem,
  isOverviewItem,
  budgetAmount,
} from '../../../../core/models/budget.model';
import { type Category } from '../../../../core/models/category.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { MonthSelector } from '../month-selector';
import { BudgetChart } from '../budget-chart';

@Component({
  selector: 'app-budget-list',
  imports: [AmountPipe, MonthSelector, BudgetChart],
  template: `
    <app-month-selector
      [month]="selectedMonth()"
      [year]="selectedYear()"
      (monthChange)="onMonthChange($event)"
    />

    @if (isCurrentMonth()) {
      <div class="budget-actions">
        <button
          class="btn-primary"
          (click)="onCreate()"
          [disabled]="allCategoriesHaveBudget()"
        >
          + Nouveau budget
        </button>
        @if (allCategoriesHaveBudget()) {
          <p class="hint">Toutes vos catégories ont déjà un budget</p>
        }
        <label class="toggle-inactive">
          <input type="checkbox" [checked]="showInactive()" (change)="toggleInactive()" />
          Afficher les inactifs
        </label>
      </div>
    }

    @if (loading()) {
      <div class="state-loading">
        <div class="spinner"></div>
        <span>Chargement...</span>
      </div>
    } @else if (error()) {
      <div class="state-error">
        <span>Une erreur est survenue</span>
        <button class="btn-outline" (click)="loadData()">Réessayer</button>
      </div>
    } @else {
      @if (monthData()) {
        <div class="budget-summary">
          <div class="budget-summary__header">
            <span class="budget-summary__label">Total dépensé</span>
            <span class="budget-summary__amounts">
              {{ monthData()!.totalSpent | amount: null : monthData()!.currency }}
              /
              {{ monthData()!.totalBudget | amount: null : monthData()!.currency }}
            </span>
          </div>
          <div class="budget-bar">
            <div
              class="budget-bar__fill budget-bar__fill--global"
              [style.width.%]="Math.min(monthData()!.percentage, 100)"
              [class.over-budget]="monthData()!.percentage > 100"
            ></div>
          </div>
        </div>
      }

      @if (items().length === 0) {
        <div class="state-empty">
          <span>Aucun budget pour cette période</span>
        </div>
      } @else {
        <ul class="budget-list">
          @for (item of items(); track item.categoryId) {
            <li
              class="budget-item"
              [class.budget-item--inactive]="isOverviewItem(item) && !item.actif"
            >
              <div class="budget-item__header">
                <span class="budget-item__icon">{{ item.categoryIcone }}</span>
                <span class="budget-item__name">{{ item.categoryNom }}</span>
                <span
                  class="budget-item__amount"
                  [class.over-budget]="item.percentage > 100"
                >
                  {{ item.montantDepense | amount: null : monthData()!.currency }}
                  /
                  {{ budgetAmount(item) | amount: null : monthData()!.currency }}
                </span>
              </div>
              <div class="budget-bar">
                <div
                  class="budget-bar__fill"
                  [style.width.%]="Math.min(item.percentage, 100)"
                  [style.background-color]="item.categoryCouleur"
                  [class.over-budget]="item.percentage > 100"
                ></div>
              </div>
              @if (isCurrentMonth() && isOverviewItem(item)) {
                <div class="budget-item__actions">
                  <button class="btn-icon" (click)="onEdit(item)" title="Modifier">✏️</button>
                  <button
                    class="btn-icon btn-icon--danger"
                    (click)="onDelete(item)"
                    title="Supprimer"
                  >🗑️</button>
                </div>
              }
            </li>
          }
        </ul>

        @if (unbudgetedTotal() > 0) {
          <div class="budget-item budget-item--other" (click)="onShowUnbudgeted()">
            <div class="budget-item__header">
              <span class="budget-item__icon">📦</span>
              <span class="budget-item__name">Autre</span>
              <span class="budget-item__amount">
                {{ unbudgetedTotal() | amount: null : monthData()!.currency }}
              </span>
            </div>
          </div>
        }

        <app-budget-chart
          [items]="items()"
          [totalSpent]="monthData()?.totalSpent ?? 0"
          [currency]="monthData()?.currency ?? 'EUR'"
          [clickable]="true"
          [unbudgetedTotal]="unbudgetedTotal()"
          (chartClicked)="onChartClick()"
        />

        @if (!hasExpenses() && !loading() && monthData()) {
          <p class="no-expenses">Aucune dépense ce mois</p>
        }
      }
    }
  `,
  styles: `
    :host {
      display: flex;
      flex-direction: column;
      gap: var(--space-5);
      padding: var(--space-4);
    }

    .budget-actions {
      display: flex;
      flex-direction: column;
      gap: var(--space-2);
      align-items: flex-start;

      .hint {
        font-size: var(--font-size-sm);
        color: var(--text-secondary);
        margin: 0;
      }
    }

    .budget-summary {
      display: flex;
      flex-direction: column;
      gap: var(--space-2);
      padding: var(--space-4);
      background-color: var(--surface-default);
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-md);

      &__header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      &__label {
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-medium);
        color: var(--text-secondary);
      }

      &__amounts {
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
      }
    }

    .budget-list {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
      gap: var(--space-3);
    }

    .budget-item {
      display: flex;
      flex-direction: column;
      gap: var(--space-2);
      padding: var(--space-4);
      background-color: var(--surface-default);
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-sm);

      &__header {
        display: flex;
        align-items: center;
        gap: var(--space-2);
      }

      &__icon {
        font-size: var(--font-size-xl);
        line-height: 1;
        flex-shrink: 0;
      }

      &__name {
        flex: 1;
        font-size: var(--font-size-base);
        font-weight: var(--font-weight-medium);
        color: var(--text-primary);
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      &__amount {
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-semibold);
        color: var(--text-secondary);
        white-space: nowrap;
        flex-shrink: 0;

        &.over-budget {
          color: var(--color-expense);
        }
      }

      &__actions {
        display: flex;
        gap: var(--space-2);
        justify-content: flex-end;
      }
    }

    .budget-bar {
      height: 8px;
      background-color: var(--border-default);
      border-radius: var(--radius-round);
      overflow: hidden;

      &__fill {
        height: 100%;
        border-radius: var(--radius-round);
        background-color: var(--color-primary);
        transition: width var(--duration-normal) var(--easing-default);

        &--global {
          background-color: var(--color-primary);
        }

        &.over-budget {
          background-color: var(--color-expense);
        }
      }
    }

    .btn-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      padding: 0;
      border: 1px solid var(--border-default);
      border-radius: var(--radius-lg);
      background-color: var(--surface-default);
      cursor: pointer;
      font-size: var(--font-size-base);
      transition:
        background-color var(--duration-normal) var(--easing-default),
        border-color var(--duration-normal) var(--easing-default);

      &:hover {
        background-color: var(--hover-bg);
      }

      &--danger {
        &:hover {
          background-color: var(--color-expense);
          border-color: var(--color-expense);
        }
      }
    }

    .state-loading,
    .state-empty,
    .state-error {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: var(--space-6) var(--space-4);
      gap: var(--space-4);
      color: var(--text-secondary);
    }

    .spinner {
      width: 32px;
      height: 32px;
      border: 3px solid var(--border-default);
      border-top-color: var(--color-primary);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin {
      to {
        transform: rotate(360deg);
      }
    }

    .no-expenses {
      text-align: center;
      color: var(--text-secondary);
      font-size: var(--font-size-sm);
      padding: var(--space-4);
    }

    .budget-item--other {
      background-color: var(--surface-muted, #f3f4f6);
      cursor: pointer;

      &:hover {
        box-shadow: var(--shadow-md);
      }
    }

    .budget-item--inactive {
      opacity: 0.5;
    }

    .toggle-inactive {
      display: flex;
      align-items: center;
      gap: var(--space-2);
      font-size: var(--font-size-sm);
      color: var(--text-secondary);
      cursor: pointer;

      input[type='checkbox'] {
        cursor: pointer;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetList {
  private readonly router = inject(Router);
  private readonly budgetService = inject(BudgetService);
  private readonly modalService = inject(ModalService);
  private readonly categoryService = inject(CategoryService);

  readonly Math = Math;
  readonly isOverviewItem = isOverviewItem;
  readonly budgetAmount = budgetAmount;

  readonly selectedMonth = signal(new Date().getMonth() + 1);
  readonly selectedYear = signal(new Date().getFullYear());
  readonly monthData = signal<BudgetOverview | BudgetHistory | null>(null);
  readonly loading = signal(true);
  readonly error = signal<string | null>(null);
  readonly allBudgets = signal<Budget[]>([]);
  readonly allCategories = signal<Category[]>([]);

  readonly showInactive = signal(false);

  private loadVersion = 0;

  readonly isCurrentMonth = computed(() => {
    const now = new Date();
    return (
      this.selectedMonth() === now.getMonth() + 1 &&
      this.selectedYear() === now.getFullYear()
    );
  });

  readonly items = computed<BudgetItem[]>(() => this.monthData()?.items ?? []);

  readonly unbudgetedTotal = computed(() => this.monthData()?.unbudgetedTotal ?? 0);

  readonly allCategoriesHaveBudget = computed(() => {
    const userCategories = this.allCategories().filter((c) => !c.isSystem);
    if (userCategories.length === 0) return false;
    const budgetedCategoryIds = new Set(this.allBudgets().map((b) => b.category.id));
    return userCategories.every((c) => budgetedCategoryIds.has(c.id));
  });

  readonly hasExpenses = computed(() => {
    const data = this.monthData();
    return data != null && data.items.some((i) => i.montantDepense > 0);
  });

  constructor() {
    effect(() => {
      this.selectedMonth();
      this.selectedYear();
      this.budgetService.refreshTrigger();
      this.loadData();
    });

    effect(() => {
      this.budgetService.refreshTrigger();
      this.loadAllBudgets();
    });

    this.loadAllCategories();
  }

  onMonthChange(event: { month: number; year: number }): void {
    this.selectedMonth.set(event.month);
    this.selectedYear.set(event.year);
  }

  async loadData(): Promise<void> {
    const version = ++this.loadVersion;
    this.loading.set(true);
    this.error.set(null);
    const month = `${this.selectedYear()}-${String(this.selectedMonth()).padStart(2, '0')}`;
    try {
      let data: BudgetOverview | BudgetHistory;
      if (this.isCurrentMonth() && this.showInactive()) {
        const budgets = await firstValueFrom(this.budgetService.getAll(true));
        const overview = await firstValueFrom(this.budgetService.getOverview());
        const inactiveItems = budgets
          .filter((b) => !b.actif)
          .map((b) => ({
            budgetId: b.id,
            categoryId: b.category.id,
            categoryNom: b.category.nom,
            categoryIcone: b.category.icone,
            categoryCouleur: b.category.couleur,
            montantBudget: b.montant,
            montantBudgetNormalise: b.montant,
            currency: b.currency,
            montantDepense: b.spent,
            percentage: 0,
            frequence: b.frequence,
            actif: false,
          })) as unknown as BudgetItem[];
        data = {
          ...overview,
          items: [...overview.items, ...inactiveItems] as BudgetOverview['items'],
        };
      } else if (this.isCurrentMonth()) {
        data = await firstValueFrom(this.budgetService.getOverview());
      } else {
        data = await firstValueFrom(this.budgetService.getHistory(month));
      }
      if (version !== this.loadVersion) return;
      this.monthData.set(data);
    } catch (err) {
      if (version !== this.loadVersion) return;
      if (isDevMode()) console.error('Failed to load budget data', err);
      this.error.set(
        this.isCurrentMonth()
          ? 'Impossible de charger les budgets'
          : "Impossible de charger l'historique des budgets",
      );
    } finally {
      if (version !== this.loadVersion) return;
      this.loading.set(false);
    }
  }

  toggleInactive(): void {
    this.showInactive.update((v) => !v);
    this.loadData();
  }

  private async loadAllBudgets(): Promise<void> {
    try {
      const data = await firstValueFrom(this.budgetService.getAll());
      this.allBudgets.set(data);
    } catch (err) {
      if (isDevMode()) console.error('Failed to load all budgets', err);
    }
  }

  private async loadAllCategories(): Promise<void> {
    try {
      const data = await firstValueFrom(this.categoryService.getAll());
      this.allCategories.set(data);
    } catch (err) {
      if (isDevMode()) console.error('Failed to load categories', err);
    }
  }

  onShowUnbudgeted(): void {
    const month = `${this.selectedYear()}-${String(this.selectedMonth()).padStart(2, '0')}`;
    this.router.navigate(['/budgets/details'], {
      queryParams: { showUnbudgeted: 'true', month },
    });
  }

  onChartClick(): void {
    const month = `${this.selectedYear()}-${String(this.selectedMonth()).padStart(2, '0')}`;
    this.router.navigate(['/budgets/details'], { queryParams: { month } });
  }

  onCreate(): void {
    this.modalService.openModal('budget');
  }

  async onEdit(item: BudgetOverviewItem): Promise<void> {
    try {
      const budget = await firstValueFrom(this.budgetService.getById(item.budgetId));
      this.modalService.openModal('budget', budget);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load budget for edit', err);
      }
    }
  }

  async onDelete(item: BudgetOverviewItem): Promise<void> {
    if (confirm('Supprimer ce budget ?')) {
      try {
        await firstValueFrom(this.budgetService.delete(item.budgetId));
      } catch (err) {
        if (isDevMode()) console.error('Failed to delete budget', err);
      }
    }
  }
}
