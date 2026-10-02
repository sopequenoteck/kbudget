import { ChangeDetectionStrategy, Component, inject, input, output } from '@angular/core';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { TranslocoPipe } from '@jsverse/transloco';
import {
  phosphorCheckCircle,
  phosphorLinkSimple,
  phosphorReceipt,
  phosphorWarningCircle,
} from '@ng-icons/phosphor-icons/regular';

import { LanguageService } from '../../../core/services/language';
import { ImportConfirmResult } from '../../../core/models/import.model';
import { AmountPipe } from '../../../shared/pipes/amount.pipe';
import {
  formatDayMonthLabel,
  formatFullDateLabel,
} from '../../../shared/utils/locale-format.utils';

/**
 * Etat « resultat » de la revue apres confirmation (KKS-386) : ce que l'import
 * a fait, puis le controle du solde contre celui de la banque.
 */
@Component({
  selector: 'app-import-result',
  standalone: true,
  imports: [NgIcon, AmountPipe, TranslocoPipe],
  providers: [
    provideIcons({
      phosphorCheckCircle,
      phosphorLinkSimple,
      phosphorReceipt,
      phosphorWarningCircle,
    }),
  ],
  templateUrl: './import-result.html',
  styleUrl: './import-result.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ImportResult {
  private readonly languageService = inject(LanguageService);

  readonly result = input.required<ImportConfirmResult>();
  readonly currency = input<string>('EUR');

  /** L'utilisatrice veut quitter la revue pour ses transactions. */
  readonly done = output<void>();

  fullDate(isoDate: string): string {
    return formatFullDateLabel(isoDate, this.languageService.displayLocale());
  }

  shortDate(isoDate: string): string {
    return formatDayMonthLabel(isoDate, this.languageService.displayLocale());
  }
}
