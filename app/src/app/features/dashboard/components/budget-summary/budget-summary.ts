import { ChangeDetectionStrategy, Component, effect, input, signal } from '@angular/core';

import { type BudgetOverview, type BudgetOverviewItem } from '../../../../core/models/budget.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';

@Component({
  selector: 'app-budget-summary',
  standalone: true,
  imports: [AmountPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (overview(); as ov) {
      <div class="budget-summary__subtitle">
        <span>MENSUEL · EN {{ ov.currency }}</span>
        <span>{{ ov.totalSpent | amount: null : ov.currency }} / {{ ov.totalBudget | amount: null : ov.currency }}</span>
      </div>
    }

    @if (isLoading()) {
      <div class="budget-summary__state">
        <div class="spinner"></div>
      </div>
    } @else {
      <ul class="budget-summary__list">
        @for (item of items(); track item.budgetId) {
          <li class="budget-item">
            <div class="budget-item__header">
              <span class="budget-item__icon" [style.backgroundColor]="item.categoryCouleur + '26'">{{ item.categoryIcone }}</span>
              <span class="budget-item__name">{{ item.categoryNom }}</span>
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
      gap: var(--space-3);
    }

    .budget-summary__subtitle {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin: 0;
      font-size: var(--font-size-xs);
      font-weight: var(--font-weight-medium);
      color: var(--text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .budget-summary__state {
      display: flex;
      align-items: center;
      justify-content: center;
      padding: var(--space-6) var(--space-4);
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
      background-color: var(--surface-default);
      border-radius: var(--radius-xl);
      overflow: hidden;
    }

    .budget-item {
      display: flex;
      flex-direction: column;
      gap: var(--space-2);
      padding: var(--space-3) var(--space-4);
      border-bottom: 1px solid var(--border-default);

      &:last-child {
        border-bottom: none;
      }
    }

    .budget-item__header {
      display: flex;
      align-items: center;
      gap: var(--space-2);
    }

    .budget-item__icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: var(--space-6);
      height: var(--space-6);
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
      position: relative;
      width: 100%;
      height: 4px;
      background-color: var(--border-default);
      border-radius: var(--radius-round);
      overflow: hidden;
    }

    .budget-bar__fill {
      height: 100%;
      border-radius: var(--radius-round);
      background-color: var(--color-income);
      opacity: 0.7;
      transition: width var(--duration-slow) var(--easing-out);
      min-width: 0;

      &.budget-bar__fill--initial {
        width: 0 !important;
      }

      &.budget-bar__fill--warning {
        background-color: var(--text-warning);
      }

      &.budget-bar__fill--exceeded {
        background-color: var(--color-expense);
      }
    }

    .budget-bar__overflow-marker {
      position: absolute;
      right: 0;
      top: 0;
      width: 3px;
      height: 100%;
      background-color: var(--color-expense);
      border-radius: 0 var(--radius-round) var(--radius-round) 0;
    }
  `,
})
export class BudgetSummary {
  readonly items = input.required<BudgetOverviewItem[]>();
  readonly overview = input<BudgetOverview | null>(null);
  readonly isLoading = input<boolean>(false);
  readonly animated = signal(false);

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
