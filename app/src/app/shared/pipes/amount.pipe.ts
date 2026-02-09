import { Pipe, PipeTransform } from '@angular/core';

const POSITIVE_TYPES = ['RECETTE', 'ON_ME_DOIT'];
const NEGATIVE_TYPES = ['DEPENSE', 'JE_DOIS'];

const formatter = new Intl.NumberFormat('fr-FR', {
  style: 'currency',
  currency: 'EUR',
  signDisplay: 'never',
});

@Pipe({ name: 'amount', pure: true })
export class AmountPipe implements PipeTransform {
  transform(value: number | null | undefined, type?: string | null): string {
    if (value == null) {
      return '';
    }

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
