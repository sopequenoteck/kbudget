# Quickstart: Configuration de la navigation — Flutter

**Branch**: `059-flutter-settings-bottom-nav` | **Date**: 2026-02-28

## Prérequis

- Flutter >= 3.27 (stable)
- Dart >= 3.6
- Dépendance KKS-120 implémentée (feature toggles, `featureConfigProvider`)

## Fichiers à modifier

### Domain layer
1. `flutter/lib/src/domain/enums/feature.dart` — Ajouter `outlinedIcon` getter
2. `flutter/lib/src/domain/models/app_config.dart` — Ajouter champ `navOrder`
3. `flutter/lib/src/domain/repositories/app_config_repository.dart` — Ajouter `getNavOrder()` / `setNavOrder()`

### Data layer
4. `flutter/lib/src/features/onboarding/data/app_config_repository_impl.dart` — Implémenter les nouvelles méthodes

### Application layer
5. `flutter/lib/src/features/settings/application/feature_config_notifier.dart` — Ajouter `navOrder` au state + méthode `reorderNavigation()`

### Presentation layer
6. `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart` — Ajouter section Navigation + preview
7. `flutter/lib/src/features/settings/domain/settings_section.dart` — Mettre à jour titre/description

### Navigation
8. `flutter/lib/src/routing/app_router.dart` — `_ShellScaffold` utilise `navOrder` pour l'ordre des onglets

## Commandes

```bash
# Code generation après modification Freezed (AppConfig, FeatureConfigState)
cd flutter && dart run build_runner build --delete-conflicting-outputs

# Vérification
cd flutter && flutter analyze
cd flutter && flutter test
```

## Séquence de build recommandée

1. Domain : enum + model + repository interface
2. `build_runner` (génère .freezed.dart et .g.dart)
3. Data : repository impl
4. Application : notifier
5. `build_runner` (génère .freezed.dart pour le state)
6. Presentation : UI (screen + preview)
7. Navigation : _ShellScaffold
8. Settings hub : mise à jour libellé
9. Tests
