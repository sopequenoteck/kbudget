import { Pipe, PipeTransform, inject } from '@angular/core';
import { ConversionService } from '../../core/services/conversion';
import { LanguageService } from '../../core/services/language';

const CURRENCY_SYMBOLS: Record<string, string> = {
  EUR: '€',
  XOF: 'CFA',
  USD: '$',
  GBP: '£',
  CHF: 'CHF',
  CAD: 'CA$',
  MAD: 'MAD',
};

// Impure (KKS-373, D8) : un pipe pur memorise sur l'identite des arguments et
// ne rappellerait jamais `transform` au seul changement de langue.
@Pipe({
  name: 'convertAmount',
  standalone: true,
  pure: false,
})
export class ConvertAmountPipe implements PipeTransform {
  private readonly conversionService = inject(ConversionService);
  private readonly languageService = inject(LanguageService);

  transform(amount: number, fromCurrency: string, toCurrency: string): string {
    if (!fromCurrency || fromCurrency === toCurrency) return '';

    const converted = this.conversionService.convert(amount, fromCurrency, toCurrency);
    if (converted === null) return '';

    const symbol = CURRENCY_SYMBOLS[toCurrency] ?? toCurrency;
    const decimals = toCurrency === 'XOF' ? 0 : 2;
    const formatted = converted.toLocaleString(this.languageService.displayLocale(), {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    });

    return `~ ${formatted} ${symbol}`;
  }
}
