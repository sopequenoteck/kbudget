import 'package:json_annotation/json_annotation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum NotificationType {
  @JsonValue('SUBSCRIPTION_DUE')
  subscriptionDue,
  @JsonValue('DEBT_DUE')
  debtDue,
  @JsonValue('DEBT_REMINDER')
  debtReminder;

  String get label => switch (this) {
        NotificationType.subscriptionDue => 'Échéance abonnement',
        NotificationType.debtDue => 'Échéance dette',
        NotificationType.debtReminder => 'Rappel dette',
      };

  PhosphorIconData get icon => switch (this) {
        NotificationType.subscriptionDue => PhosphorIconsRegular.calendarCheck,
        NotificationType.debtDue => PhosphorIconsRegular.handCoins,
        NotificationType.debtReminder => PhosphorIconsRegular.bellRinging,
      };
}
