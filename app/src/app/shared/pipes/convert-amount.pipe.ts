import { Pipe, PipeTransform, inject } from '@angular/core';
import { ConversionService } from '../../core/services/conversion';
import { LanguageService } from '../../core/services/language';
import { formatCurrencyAmount } from '../utils/locale-format.utils';

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

    return `~ ${formatCurrencyAmount(converted, toCurrency, this.languageService.displayLocale())}`;
  }
}
