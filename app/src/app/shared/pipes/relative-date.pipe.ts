import { Pipe, PipeTransform } from '@angular/core';

const longDateFormatter = new Intl.DateTimeFormat('fr-FR', {
  day: 'numeric',
  month: 'long',
  year: 'numeric',
});

@Pipe({ name: 'relativeDate', pure: true })
export class RelativeDatePipe implements PipeTransform {
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

    return longDateFormatter.format(date);
  }
}
