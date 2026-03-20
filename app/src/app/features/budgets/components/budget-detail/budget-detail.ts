import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { BudgetService } from '../../../../core/services/budget';
import {
  type BudgetOverview,
  type BudgetHistory,
  type BudgetItem,
  type UnbudgetedItem,
  budgetAmount,
} from '../../../../core/models/budget.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { MonthSelector } from '../month-selector';
import { BudgetChart } from '../budget-chart';

@Component({
  selector: 'app-budget-detail',
  standalone: true,
  imports: [RouterLink, AmountPipe, MonthSelector, BudgetChart],
  template: `
    <div class="detail-header">
      <a class="btn-back" routerLink="/budgets">&#9664; Retour</a>
      <h2 class="detail-header__title">Détails budget</h2>
    </div>

    <app-month-selector
      [month]="selectedMonth()"
      [year]="selectedYear()"
      (monthChange)="onMonthChange($event)"
    />

    @if (loading()) {
      <div class="state-loading">
        <div class="spinner"></div>
        <span>Chargement...</span>
      </div>
    } @else if (error()) {
      <div class="state-error">
        <span>{{ error() }}</span>
        <button class="btn-outline" (click)="loadData()">Réessayer</button>
      </div>
    } @else if (!monthData()) {
      <div class="state-empty">
        <span>Aucune donnée pour cette période</span>
      </div>
    } @else {
      <div class="detail-summary">
        <div class="detail-summary__row">
          <span class="detail-summary__label">Total dépensé</span>
          <span class="detail-summary__value">
            {{ monthData()!.totalSpent | amount: null : monthData()!.currency }}
            /
            {{ monthData()!.totalBudget | amount: null : monthData()!.currency }}
          </span>
        </div>
        <div class="budget-bar">
          <div
            class="budget-bar__fill"
            [style.width.%]="Math.min(monthData()!.percentage, 100)"
            [class.over-budget]="monthData()!.percentage > 100"
          ></div>
        </div>
        <span class="detail-summary__pct">{{ monthData()!.percentage.toFixed(1) }}%</span>
      </div>

      <app-budget-chart
        [items]="items()"
        [totalSpent]="monthData()!.totalSpent"
        [currency]="monthData()!.currency"
        [unbudgetedTotal]="unbudgetedTotal()"
      />

      @if (showUnbudgeted() && unbudgetedItems().length > 0) {
        <div class="unbudgeted-section">
          <h3 class="unbudgeted-section__title">Dépenses non budgétées</h3>
          <ul class="budget-list">
            @for (item of unbudgetedItems(); track item.categoryId) {
              <li class="budget-item">
                <div class="budget-item__header">
                  <span class="budget-item__icon">{{ item.categoryIcone }}</span>
                  <span class="budget-item__name">{{ item.categoryNom }}</span>
                  <span class="budget-item__amount">
                    {{ item.montantDepense | amount: null : monthData()!.currency }}
                  </span>
                </div>
              </li>
            }
          </ul>
        </div>
      }

      @if (items().length === 0) {
        <div class="state-empty">
          <span>Aucun budget pour cette période</span>
        </div>
      } @else {
        <ul class="budget-list">
          @for (item of items(); track item.categoryId) {
            <li class="budget-item">
              <div class="budget-item__header">
                <span class="budget-item__icon">{{ item.categoryIcone }}</span>
                <span class="budget-item__name">{{ item.categoryNom }}</span>
                <div class="budget-item__right">
                  <span
                    class="budget-item__amount"
                    [class.over-budget]="item.percentage > 100"
                  >
                    {{ item.montantDepense | amount: null : monthData()!.currency }}
                    /
                    {{ budgetAmount(item) | amount: null : monthData()!.currency }}
                  </span>
                  <span
                    class="budget-item__pct"
                    [class.over-budget]="item.percentage > 100"
                  >
                    {{ item.percentage.toFixed(1) }}%
                  </span>
                </div>
              </div>
              <div class="budget-bar">
                <div
                  class="budget-bar__fill"
                  [style.width.%]="Math.min(item.percentage, 100)"
                  [style.background-color]="item.categoryCouleur"
                  [class.over-budget]="item.percentage > 100"
                ></div>
              </div>
            </li>
          }
        </ul>
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

    .detail-header {
      display: flex;
      align-items: center;
      gap: var(--space-3);

      &__title {
        font-size: var(--font-size-lg);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
        margin: 0;
        flex: 1;
      }
    }

    .btn-back {
      display: flex;
      align-items: center;
      gap: var(--space-2);
      padding: var(--space-2) var(--space-3);
      border: none;
      border-radius: var(--radius-lg);
      background-color: var(--surface-default);
      color: var(--text-primary);
      font-size: var(--font-size-sm);
      font-weight: var(--font-weight-medium);
      cursor: pointer;
      text-decoration: none;
      box-shadow: var(--shadow-sm);
      transition:
        background-color var(--duration-normal) var(--easing-default),
        box-shadow var(--duration-normal) var(--easing-default);

      &:hover {
        background-color: var(--hover-bg);
        box-shadow: var(--shadow-md);
      }
    }

    .detail-summary {
      display: flex;
      flex-direction: column;
      gap: var(--space-2);
      padding: var(--space-4);
      background-color: var(--surface-default);
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-md);

      &__row {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      &__label {
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-medium);
        color: var(--text-secondary);
      }

      &__value {
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
      }

      &__pct {
        font-size: var(--font-size-xs);
        color: var(--text-tertiary);
        text-align: right;
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

      &__right {
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: var(--space-1);
        flex-shrink: 0;
      }

      &__amount {
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-semibold);
        color: var(--text-secondary);
        white-space: nowrap;

        &.over-budget {
          color: var(--color-expense);
        }
      }

      &__pct {
        font-size: var(--font-size-xs);
        color: var(--text-tertiary);
        white-space: nowrap;

        &.over-budget {
          color: var(--color-expense);
        }
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

        &.over-budget {
          background-color: var(--color-expense);
        }
      }
    }

    .btn-outline {
      padding: var(--space-2) var(--space-4);
      border: 1px solid var(--border-default);
      border-radius: var(--radius-lg);
      background-color: transparent;
      color: var(--text-primary);
      font-size: var(--font-size-sm);
      cursor: pointer;
      transition:
        background-color var(--duration-normal) var(--easing-default),
        border-color var(--duration-normal) var(--easing-default);

      &:hover {
        background-color: var(--hover-bg);
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

    .unbudgeted-section {
      display: flex;
      flex-direction: column;
      gap: var(--space-3);

      &__title {
        font-size: var(--font-size-base);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
        margin: 0;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetDetail {
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly budgetService = inject(BudgetService);

  readonly Math = Math;
  readonly budgetAmount = budgetAmount;

  readonly selectedMonth = signal(new Date().getMonth() + 1);
  readonly selectedYear = signal(new Date().getFullYear());
  readonly monthData = signal<BudgetOverview | BudgetHistory | null>(null);
  readonly loading = signal(true);
  readonly error = signal<string | null>(null);

  readonly showUnbudgeted = signal(false);

  readonly isCurrentMonth = computed(() => {
    const now = new Date();
    return (
      this.selectedMonth() === now.getMonth() + 1 &&
      this.selectedYear() === now.getFullYear()
    );
  });

  readonly items = computed<BudgetItem[]>(() => this.monthData()?.items ?? []);

  readonly unbudgetedItems = computed<UnbudgetedItem[]>(
    () => this.monthData()?.unbudgetedItems ?? [],
  );

  readonly unbudgetedTotal = computed(() => this.monthData()?.unbudgetedTotal ?? 0);

  constructor() {
    const queryParams = this.route.snapshot.queryParamMap;

    const monthParam = queryParams.get('month');
    if (monthParam) {
      const parts = monthParam.split('-');
      if (parts.length === 2) {
        const year = parseInt(parts[0], 10);
        const month = parseInt(parts[1], 10);
        if (!isNaN(year) && !isNaN(month) && month >= 1 && month <= 12) {
          this.selectedYear.set(year);
          this.selectedMonth.set(month);
        }
      }
    }

    const showUnbudgetedParam = queryParams.get('showUnbudgeted');
    if (showUnbudgetedParam === 'true') {
      this.showUnbudgeted.set(true);
    }

    effect(() => {
      this.selectedMonth();
      this.selectedYear();
      this.loadData();
    });
  }

  onMonthChange(event: { month: number; year: number }): void {
    this.selectedMonth.set(event.month);
    this.selectedYear.set(event.year);
    const m = `${event.year}-${String(event.month).padStart(2, '0')}`;
    this.router.navigate([], { queryParams: { month: m }, replaceUrl: true });
  }

  async loadData(): Promise<void> {
    this.loading.set(true);
    this.error.set(null);
    const month = `${this.selectedYear()}-${String(this.selectedMonth()).padStart(2, '0')}`;
    try {
      const data = this.isCurrentMonth()
        ? await firstValueFrom(this.budgetService.getOverview())
        : await firstValueFrom(this.budgetService.getHistory(month));
      this.monthData.set(data);
    } catch (err) {
      if (isDevMode()) console.error('Failed to load budget data', err);
      this.error.set(
        this.isCurrentMonth()
          ? 'Impossible de charger les budgets'
          : "Impossible de charger l'historique des budgets",
      );
    } finally {
      this.loading.set(false);
    }
  }
}
