import 'package:json_annotation/json_annotation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum NotificationType {
  @JsonValue('SUBSCRIPTION_DUE')
  subscriptionDue,
  @JsonValue('DEBT_DUE')
  debtDue;

  String get label => switch (this) {
        NotificationType.subscriptionDue => 'Échéance abonnement',
        NotificationType.debtDue => 'Échéance dette',
      };

  PhosphorIconData get icon => switch (this) {
        NotificationType.subscriptionDue => PhosphorIconsRegular.calendarCheck,
        NotificationType.debtDue => PhosphorIconsRegular.handCoins,
      };
}
