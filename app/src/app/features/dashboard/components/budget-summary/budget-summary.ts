import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { BudgetService } from '../../../../core/services/budget';
import { ModalService } from '../../../../core/services/modal.service';
import { type BudgetOverviewItem } from '../../../../core/models/budget.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';

@Component({
  selector: 'app-budget-summary',
  standalone: true,
  imports: [RouterLink, AmountPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="dashboard-section__header">
      <h2 class="dashboard-section__title">Budgets</h2>
      <a class="dashboard-section__link" routerLink="/budgets">Voir tout</a>
    </div>

    @if (loading()) {
      <div class="budget-summary__state">
        <div class="spinner"></div>
      </div>
    } @else if (error()) {
      <div class="budget-summary__state">
        <p>{{ error() }}</p>
        <button class="btn-outline" (click)="loadOverview()">Réessayer</button>
      </div>
    } @else if (!overview() || overview()!.length === 0) {
      <div class="budget-summary__state">
        <p>Aucun budget</p>
        <button class="btn-outline" (click)="openCreateBudget()">Créer un budget</button>
      </div>
    } @else {
      <ul class="budget-summary__list">
        @for (item of topItems(); track item.budgetId) {
          <li class="budget-item">
            <div class="budget-item__header">
              <span class="budget-item__icon">{{ item.categoryIcone }}</span>
              <span class="budget-item__name">{{ item.categoryNom }}</span>
              <span
                class="budget-item__amounts"
                [class.over-budget]="item.percentage > 100"
              >
                {{ item.montantDepense | amount: null : overviewCurrency() }}
                /
                {{ item.montantBudgetNormalise | amount: null : overviewCurrency() }}
              </span>
            </div>
            <div class="budget-bar">
              <div
                class="budget-bar__fill"
                [style.width.%]="min(item.percentage, 100)"
                [style.background-color]="item.categoryCouleur"
              ></div>
            </div>
          </li>
        }
      </ul>
      @if (totalBudget() > 0) {
        <div class="budget-summary__footer">
          <span class="budget-summary__footer-label">Total</span>
          <span class="budget-summary__footer-value">
            {{ totalSpent() | amount: null : overviewCurrency() }}
            /
            {{ totalBudget() | amount: null : overviewCurrency() }}
          </span>
        </div>
      }
    }
  `,
  styles: `
    :host {
      display: flex;
      flex-direction: column;
      gap: var(--space-3);
    }

    .budget-summary__state {
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

    .budget-summary__list {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
      gap: var(--space-3);
      background-color: var(--surface-default);
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-sm);
      padding: var(--space-4);
    }

    .budget-item {
      display: flex;
      flex-direction: column;
      gap: var(--space-2);

      &:not(:last-child) {
        padding-bottom: var(--space-3);
        border-bottom: 1px solid var(--border-default);
      }
    }

    .budget-item__header {
      display: flex;
      align-items: center;
      gap: var(--space-2);
    }

    .budget-item__icon {
      font-size: var(--font-size-base);
      line-height: 1;
      flex-shrink: 0;
    }

    .budget-item__name {
      flex: 1;
      font-size: var(--font-size-sm);
      font-weight: var(--font-weight-medium);
      color: var(--text-primary);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .budget-item__amounts {
      font-size: var(--font-size-sm);
      color: var(--text-secondary);
      white-space: nowrap;
      flex-shrink: 0;

      &.over-budget {
        color: var(--color-expense);
        font-weight: var(--font-weight-semibold);
      }
    }

    .budget-bar {
      width: 100%;
      height: 6px;
      background-color: var(--border-default);
      border-radius: var(--radius-round);
      overflow: hidden;
    }

    .budget-bar__fill {
      height: 100%;
      border-radius: var(--radius-round);
      transition: width var(--duration-normal) var(--easing-default);
      min-width: 0;
    }

    .budget-summary__footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: var(--space-2) 0;
      border-top: 1px solid var(--border-default);
    }

    .budget-summary__footer-label {
      font-size: var(--font-size-sm);
      font-weight: var(--font-weight-medium);
      color: var(--text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .budget-summary__footer-value {
      font-size: var(--font-size-sm);
      font-weight: var(--font-weight-semibold);
      color: var(--text-primary);
    }
  `,
})
export class BudgetSummary {
  private readonly budgetService = inject(BudgetService);
  private readonly modalService = inject(ModalService);

  readonly overview = signal<BudgetOverviewItem[] | null>(null);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);

  readonly topItems = computed(() => {
    const items = this.overview();
    if (!items) return [];
    return [...items].sort((a, b) => b.percentage - a.percentage).slice(0, 5);
  });

  readonly totalBudget = computed(() => {
    const items = this.overview();
    if (!items) return 0;
    return items.reduce((sum, item) => sum + item.montantBudgetNormalise, 0);
  });

  readonly totalSpent = computed(() => {
    const items = this.overview();
    if (!items) return 0;
    return items.reduce((sum, item) => sum + item.montantDepense, 0);
  });

  readonly overviewCurrency = signal<string>('EUR');

  constructor() {
    effect(() => {
      this.budgetService.refreshTrigger();
      this.loadOverview();
    });
  }

  async loadOverview(): Promise<void> {
    this.loading.set(true);
    this.error.set(null);
    try {
      const data = await firstValueFrom(this.budgetService.getOverview());
      this.overview.set(data.items);
      this.overviewCurrency.set(data.currency);
    } catch (err) {
      if (isDevMode()) console.error('Failed to load budget overview', err);
      this.error.set('Erreur de chargement des budgets');
    } finally {
      this.loading.set(false);
    }
  }

  openCreateBudget(): void {
    this.modalService.openModal('budget');
  }

  min(a: number, b: number): number {
    return Math.min(a, b);
  }
}
