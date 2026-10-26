import { Component, ChangeDetectionStrategy, input, output, inject } from '@angular/core';
import { CurrencyService } from '../../../core/services/currency';

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
        gap: var(--k-space-1);
        overflow-x: auto;
      }
      .pill {
        padding: var(--k-space-1) var(--k-space-3);
        border-radius: var(--k-radius-round);
        border: 1px solid var(--k-border-default);
        cursor: pointer;
        font-size: var(--k-font-size-xs);
        font-weight: var(--k-font-weight-medium);
        background: none;
        color: var(--k-text-secondary);
        white-space: nowrap;
        transition: all var(--duration-fast);
      }
      .pill.active {
        background-color: var(--k-color-primary);
        border-color: var(--k-color-primary);
        color: var(--k-color-primary-contrast);
        font-weight: var(--k-font-weight-semibold);
      }
    `,
  ],
})
export class CurrencyPillSelector {
  private readonly currencyService = inject(CurrencyService);

  readonly currencies = input.required<string[]>();
  readonly activeCurrency = input.required<string>();
  readonly currencyChange = output<string>();

  private readonly _init = this.currencyService.loadIfEmpty();

  getCurrencySymbol(code: string): string {
    const info = this.currencyService.currencies().find(c => c.code === code);
    return info?.symbol ?? code;
  }
}
