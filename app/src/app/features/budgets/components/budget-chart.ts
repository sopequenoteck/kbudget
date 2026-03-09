import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { BaseChartDirective } from 'ng2-charts';
import {
  Chart,
  DoughnutController,
  ArcElement,
  Tooltip,
  Legend,
  type ChartData,
  type ChartOptions,
} from 'chart.js';

import { type BudgetItem } from '../../../core/models/budget.model';

Chart.register(DoughnutController, ArcElement, Tooltip, Legend);

@Component({
  selector: 'app-budget-chart',
  standalone: true,
  imports: [BaseChartDirective],
  template: `
    @if (hasExpenses()) {
      <section class="chart-section" [class.clickable]="clickable()" (click)="onClick()">
        <h3 class="chart-section__title">Répartition des dépenses</h3>
        <div class="chart-container">
          <canvas baseChart type="doughnut" [data]="chartData()" [options]="chartOptions()"></canvas>
        </div>
        @if (clickable()) {
          <p class="chart-section__hint">Appuyez pour voir les détails</p>
        }
      </section>
    }
  `,
  styles: `
    .chart-section {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: var(--space-3);
      padding: var(--space-4);
      background-color: var(--surface-default);
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-sm);
      transition: box-shadow var(--duration-normal) var(--easing-default);

      &.clickable {
        cursor: pointer;

        &:hover {
          box-shadow: var(--shadow-md);
        }
      }

      &__title {
        font-size: var(--font-size-base);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
        margin: 0;
      }

      &__hint {
        font-size: var(--font-size-xs);
        color: var(--text-tertiary);
        margin: 0;
      }
    }

    .chart-container {
      width: 250px;
      height: 250px;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetChart {
  readonly items = input.required<BudgetItem[]>();
  readonly totalSpent = input.required<number>();
  readonly currency = input<string>('EUR');
  readonly clickable = input<boolean>(false);
  readonly unbudgetedTotal = input<number>(0);
  readonly chartClicked = output<void>();

  readonly hasExpenses = computed(
    () => this.items().some((i) => i.montantDepense > 0) || this.unbudgetedTotal() > 0,
  );

  readonly chartData = computed<ChartData<'doughnut'>>(() => {
    const items = this.items();
    const labels: string[] = items.map((i) => i.categoryNom);
    const data: number[] = items.map((i) => i.montantDepense);
    const colors: string[] = items.map((i) => i.categoryCouleur);

    if (this.unbudgetedTotal() > 0) {
      labels.push('Autre');
      data.push(this.unbudgetedTotal());
      colors.push('#9ca3af');
    }

    if (labels.length === 0) {
      return { labels: [], datasets: [{ data: [] }] };
    }
    return {
      labels,
      datasets: [
        {
          data,
          backgroundColor: colors,
          borderWidth: 0,
        },
      ],
    };
  });

  readonly chartOptions = computed<ChartOptions<'doughnut'>>(() => {
    const total = this.totalSpent();
    const currency = this.currency();
    return {
      responsive: true,
      maintainAspectRatio: true,
      cutout: '65%',
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => {
              const value = ctx.parsed;
              const pct = total > 0 ? ((value / total) * 100).toFixed(1) : '0';
              return `${ctx.label}: ${value.toFixed(2)} ${currency} (${pct}%)`;
            },
          },
        },
      },
    };
  });

  onClick(): void {
    if (this.clickable()) {
      this.chartClicked.emit();
    }
  }
}
