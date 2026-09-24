import { Pipe, PipeTransform, inject } from '@angular/core';
import { LanguageService } from '../../core/services/language';

// Cache par locale (KKS-373, D8) : le format long change de langue sans
// reconstruire un `Intl.DateTimeFormat` a chaque rendu.
const longDateFormatterCache = new Map<string, Intl.DateTimeFormat>();

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

  transform(value: string | null | undefined): string {
    if (!value) {
      return '';
    }

    const date = new Date(value);
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
      return "Aujourd'hui";
    }

    if (diffDays === 1) {
      return 'Hier';
    }

    if (diffDays === -1) {
      return 'Demain';
    }

    if (diffDays >= 2 && diffDays <= 7) {
      return `il y a ${diffDays} jours`;
    }

    if (diffDays >= 8 && diffDays <= 30) {
      const weeks = Math.floor(diffDays / 7);
      return `il y a ${weeks} semaine${weeks > 1 ? 's' : ''}`;
    }

    return getLongDateFormatter(this.languageService.displayLocale()).format(date);
  }
}
