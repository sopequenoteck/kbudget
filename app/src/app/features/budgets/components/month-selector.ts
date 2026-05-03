import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { APP_LOCALE } from '../../../core/constants/locale.constants';

@Component({
  selector: 'app-month-selector',
  standalone: true,
  imports: [],
  template: `
    <div class="month-selector">
      <button class="month-selector__btn" (click)="prevMonth()">&#9664;</button>
      <span class="month-selector__label">{{ monthLabel() }}</span>
      <button class="month-selector__btn" (click)="nextMonth()">&#9654;</button>
    </div>
  `,
  styles: `
    .month-selector {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: var(--space-4);

      &__btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 44px;
        height: 44px;
        min-width: 44px;
        padding: 0;
        border: none;
        border-radius: var(--radius-round);
        background-color: var(--surface-default);
        color: var(--text-primary);
        font-size: var(--font-size-base);
        box-shadow: var(--shadow-sm);
        cursor: pointer;
        transition:
          background-color var(--duration-normal) var(--easing-default),
          box-shadow var(--duration-normal) var(--easing-default);

        &:hover {
          background-color: var(--hover-bg);
          box-shadow: var(--shadow-md);
        }
      }

      &__label {
        font-size: var(--font-size-lg);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
        text-transform: capitalize;
        min-width: 160px;
        text-align: center;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MonthSelector {
  readonly month = input.required<number>();
  readonly year = input.required<number>();
  readonly monthChange = output<{ month: number; year: number }>();

  readonly monthLabel = computed(() =>
    new Date(this.year(), this.month() - 1).toLocaleDateString(APP_LOCALE, {
      month: 'long',
      year: 'numeric',
    }),
  );

  prevMonth(): void {
    let month = this.month();
    let year = this.year();
    if (month === 1) {
      month = 12;
      year -= 1;
    } else {
      month -= 1;
    }
    this.monthChange.emit({ month, year });
  }

  nextMonth(): void {
    let month = this.month();
    let year = this.year();
    if (month === 12) {
      month = 1;
      year += 1;
    } else {
      month += 1;
    }
    this.monthChange.emit({ month, year });
  }
}
