// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:intl/intl.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/enums/notification_type.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/category_name.dart';

/// Titre et message affiches d'une [NotificationModel], construits depuis
/// `type` et `params` dans la langue de [l10n] (KKS-425, pendant Flutter de
/// KKS-397). Montants et dates sont formates pour [intlLocale].
///
/// Repli sur `title` / `message` tels que stockes quand `params` est absent
/// (notification anterieure a V40), quand `type` est inconnu de ce client,
/// ou quand un parametre requis manque ou est vide.
({String title, String message}) buildNotificationText(
  NotificationModel notification,
  AppLocalizations l10n,
  String intlLocale,
) {
  final params = notification.params;
  final type = notification.type;
  if (params == null ||
      type == null ||
      _requiredParams(type).any((key) => params[key]?.isEmpty ?? true)) {
    return (title: notification.title, message: notification.message);
  }
  String param(String key) => params[key] ?? '';
  String amount() =>
      _formatAmount(param('amount'), params['currency'], intlLocale);
  String category() =>
      categoryDisplayName(param('category'), params['categorySystemKey'], l10n);

  return switch (type) {
    NotificationType.subscriptionDue => (
        title: l10n.notificationsListSubscriptionDueTitle(param('name')),
        message: l10n.notificationsListSubscriptionDueMessage(param('name')),
      ),
    NotificationType.debtDue => (
        title: l10n.notificationsListDebtDueTitle(param('person')),
        message: l10n.notificationsListDebtDueMessage(param('person')),
      ),
    NotificationType.debtReminder => (
        title: l10n.notificationsListDebtReminderTitle(param('person')),
        message: l10n.notificationsListDebtReminderMessage(
          amount(),
          param('person'),
        ),
      ),
    NotificationType.budgetThreshold => (
        title: l10n.notificationsListBudgetThresholdTitle(
          category(),
          param('percentage'),
        ),
        message: l10n.notificationsListBudgetThresholdMessage(
          param('percentage'),
          category(),
        ),
      ),
    NotificationType.budgetExceeded => (
        title: l10n.notificationsListBudgetExceededTitle(category()),
        message: l10n.notificationsListBudgetExceededMessage(
          category(),
          param('percentage'),
        ),
      ),
    NotificationType.recurringTransactionDue => (
        title: l10n.notificationsListRecurringTransactionDueTitle(
          param('label'),
        ),
        message: l10n.notificationsListRecurringTransactionDueMessage(
          param('label'),
          amount(),
          _formatDueDate(param('dueDate'), intlLocale),
        ),
      ),
  };
}

/// Parametres sans lesquels le texte ne peut pas etre reconstruit, comme
/// Angular : `currency` est absent pour une transaction recurrente, qui peut
/// ne pas en recevoir (aucun compte lie).
List<String> _requiredParams(NotificationType type) => switch (type) {
      NotificationType.subscriptionDue => const ['name'],
      NotificationType.debtDue => const ['person'],
      NotificationType.debtReminder => const ['person', 'amount', 'currency'],
      NotificationType.budgetThreshold ||
      NotificationType.budgetExceeded =>
        const ['category', 'percentage'],
      NotificationType.recurringTransactionDue =>
        const ['label', 'amount', 'dueDate'],
    };

/// Montant formate avec sa devise ; sans devise ou illisible, [amount] brut ;
/// devise inconnue de [Currency], montant et code bruts.
String _formatAmount(String amount, String? code, String intlLocale) {
  final value = double.tryParse(amount);
  if (code == null || code.isEmpty || value == null) {
    return amount;
  }
  final currency = Currency.values.asNameMap()[code.toLowerCase()];
  if (currency == null) {
    return '$amount $code';
  }
  return AmountFormatter.format(value, locale: intlLocale, currency: currency);
}

/// Date d'echeance `AAAA-MM-JJ` en toutes lettres ; illisible, brute.
String _formatDueDate(String dueDate, String intlLocale) {
  final date = DateTime.tryParse(dueDate);
  if (date == null) {
    return dueDate;
  }
  return DateFormat.yMMMMd(intlLocale).format(date);
}
