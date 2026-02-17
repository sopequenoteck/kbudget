import { Pipe, PipeTransform } from '@angular/core';

const POSITIVE_TYPES = ['RECETTE', 'PRET'];
const NEGATIVE_TYPES = ['DEPENSE', 'EMPRUNT'];

const formatterCache = new Map<string, Intl.NumberFormat>();

function getFormatter(currency: string): Intl.NumberFormat {
  let formatter = formatterCache.get(currency);
  if (!formatter) {
    formatter = new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency,
      signDisplay: 'never',
    });
    formatterCache.set(currency, formatter);
  }
  return formatter;
}

@Pipe({ name: 'amount', pure: true })
export class AmountPipe implements PipeTransform {
  transform(value: number | null | undefined, type?: string | null, currency?: string | null): string {
    if (value == null) {
      return '';
    }

    const formatter = getFormatter(currency || 'EUR');
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
