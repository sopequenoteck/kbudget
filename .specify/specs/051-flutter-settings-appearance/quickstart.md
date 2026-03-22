# Quickstart: Settings — Apparence

**Feature Branch**: `051-flutter-settings-appearance`

## Prérequis

- Flutter >= 3.27 (stable)
- Dart >= 3.6
- build_runner installé (`dart pub get`)

## Séquence de build

```bash
# 1. Checkout de la branche
git checkout 051-flutter-settings-appearance

# 2. Installer les dépendances
cd flutter && flutter pub get

# 3. Régénérer le code (Freezed, json_serializable) — OBLIGATOIRE après modification AppConfig
cd flutter && dart run build_runner build --delete-conflicting-outputs

# 4. Vérifier l'analyse statique
cd flutter && flutter analyze

# 5. Lancer les tests
cd flutter && flutter test

# 6. Lancer sur simulateur
cd flutter && flutter run
```

## Ordre d'implémentation recommandé

1. Enum `TextScale` (aucune dépendance)
2. Modifier `AppConfig` + `AppConfigRepository` + impl (puis build_runner)
3. Créer `TextScaleNotifier` (dépend de 2)
4. Modifier `app.dart` pour le `MediaQuery` wrapper (dépend de 3)
5. Créer l'écran `AppearanceSettingsScreen` (dépend de 3 et 4)
6. Mettre à jour le routeur (dépend de 5)
7. Tests

## Vérification rapide

Après implémentation, vérifier :
- [ ] Thème clair/sombre bascule immédiatement via tiles
- [ ] Taille texte change immédiatement (preview + app entière)
- [ ] Préférences persistent après kill + relaunch
- [ ] Config existante (sans `textScale`) ne crashe pas (défaut `medium`)
