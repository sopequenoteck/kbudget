import { Pipe, PipeTransform, inject } from '@angular/core';
import { LanguageService } from '../../core/services/language';

const POSITIVE_TYPES = ['RECETTE', 'PRET'];
const NEGATIVE_TYPES = ['DEPENSE', 'EMPRUNT'];

// Cle locale+devise (KKS-373, D8) : un meme montant en XOF se formate
// differemment en fr-FR et en-GB, la cache doit distinguer les deux.
const formatterCache = new Map<string, Intl.NumberFormat>();

function getFormatter(locale: string, currency: string): Intl.NumberFormat {
  const key = `${locale}|${currency}`;
  let formatter = formatterCache.get(key);
  if (!formatter) {
    formatter = new Intl.NumberFormat(locale, {
      style: 'currency',
      currency,
      signDisplay: 'never',
    });
    formatterCache.set(key, formatter);
  }
  return formatter;
}

// Impure (KKS-373, D8) : un pipe pur memorise sur l'identite des arguments
// (value/type/currency) et ne rappellerait jamais `transform` au seul
// changement de langue — la locale lue via `LanguageService` ne fait pas
// partie de ces arguments.
@Pipe({ name: 'amount', standalone: true, pure: false })
export class AmountPipe implements PipeTransform {
  private readonly languageService = inject(LanguageService);

  transform(
    value: number | null | undefined,
    type?: string | null,
    currency?: string | null,
  ): string {
    if (value == null) {
      return '';
    }

    const formatter = getFormatter(this.languageService.displayLocale(), currency || 'EUR');
    const formatted = formatter.format(Math.abs(value));

    if (value === 0) {
      return formatted;
    }

    if (type && POSITIVE_TYPES.includes(type)) {
      return `+${formatted}`;
    }

    if (type && NEGATIVE_TYPES.includes(type)) {
      return `-${formatted}`;
    }

    if (value < 0) {
      return `-${formatted}`;
    }

    return formatted;
  }
}
