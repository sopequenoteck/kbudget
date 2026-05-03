# Quickstart: 053-flutter-settings-accounts

## Prérequis

- Flutter >= 3.27 (stable)
- API backend démarrée (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Un utilisateur existant avec au moins un compte

## Fichiers à créer

### Couche data (extension)
1. `flutter/lib/src/data/remote/dto/adjust_balance_request.dart` — DTO requête
2. `flutter/lib/src/data/remote/dto/adjust_balance_request.g.dart` — Généré

### Couche presentation — List
3. `flutter/lib/src/features/accounts/presentation/screens/account_list_screen.dart`
4. `flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart`
5. `flutter/lib/src/features/accounts/presentation/widgets/account_list_skeleton.dart`

### Couche presentation — Form
6. `flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart`
7. `flutter/lib/src/features/accounts/presentation/widgets/account_preview_card.dart`
8. `flutter/lib/src/features/accounts/presentation/widgets/account_type_selector.dart`
9. `flutter/lib/src/features/accounts/presentation/widgets/color_palette_picker.dart`

### Localisation
10. Ajout de clés dans `flutter/lib/src/localization/app_*.arb`

## Fichiers à modifier

### Couche data
1. `flutter/lib/src/data/remote/data_sources/account_remote_data_source.dart` — ajouter `adjustBalance()`
2. `flutter/lib/src/domain/repositories/account_repository.dart` — ajouter `adjustBalance()`
3. `flutter/lib/src/features/accounts/data/account_repository_remote.dart` — implémenter `adjustBalance()`

### Couche application
4. `flutter/lib/src/features/accounts/application/account_notifier.dart` — ajouter `adjustBalance()`

### Routing
5. `flutter/lib/src/routing/app_router.dart` — remplacer StubSettingsScreen par AccountListScreen + ajouter routes form
6. `flutter/lib/src/routing/route_names.dart` — ajouter constantes de route

## Séquence de build

```bash
# 1. Générer le DTO (après création de adjust_balance_request.dart)
cd flutter && dart run build_runner build --delete-conflicting-outputs

# 2. Vérifier que les tests existants passent
cd flutter && flutter test

# 3. Analyser le code
cd flutter && flutter analyze
```

## Commandes de test

```bash
# Tests unitaires (notifier)
cd flutter && flutter test test/src/features/accounts/

# Tests widget (écrans)
cd flutter && flutter test test/src/features/accounts/presentation/

# Tous les tests
cd flutter && flutter test
```
