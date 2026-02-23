# Quickstart: Flutter — Écran Dettes Liste

**Feature**: 048-flutter-debts-list | **Date**: 2026-02-23

## Prérequis

- Flutter >= 3.27 (stable)
- Dart >= 3.6
- Le projet Flutter compile sans erreur sur la branche `048-flutter-debts-list`
- Les branches 047 (DebtForm), 041 (Notifiers CRUD), 038 (SegmentedFilter), 033 (ListItem) sont mergées

## Setup

```bash
cd flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Le `build_runner` est nécessaire après création du nouveau fichier `debt_list_state.dart` (Freezed).

## Lancer l'app

```bash
cd flutter
flutter run
```

Naviguer vers l'onglet "Dettes" dans la barre de navigation.

## Tests

```bash
# Tous les tests
cd flutter && flutter test

# Tests spécifiques à cette feature
cd flutter && flutter test test/src/features/debts/

# Test du notifier uniquement
cd flutter && flutter test test/src/features/debts/application/debt_notifier_test.dart

# Test du widget uniquement
cd flutter && flutter test test/src/features/debts/presentation/debt_list_screen_test.dart
```

## Vérification rapide

1. **Liste avec sections** : Créer au moins 1 prêt et 1 emprunt → vérifier les 2 sections avec sous-totaux
2. **Résumé** : Vérifier la carte récapitulative (emprunts, prêts, solde net) avec couleurs
3. **Filtre** : Tester les 3 filtres (Tous / En cours / Remboursé)
4. **Badge** : Marquer une dette comme remboursée → vérifier le badge "Remboursé"
5. **Édition** : Tap sur un item → vérifier que la modal s'ouvre avec les données pré-remplies
6. **État vide** : Supprimer toutes les dettes → vérifier le message "Aucune dette"
7. **Pull-to-refresh** : Tirer vers le bas → vérifier le rechargement

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `flutter/lib/src/domain/enums/debt_status_filter.dart` | Enum filtre (all/enCours/rembourse) |
| `flutter/lib/src/features/debts/application/debt_list_state.dart` | State Freezed custom |
| `flutter/lib/src/features/debts/application/debt_notifier.dart` | Notifier (modifié: filtre + résumé) |
| `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` | Screen complet (remplace stub) |
| `flutter/lib/src/localization/app_fr.arb` | Clés i18n françaises |
| `flutter/lib/src/localization/app_en.arb` | Clés i18n anglaises |
