import { Pipe, PipeTransform, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';

import { LanguageService } from '../../core/services/language';
import { categoryDisplayName } from '../utils/category-name.utils';

// Impure (KKS-395, D8, precedent amount.pipe / relative-date.pipe) : un pipe
// pur memorise sur l'identite de `nom`/`systemKey` et ne rappellerait jamais
// `transform` au seul changement de langue — `activeLanguage()` n'en fait
// pas partie.
@Pipe({ name: 'categoryName', standalone: true, pure: false })
export class CategoryNamePipe implements PipeTransform {
  private readonly languageService = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);

  transform(nom: string | null | undefined, systemKey?: string | null): string {
    return categoryDisplayName(
      nom ?? '',
      systemKey,
      this.transloco,
      this.languageService.activeLanguage(),
    );
  }
}
