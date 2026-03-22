# Quickstart: Page Fonctionnalités (Feature Toggles) — Flutter

**Branch**: `058-flutter-settings-features`

## Prérequis

- Flutter >= 3.27 (stable)
- Dart >= 3.6
- Backend k-budget en cours d'exécution (profil dev) pour le mode serveur

## Setup dev

```bash
# Cloner et checkout la branche
git checkout 058-flutter-settings-features

# Backend (pour mode serveur)
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev

# Flutter
cd flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Fichiers impactés (existants)

| Fichier | Modification |
|---------|-------------|
| `flutter/lib/src/domain/models/app_config.dart` | Ajout champ `enabledFeatures` |
| `flutter/lib/src/domain/repositories/app_config_repository.dart` | Ajout getter/setter `enabledFeatures` |
| `flutter/lib/src/features/onboarding/data/app_config_repository_impl.dart` | Implémentation getter/setter |
| `flutter/lib/src/domain/enums/enums.dart` | Export du nouvel enum `Feature` |
| `flutter/lib/src/features/settings/domain/settings_section.dart` | Ajout section "Fonctionnalités" |
| `flutter/lib/src/routing/app_router.dart` | Navigation dynamique + route features + route shop |
| `flutter/lib/src/routing/route_names.dart` | Ajout constantes routes |
| `flutter/lib/src/common_widgets/adaptive_scaffold.dart` | Destinations dynamiques |
| `flutter/lib/src/common_widgets/fab_menu.dart` | Filtrage items par features |

## Fichiers à créer

| Fichier | Rôle |
|---------|------|
| `flutter/lib/src/domain/enums/feature.dart` | Enum Feature (SUBSCRIPTIONS, DEBTS, SHOP) |
| `flutter/lib/src/data/remote/dtos/user_preference_response.dart` | DTO réponse |
| `flutter/lib/src/data/remote/dtos/user_preference_request.dart` | DTO requête |
| `flutter/lib/src/data/remote/data_sources/preference_remote_data_source.dart` | Datasource Dio |
| `flutter/lib/src/features/settings/application/feature_config_notifier.dart` | Notifier + state |
| `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart` | Écran toggles |

## Vérification rapide

1. Lancer l'app Flutter
2. Aller dans Settings > Fonctionnalités
3. Désactiver "Dettes" → l'onglet Dettes disparaît de la bottom nav
4. Réactiver "Dettes" → l'onglet réapparaît
5. Fermer et rouvrir l'app → état restauré

## Tests

```bash
cd flutter && flutter test test/src/features/settings/
```
