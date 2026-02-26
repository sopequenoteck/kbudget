# Quickstart — 034-flutter-settings-hub

## Prérequis

- Flutter >= 3.27 (stable)
- Dart >= 3.6

## Lancer le projet

```bash
cd flutter && flutter run
```

## Fichiers à créer

| Fichier | Description |
|---------|-------------|
| `lib/src/features/settings/domain/settings_section.dart` | Modèle SettingsSection + enum SettingsGroup + liste statique |
| `lib/src/features/settings/presentation/settings_hub_screen.dart` | Écran hub (remplace settings_screen.dart) |
| `lib/src/features/settings/presentation/widgets/settings_item.dart` | Widget d'item de section |
| `lib/src/features/settings/presentation/data_settings_screen.dart` | Sous-page Données (switch source + URL) |
| `lib/src/features/settings/application/data_settings_notifier.dart` | Notifier pour la logique du switch source |
| `lib/src/features/settings/presentation/stub_settings_screen.dart` | Écran stub générique pour sous-pages non implémentées |
| `lib/src/common_widgets/restart_widget.dart` | Widget wrapper pour redémarrage de l'app |
| `test/src/features/settings/presentation/settings_hub_screen_test.dart` | Tests widget du hub |
| `test/src/features/settings/presentation/data_settings_screen_test.dart` | Tests widget de la sous-page Données |
| `test/src/features/settings/presentation/widgets/settings_item_test.dart` | Tests widget de l'item |

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `lib/src/routing/app_router.dart` | Remplacer route `/settings` + ajouter sous-routes |
| `lib/src/routing/route_names.dart` | Ajouter constantes pour sous-routes settings |
| `lib/src/data/remote/api_client.dart` | Lire `serverUrl` depuis `AppConfig` au lieu de `EnvConfig` |
| `lib/main.dart` | Wrapper `RestartWidget` autour de `ProviderScope` |

## Ordre d'implémentation

1. `RestartWidget` (dépendance pour le redémarrage)
2. `SettingsSection` modèle + `SettingsGroup` enum
3. `SettingsItem` widget
4. `SettingsHubScreen` (remplace `SettingsScreen`)
5. `RouteNames` + `AppRouter` (sous-routes)
6. `StubSettingsScreen` (placeholder pour sous-pages)
7. `DataSettingsNotifier` (logique switch source)
8. `DataSettingsScreen` (UI switch source + URL)
9. `apiClientProvider` (URL dynamique)
10. Tests widget

## Vérifications

```bash
cd flutter && flutter test
cd flutter && flutter analyze
```
