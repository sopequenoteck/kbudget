# Data Model — 034-flutter-settings-hub

**Date**: 2026-02-21

## Entités

### SettingsSection (statique, non persistée)

Représente un item dans le hub de réglages. Défini comme liste statique dans le code.

| Champ | Type | Description |
|-------|------|-------------|
| `icon` | `IconData` | Icône Material |
| `iconColor` | `Color` | Couleur du cercle de fond |
| `title` | `String` | Titre affiché |
| `description` | `String` | Description courte |
| `group` | `SettingsGroup` | Groupe parent |
| `isPlaceholder` | `bool` | `true` = badge "À venir" + opacité réduite + non interactif |
| `route` | `String?` | Route GoRouter (null si placeholder) |

### SettingsGroup (enum)

| Valeur | Label affiché |
|--------|---------------|
| `general` | "Général" |
| `management` | "Gestion" |
| `other` | "Autre" |

### AppConfig (existant — pas de modification)

Déjà défini dans `lib/src/domain/models/app_config.dart` avec Freezed. Champs utilisés par cette feature :

| Champ | Type | Usage |
|-------|------|-------|
| `dataMode` | `DataMode` | Source active (local/server) |
| `serverUrl` | `String?` | URL du serveur API |

Persistence : `FlutterSecureStorage` via `AppConfigRepository`.

### DataMode (enum existant — pas de modification)

| Valeur | Description |
|--------|-------------|
| `local` | SQLite via Drift |
| `server` | API REST via Dio |

## Relations

```
SettingsGroup (enum)
  └── contient 1..n SettingsSection (statique)

AppConfig (persisté)
  ├── dataMode: DataMode
  └── serverUrl: String?
```

## Données statiques du hub

```dart
final settingsSections = [
  // Général
  SettingsSection(icon: Icons.person, iconColor: Colors.blue, title: 'Profil', description: 'Nom, email, devise', group: SettingsGroup.general, route: '/settings/profile'),
  SettingsSection(icon: Icons.palette, iconColor: Colors.purple, title: 'Apparence', description: 'Thème, taille texte', group: SettingsGroup.general, route: '/settings/appearance'),
  // Gestion
  SettingsSection(icon: Icons.account_balance, iconColor: Colors.teal, title: 'Comptes', description: 'Gérer les comptes', group: SettingsGroup.management, route: '/settings/accounts'),
  SettingsSection(icon: Icons.label, iconColor: Colors.orange, title: 'Catégories', description: 'Gérer les catégories', group: SettingsGroup.management, route: '/settings/categories'),
  SettingsSection(icon: Icons.storage, iconColor: Colors.indigo, title: 'Données', description: 'Source locale / serveur', group: SettingsGroup.management, route: '/settings/data'),
  // Autre
  SettingsSection(icon: Icons.lock, iconColor: Colors.red, title: 'Sécurité', description: 'Verrouillage, biométrie', group: SettingsGroup.other, isPlaceholder: true),
  SettingsSection(icon: Icons.info, iconColor: Colors.grey, title: 'À propos', description: 'Version, licences', group: SettingsGroup.other, isPlaceholder: true),
];
```

## Validation

### Sous-page Données — champ URL serveur

| Règle | Condition | Message d'erreur |
|-------|-----------|------------------|
| Non vide | `url.trim().isEmpty` | "L'URL du serveur est requise" |
| Format URL | Ne commence pas par `https://` (ou `http://` en dev) | "L'URL doit commencer par https://" |
| Connectivité | HEAD request échoue (timeout 10s) | "Serveur injoignable" |

## State transitions — Data source switch

```
[Idle] → utilisateur change le sélecteur → [Confirmation dialog]
  ├── Annule → [Idle] (pas de changement)
  └── Confirme → [Checking connectivity] (si switch vers server)
       ├── Échec → [Error] → [Idle]
       └── Succès → [Saving] → [Restart app]

[Idle] → utilisateur change le sélecteur (local → local ou server → server) → [Idle] (pas de dialog)
```
