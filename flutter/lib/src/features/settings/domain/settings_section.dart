import 'package:flutter/material.dart';

enum SettingsGroup {
  general('Général'),
  management('Gestion'),
  other('Autre');

  final String label;
  const SettingsGroup(this.label);
}

class SettingsSection {
  final IconData icon;
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
    icon: Icons.person,
    iconColor: Colors.blue,
    title: 'Profil',
    description: 'Nom, email, devise',
    group: SettingsGroup.general,
    route: '/settings/profile',
  ),
  SettingsSection(
    icon: Icons.toggle_on,
    iconColor: Colors.green,
    title: 'Fonctionnalités & Navigation',
    description: 'Modules et ordre de navigation',
    group: SettingsGroup.general,
    route: '/settings/features',
  ),
  SettingsSection(
    icon: Icons.palette,
    iconColor: Colors.purple,
    title: 'Apparence',
    description: 'Thème, taille texte',
    group: SettingsGroup.general,
    route: '/settings/appearance',
  ),
  // Gestion
  SettingsSection(
    icon: Icons.account_balance,
    iconColor: Colors.teal,
    title: 'Comptes',
    description: 'Gérer les comptes',
    group: SettingsGroup.management,
    route: '/settings/accounts',
  ),
  SettingsSection(
    icon: Icons.label,
    iconColor: Colors.orange,
    title: 'Catégories',
    description: 'Gérer les catégories',
    group: SettingsGroup.management,
    route: '/settings/categories',
  ),
  SettingsSection(
    icon: Icons.storage,
    iconColor: Colors.indigo,
    title: 'Données',
    description: 'Source locale / serveur',
    group: SettingsGroup.management,
    route: '/settings/data',
  ),
  // Autre
  SettingsSection(
    icon: Icons.lock,
    iconColor: Colors.red,
    title: 'Sécurité',
    description: 'Verrouillage, biométrie',
    group: SettingsGroup.other,
    isPlaceholder: true,
  ),
  SettingsSection(
    icon: Icons.info,
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
