# Quickstart: 054-flutter-settings-categories

**Date**: 2026-02-26

## Prérequis

- Flutter >= 3.27 installé
- Branche `054-flutter-settings-categories` checkoutée

## Démarrage rapide

```bash
cd flutter

# Vérifier que le code compile
flutter analyze

# Lancer les tests existants (catégories)
flutter test test/src/features/categories/

# Lancer sur simulateur/device
flutter run
```

## Navigation vers la feature

1. Lancer l'app → Se connecter
2. Aller dans **Paramètres** (icône engrenage)
3. Section **Gestion** → Taper **Catégories**
4. La liste des catégories s'affiche (actuellement : écran stub)

## Fichiers clés existants à consulter

| Fichier | Raison |
|---------|--------|
| `lib/src/features/accounts/presentation/screens/account_list_screen.dart` | Pattern de référence pour la liste |
| `lib/src/features/accounts/presentation/screens/account_form_screen.dart` | Pattern de référence pour le formulaire |
| `lib/src/features/categories/application/category_notifier.dart` | Notifier CRUD existant |
| `lib/src/common_widgets/emoji_input.dart` | Widget emoji à réutiliser |
| `lib/src/features/accounts/presentation/widgets/color_palette_picker.dart` | Widget couleur à déplacer |
| `lib/src/routing/app_router.dart` | Route stub à remplacer (ligne ~215) |

## Code generation

Si vous modifiez des fichiers Freezed ou Drift :

```bash
cd flutter
dart run build_runner build --delete-conflicting-outputs
```

> Note : Pour cette feature, aucune modification de modèle Freezed n'est prévue. Le build_runner ne devrait pas être nécessaire sauf si des fichiers `.g.dart` ou `.freezed.dart` sont manquants.

## Tests

```bash
cd flutter

# Tests unitaires catégories (notifier)
flutter test test/src/features/categories/

# Tests widgets (après création)
flutter test test/src/features/categories/presentation/

# Tous les tests
flutter test
```
