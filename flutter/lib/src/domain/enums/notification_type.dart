// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:json_annotation/json_annotation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum NotificationType {
  @JsonValue('SUBSCRIPTION_DUE')
  subscriptionDue,
  @JsonValue('DEBT_DUE')
  debtDue,
  @JsonValue('DEBT_REMINDER')
  debtReminder,
  @JsonValue('RECURRING_TRANSACTION_DUE')
  recurringTransactionDue,
  @JsonValue('BUDGET_THRESHOLD')
  budgetThreshold,
  @JsonValue('BUDGET_EXCEEDED')
  budgetExceeded;

  String get label => switch (this) {
        NotificationType.subscriptionDue => 'Échéance abonnement',
        NotificationType.debtDue => 'Échéance dette',
        NotificationType.debtReminder => 'Rappel dette',
        NotificationType.recurringTransactionDue => 'Récurrence due',
        NotificationType.budgetThreshold => 'Seuil budget atteint',
        NotificationType.budgetExceeded => 'Budget dépassé',
      };

  PhosphorIconData get icon => switch (this) {
        NotificationType.subscriptionDue => PhosphorIconsRegular.calendarCheck,
        NotificationType.debtDue => PhosphorIconsRegular.handCoins,
        NotificationType.debtReminder => PhosphorIconsRegular.bellRinging,
        NotificationType.recurringTransactionDue => PhosphorIconsRegular.repeat,
        NotificationType.budgetThreshold => PhosphorIconsRegular.chartPieSlice,
        NotificationType.budgetExceeded => PhosphorIconsRegular.warning,
      };
}
