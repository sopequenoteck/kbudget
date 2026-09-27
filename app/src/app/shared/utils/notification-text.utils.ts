import { TranslocoService } from '@jsverse/transloco';

import { type NotificationModel, type NotificationType } from '../../core/models/notification.model';
import { categoryDisplayName } from './category-name.utils';
import { formatCurrencyAmount, formatFullDateLabel } from './locale-format.utils';

export interface NotificationDisplayText {
  title: string;
  message: string;
}

interface NotificationTextKeys {
  titleKey: string;
  messageKey: string;
  /** Parametres sans lesquels le texte ne peut pas etre reconstruit (KKS-397)
   * — `currency` en est volontairement absent pour `RECURRING_TRANSACTION_DUE`,
   * qui peut le recevoir vide. */
  requiredParams: readonly string[];
}

const NOTIFICATION_TEXT_KEYS: Readonly<Record<NotificationType, NotificationTextKeys>> = {
  SUBSCRIPTION_DUE: {
    titleKey: 'notifications.list.subscriptionDueTitle',
    messageKey: 'notifications.list.subscriptionDueMessage',
    requiredParams: ['name'],
  },
  DEBT_DUE: {
    titleKey: 'notifications.list.debtDueTitle',
    messageKey: 'notifications.list.debtDueMessage',
    requiredParams: ['person'],
  },
  DEBT_REMINDER: {
    titleKey: 'notifications.list.debtReminderTitle',
    messageKey: 'notifications.list.debtReminderMessage',
    requiredParams: ['person', 'amount', 'currency'],
  },
  BUDGET_THRESHOLD: {
    titleKey: 'notifications.list.budgetThresholdTitle',
    messageKey: 'notifications.list.budgetThresholdMessage',
    requiredParams: ['category', 'percentage'],
  },
  BUDGET_EXCEEDED: {
    titleKey: 'notifications.list.budgetExceededTitle',
    messageKey: 'notifications.list.budgetExceededMessage',
    requiredParams: ['category', 'percentage'],
  },
  RECURRING_TRANSACTION_DUE: {
    titleKey: 'notifications.list.recurringTransactionDueTitle',
    messageKey: 'notifications.list.recurringTransactionDueMessage',
    requiredParams: ['label', 'amount', 'dueDate'],
  },
};

function isMissing(value: string | undefined): boolean {
  return !value;
}

/** Montant formate avec sa devise (KKS-397) ; sans devise — cas documente de
 * `RECURRING_TRANSACTION_DUE` — retombe sur la valeur brute plutot que sur
 * le repli complet du texte. */
function formatAmountParam(amount: string, currency: string | undefined, locale: string): string {
  if (!currency) {
    return amount;
  }
  const numericAmount = Number(amount);
  return Number.isNaN(numericAmount) ? amount : formatCurrencyAmount(numericAmount, currency, locale);
}

function buildIcuParams(
  type: NotificationType,
  params: Record<string, string>,
  transloco: TranslocoService,
  lang: string,
  locale: string,
): Record<string, string> {
  switch (type) {
    case 'SUBSCRIPTION_DUE':
      return { name: params['name'] };
    case 'DEBT_DUE':
      return { person: params['person'] };
    case 'DEBT_REMINDER':
      return {
        person: params['person'],
        amount: formatAmountParam(params['amount'], params['currency'], locale),
      };
    case 'BUDGET_THRESHOLD':
    case 'BUDGET_EXCEEDED':
      return {
        category: categoryDisplayName(params['category'], params['categorySystemKey'], transloco, lang),
        percentage: params['percentage'],
      };
    case 'RECURRING_TRANSACTION_DUE':
      return {
        label: params['label'],
        amount: formatAmountParam(params['amount'], params['currency'], locale),
        dueDate: formatFullDateLabel(params['dueDate'], locale),
      };
  }
}

/**
 * Reconstruit `title`/`message` d'une notification a partir de `type` et
 * `params` (KKS-397), dans la langue appliquee. Repli sur les `title`/
 * `message` bruts de la notification quand `params` est absent, quand le
 * type est inconnu de ce client, ou quand un parametre requis manque —
 * couvre aussi bien une notification anterieure a ce ticket qu'un serveur
 * plus recent envoyant un type que ce client ne sait pas encore afficher.
 *
 * Partagee par le pipe `notificationText` (templates) pour n'ecrire cette
 * regle qu'une fois (meme principe que `categoryDisplayName`, KKS-395).
 */
export function buildNotificationText(
  notification: NotificationModel,
  transloco: TranslocoService,
  lang: string,
  locale: string,
): NotificationDisplayText {
  const fallback: NotificationDisplayText = { title: notification.title, message: notification.message };
  const params = notification.params;
  if (!params) {
    return fallback;
  }

  const keys = NOTIFICATION_TEXT_KEYS[notification.type];
  if (!keys) {
    return fallback;
  }

  if (keys.requiredParams.some((param) => isMissing(params[param]))) {
    return fallback;
  }

  const icuParams = buildIcuParams(notification.type, params, transloco, lang, locale);

  return {
    title: transloco.translate(keys.titleKey, icuParams, lang),
    message: transloco.translate(keys.messageKey, icuParams, lang),
  };
}
