import { Pipe, PipeTransform, inject } from '@angular/core';
import { LanguageService } from '../../core/services/language';

// Date courte relative des formulaires de transaction, d'abonnement et de
// dette, qui en portaient chacun une copie identique (KKS-373).
// Impure : un pipe pur memorise sur l'identite des arguments et ne
// rappellerait jamais `transform` au seul changement de langue.
@Pipe({ name: 'shortDate', standalone: true, pure: false })
export class ShortDatePipe implements PipeTransform {
  private readonly languageService = inject(LanguageService);

  transform(value: string): string {
    if (!value) return '';
    const date = new Date(value + 'T00:00:00');
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diff = date.getTime() - today.getTime();
    const days = Math.round(diff / 86400000);
    if (days === 0) return "Aujourd'hui";
    if (days === -1) return 'Hier';
    if (days === 1) return 'Demain';
    return date.toLocaleDateString(this.languageService.displayLocale(), {
      day: 'numeric',
      month: 'short',
    });
  }
}
