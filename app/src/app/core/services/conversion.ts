import { Injectable, computed, inject } from '@angular/core';

import { ExchangeRateService } from './exchange-rate';
import { PreferenceService } from './preference';

@Injectable({
  providedIn: 'root',
})
export class ConversionService {
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly preferenceService = inject(PreferenceService);

  readonly availableRates = computed(() => this.exchangeRateService.rates());

  /**
   * Convert an amount from one currency to another.
   * Returns null if no rate is available.
   */
  convert(amount: number, from: string, to: string): number | null {
    if (from === to) return amount;

    const rate = this.findRate(from, to);
    if (rate === null) return null;

    const converted = amount * rate;
    return this.roundForCurrency(converted, to);
  }

  /**
   * Check if conversion is possible between two currencies.
   */
  canConvert(from: string, to: string): boolean {
    if (from === to) return true;
    return this.findRate(from, to) !== null;
  }

  /**
   * Get the primary currency from preferences.
   */
  get primaryCurrency(): string {
    return this.preferenceService.primaryCurrency();
  }

  private findRate(from: string, to: string): number | null {
    const rates = this.exchangeRateService.rates();

    // Direct rate
    const direct = rates.find((r) => r.baseCurrency === from && r.targetCurrency === to);
    if (direct) return direct.rate;

    // Inverse rate
    const inverse = rates.find((r) => r.baseCurrency === to && r.targetCurrency === from);
    if (inverse) return 1 / inverse.rate;

    return null;
  }

  private roundForCurrency(amount: number, currency: string): number {
    // XOF has 0 decimal places, most others have 2
    const decimalPlaces = currency === 'XOF' ? 0 : 2;
    const factor = Math.pow(10, decimalPlaces);
    return Math.round(amount * factor) / factor;
  }
}
