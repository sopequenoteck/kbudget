import 'package:json_annotation/json_annotation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum Feature {
  @JsonValue('SUBSCRIPTIONS')
  subscriptions,
  @JsonValue('DEBTS')
  debts,
  @JsonValue('SHOP')
  shop;

  String get label => switch (this) {
    Feature.subscriptions => 'Abonnements',
    Feature.debts => 'Dettes',
    Feature.shop => 'Boutique',
  };

  PhosphorIconData get icon => switch (this) {
    Feature.subscriptions => PhosphorIconsFill.arrowsClockwise,
    Feature.debts => PhosphorIconsFill.handshake,
    Feature.shop => PhosphorIconsFill.storefront,
  };

  PhosphorIconData get outlinedIcon => switch (this) {
    Feature.subscriptions => PhosphorIconsRegular.arrowsClockwise,
    Feature.debts => PhosphorIconsRegular.handshake,
    Feature.shop => PhosphorIconsRegular.storefront,
  };

  String get description => switch (this) {
    Feature.subscriptions => 'Gérer vos abonnements récurrents',
    Feature.debts => 'Suivre vos prêts et emprunts',
    Feature.shop => 'Gérer vos ventes de produits',
  };

  bool get defaultEnabled => switch (this) {
    Feature.subscriptions => true,
    Feature.debts => true,
    Feature.shop => false,
  };
}
