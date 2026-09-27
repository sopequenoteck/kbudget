import { Pipe, PipeTransform, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { LanguageService } from '../../core/services/language';

// Cache par locale (KKS-373, D8) : le format long change de langue sans
// reconstruire un `Intl.DateTimeFormat` a chaque rendu.
const longDateFormatterCache = new Map<string, Intl.DateTimeFormat>();

const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;

function getLongDateFormatter(locale: string): Intl.DateTimeFormat {
  let formatter = longDateFormatterCache.get(locale);
  if (!formatter) {
    formatter = new Intl.DateTimeFormat(locale, {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
    longDateFormatterCache.set(locale, formatter);
  }
  return formatter;
}

// Impure (KKS-373, D8) : un pipe pur memorise sur l'identite de `value` et ne
// rappellerait jamais `transform` au seul changement de langue.
@Pipe({ name: 'relativeDate', standalone: true, pure: false })
export class RelativeDatePipe implements PipeTransform {
  private readonly languageService = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);

  transform(value: string | null | undefined): string {
    if (!value) {
      return '';
    }

    // Date seule (`AAAA-MM-JJ`) lue a minuit local : `new Date` la lirait a
    // minuit UTC, soit la veille dans un fuseau en retard sur UTC.
    const date = new Date(DATE_ONLY.test(value) ? `${value}T00:00:00` : value);
    if (isNaN(date.getTime())) {
      return '';
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const target = new Date(date);
    target.setHours(0, 0, 0, 0);

    const diffMs = today.getTime() - target.getTime();
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return this.transloco.translate('common.value.today');
    }

    if (diffDays === 1) {
      return this.transloco.translate('common.value.yesterday');
    }

    if (diffDays === -1) {
      return this.transloco.translate('common.value.tomorrow');
    }

    if (diffDays >= 2 && diffDays <= 7) {
      return this.transloco.translate('common.value.daysAgo', { count: diffDays });
    }

    if (diffDays >= 8 && diffDays <= 30) {
      const weeks = Math.floor(diffDays / 7);
      return this.transloco.translate('common.value.weeksAgo', { count: weeks });
    }

    return getLongDateFormatter(this.languageService.displayLocale()).format(date);
  }
}
