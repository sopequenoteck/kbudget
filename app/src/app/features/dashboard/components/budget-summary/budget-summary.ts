import { ChangeDetectionStrategy, Component, effect, input, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';

import { type BudgetOverview, type BudgetOverviewItem } from '../../../../core/models/budget.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { CategoryNamePipe } from '../../../../shared/pipes/category-name.pipe';

@Component({
  selector: 'app-budget-summary',
  standalone: true,
  imports: [AmountPipe, CategoryNamePipe, TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (overview(); as ov) {
      <div class="budget-summary__subtitle">
        <span>{{ 'budgets.summary.monthlyInCurrency' | transloco: { currency: ov.currency } }}</span>
        <span>{{ ov.totalSpent | amount: null : ov.currency }} / {{ ov.totalBudget | amount: null : ov.currency }}</span>
      </div>
    }

    @if (isLoading()) {
      <div class="budget-summary__state">
        @for (item of skeletonItems; track $index) {
          <div class="skeleton-item">
            <div class="skeleton-circle"></div>
            <div class="skeleton-lines">
              <div class="skeleton-line skeleton-line--title"></div>
              <div class="skeleton-line skeleton-line--subtitle"></div>
            </div>
            <div class="skeleton-lines skeleton-lines--right">
              <div class="skeleton-line skeleton-line--value"></div>
            </div>
          </div>
        }
      </div>
    } @else {
      <ul class="budget-summary__list">
        @for (item of items(); track item.budgetId) {
          <li class="budget-item">
            <div class="budget-item__header">
              <span class="budget-item__icon">{{ item.categoryIcone }}</span>
              <span class="budget-item__name">{{ item.categoryNom | categoryName: item.categorySystemKey }}</span>
              <span
                class="budget-item__amounts"
                [class.over-budget]="item.percentage > 100"
              >
                {{ item.montantDepense | amount: null : item.currency }}
                /
                {{ item.montantBudgetNormalise | amount: null : item.currency }}
              </span>
            </div>
            <div class="budget-bar">
              <div
                class="budget-bar__fill"
                [class.budget-bar__fill--warning]="item.percentage >= 80 && item.percentage <= 100"
                [class.budget-bar__fill--exceeded]="item.percentage > 100"
                [class.budget-bar__fill--initial]="!animated()"
                [style.width.%]="min(item.percentage, 100)"
              ></div>
              @if (item.percentage > 100) {
                <div class="budget-bar__overflow-marker"></div>
              }
            </div>
          </li>
        }
      </ul>
    }
  `,
  styles: `
    :host {
      display: flex;
      flex-direction: column;
      gap: var(--k-space-3);
    }

    .budget-summary__subtitle {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin: 0;
      font-size: var(--k-font-size-xs);
      font-weight: var(--k-font-weight-medium);
      color: var(--k-text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .budget-summary__state {
      display: flex;
      flex-direction: column;
      gap: 0;
    }

    .budget-summary__list {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
      background-color: var(--k-surface-default);
      border-radius: var(--k-radius-xl);
      overflow: hidden;
    }

    .budget-item {
      display: flex;
      flex-direction: column;
      gap: var(--k-space-2);
      padding: var(--k-space-3) var(--k-space-4);
    }

    .budget-item__header {
      display: flex;
      align-items: center;
      gap: var(--k-space-2);
    }

    .budget-item__icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: var(--k-space-8);
      height: var(--k-space-8);
      font-size: var(--k-font-size-lg);
      background-color: var(--k-icon-circle-bg);
      border-radius: var(--k-radius-round);
      line-height: 1;
      flex-shrink: 0;
    }

    .budget-item__name {
      flex: 1;
      font-size: var(--k-font-size-sm);
      font-weight: var(--k-font-weight-medium);
      color: var(--k-text-primary);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .budget-item__amounts {
      font-size: var(--k-font-size-xs);
      color: var(--k-text-tertiary);
      white-space: nowrap;
      flex-shrink: 0;

      &.over-budget {
        color: var(--k-color-expense);
        font-weight: var(--k-font-weight-semibold);
      }
    }

    .budget-bar {
      position: relative;
      width: 100%;
      height: 4px;
      background-color: var(--k-border-default);
      border-radius: var(--k-radius-round);
      overflow: hidden;
    }

    .budget-bar__fill {
      height: 100%;
      border-radius: var(--k-radius-round);
      background-color: var(--k-color-income);
      opacity: 0.7;
      transition: width var(--duration-slow) var(--easing-out);
      min-width: 0;

      &.budget-bar__fill--initial {
        width: 0 !important;
      }

      &.budget-bar__fill--warning {
        background-color: var(--k-text-warning);
      }

      &.budget-bar__fill--exceeded {
        background-color: var(--k-color-expense);
      }
    }

    .budget-bar__overflow-marker {
      position: absolute;
      right: 0;
      top: 0;
      width: 3px;
      height: 100%;
      background-color: var(--k-color-expense);
      border-radius: 0 var(--k-radius-round) var(--k-radius-round) 0;
    }
  `,
})
export class BudgetSummary {
  readonly items = input.required<BudgetOverviewItem[]>();
  readonly overview = input<BudgetOverview | null>(null);
  readonly isLoading = input<boolean>(false);
  readonly animated = signal(false);
  readonly skeletonItems = Array(3);

  constructor() {
    effect(() => {
      if (this.items().length > 0 && !this.animated()) {
        setTimeout(() => this.animated.set(true), 0);
      }
    });
  }

  min(a: number, b: number): number {
    return Math.min(a, b);
  }
}
