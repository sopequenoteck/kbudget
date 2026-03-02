import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

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

  IconData get icon => switch (this) {
    Feature.subscriptions => Icons.autorenew,
    Feature.debts => Icons.handshake,
    Feature.shop => Icons.storefront,
  };

  IconData get outlinedIcon => switch (this) {
    Feature.subscriptions => Icons.autorenew_outlined,
    Feature.debts => Icons.handshake_outlined,
    Feature.shop => Icons.storefront_outlined,
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
