import { Pipe, PipeTransform, inject } from '@angular/core';
import { ConversionService } from '../../core/services/conversion';
import { APP_LOCALE } from '../../core/constants/locale.constants';

const CURRENCY_SYMBOLS: Record<string, string> = {
  EUR: '€',
  XOF: 'CFA',
  USD: '$',
  GBP: '£',
  CHF: 'CHF',
  CAD: 'CA$',
  MAD: 'MAD',
};

@Pipe({
  name: 'convertAmount',
  standalone: true,
  pure: true,
})
export class ConvertAmountPipe implements PipeTransform {
  private readonly conversionService = inject(ConversionService);

  transform(amount: number, fromCurrency: string, toCurrency: string): string {
    if (!fromCurrency || fromCurrency === toCurrency) return '';

    const converted = this.conversionService.convert(amount, fromCurrency, toCurrency);
    if (converted === null) return '';

    const symbol = CURRENCY_SYMBOLS[toCurrency] ?? toCurrency;
    const decimals = toCurrency === 'XOF' ? 0 : 2;
    const formatted = converted.toLocaleString(APP_LOCALE, {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    });

    return `~ ${formatted} ${symbol}`;
  }
}
