import { Component, ChangeDetectionStrategy, input, output } from '@angular/core';

@Component({
  selector: 'app-currency-pill-selector',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (currencies().length > 1) {
      <div class="pill-container">
        @for (currency of currencies(); track currency) {
          <button
            class="pill"
            [class.active]="currency === activeCurrency()"
            (click)="currencyChange.emit(currency)"
          >
            {{ getCurrencySymbol(currency) }}
          </button>
        }
      </div>
    }
  `,
  styles: [
    `
      .pill-container {
        display: flex;
        gap: var(--space-2);
        overflow-x: auto;
        padding: var(--space-1) 0;
      }
      .pill {
        padding: var(--space-2) var(--space-4);
        border-radius: var(--radius-round);
        border: none;
        cursor: pointer;
        font-size: var(--text-sm);
        font-weight: 500;
        background: var(--color-surface-container-highest);
        color: var(--color-on-surface-variant);
        white-space: nowrap;
        transition: all 200ms ease;
      }
      .pill.active {
        background: var(--color-primary);
        color: var(--color-on-primary);
        font-weight: 600;
      }
    `,
  ],
})
export class CurrencyPillSelector {
  readonly currencies = input.required<string[]>();
  readonly activeCurrency = input.required<string>();
  readonly currencyChange = output<string>();

  private readonly symbolMap: Record<string, string> = {
    EUR: '€',
    XOF: 'CFA',
    USD: '$',
    GBP: '£',
    CHF: 'CHF',
    CAD: 'CA$',
    MAD: 'MAD',
  };

  getCurrencySymbol(currency: string): string {
    return this.symbolMap[currency] ?? currency;
  }
}
