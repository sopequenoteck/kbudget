import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum SettingsGroup {
  general('Général'),
  management('Gestion'),
  other('Autre');

  final String label;
  const SettingsGroup(this.label);
}

class SettingsSection {
  final PhosphorIconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final SettingsGroup group;
  final bool isPlaceholder;
  final String? route;

  const SettingsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.group,
    this.isPlaceholder = false,
    this.route,
  });
}

const settingsSections = <SettingsSection>[
  // Général
  SettingsSection(
    icon: PhosphorIconsRegular.user,
    iconColor: Colors.blue,
    title: 'Profil',
    description: 'Nom, email, devise',
    group: SettingsGroup.general,
    route: '/settings/profile',
  ),
  SettingsSection(
    icon: PhosphorIconsRegular.toggleRight,
    iconColor: Colors.green,
    title: 'Fonctionnalités & Navigation',
    description: 'Modules et ordre de navigation',
    group: SettingsGroup.general,
    route: '/settings/features',
  ),
  SettingsSection(
    icon: PhosphorIconsRegular.palette,
    iconColor: Colors.purple,
    title: 'Apparence',
    description: 'Thème, taille texte',
    group: SettingsGroup.general,
    route: '/settings/appearance',
  ),
  SettingsSection(
    icon: PhosphorIconsRegular.bell,
    iconColor: Colors.amber,
    title: 'Notifications',
    description: 'Types d\'alertes et fuseau horaire',
    group: SettingsGroup.general,
    route: '/settings/notifications',
  ),
  // Gestion
  SettingsSection(
    icon: PhosphorIconsRegular.bank,
    iconColor: Colors.teal,
    title: 'Comptes',
    description: 'Gérer les comptes',
    group: SettingsGroup.management,
    route: '/settings/accounts',
  ),
  SettingsSection(
    icon: PhosphorIconsRegular.tag,
    iconColor: Colors.orange,
    title: 'Catégories',
    description: 'Gérer les catégories',
    group: SettingsGroup.management,
    route: '/settings/categories',
  ),
  SettingsSection(
    icon: PhosphorIconsRegular.currencyCircleDollar,
    iconColor: Colors.amber,
    title: 'Devises & Taux',
    description: 'Devises et taux de conversion',
    group: SettingsGroup.management,
    route: '/settings/currencies',
  ),
  SettingsSection(
    icon: PhosphorIconsRegular.database,
    iconColor: Colors.indigo,
    title: 'Données',
    description: 'Source locale / serveur',
    group: SettingsGroup.management,
    route: '/settings/data',
  ),
  // Autre
  SettingsSection(
    icon: PhosphorIconsRegular.lock,
    iconColor: Colors.red,
    title: 'Sécurité',
    description: 'Verrouillage, biométrie',
    group: SettingsGroup.other,
    isPlaceholder: true,
  ),
  SettingsSection(
    icon: PhosphorIconsRegular.info,
    iconColor: Colors.grey,
    title: 'À propos',
    description: 'Version, licences',
    group: SettingsGroup.other,
    isPlaceholder: true,
  ),
];

/// Sections groupées par SettingsGroup, dans l'ordre de l'enum.
Map<SettingsGroup, List<SettingsSection>> get groupedSettingsSections {
  final map = <SettingsGroup, List<SettingsSection>>{};
  for (final group in SettingsGroup.values) {
    map[group] =
        settingsSections.where((s) => s.group == group).toList();
  }
  return map;
}
