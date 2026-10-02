import { Pipe, PipeTransform, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';

import { LanguageService } from '../../core/services/language';
import { type NotificationModel } from '../../core/models/notification.model';
import { buildNotificationText, type NotificationDisplayText } from '../utils/notification-text.utils';

// Impure (KKS-397, meme precedent que `categoryName`/`amount`/`shortDate`) :
// un pipe pur memorise sur l'identite de `notification` et ne rappellerait
// jamais `transform` au seul changement de langue — `activeLanguage()` et
// `displayLocale()` n'en font pas partie.
@Pipe({ name: 'notificationText', standalone: true, pure: false })
export class NotificationTextPipe implements PipeTransform {
  private readonly languageService = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);

  transform(notification: NotificationModel): NotificationDisplayText {
    return buildNotificationText(
      notification,
      this.transloco,
      this.languageService.activeLanguage(),
      this.languageService.displayLocale(),
    );
  }
}
