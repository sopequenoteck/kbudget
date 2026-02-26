# Quickstart: Flutter — Formulaire Transaction

**Feature**: `044-flutter-transaction-form` | **Date**: 2026-02-23

## Prérequis

- Flutter >= 3.27, Dart >= 3.6
- Dépendances KKS résolues : Modal (KKS-94), FormField (KKS-95), SelectPicker (KKS-96), CategoryPicker (KKS-97), Notifiers CRUD (KKS-115)

## Lancer l'app

```bash
cd flutter && flutter run
```

## Tester le formulaire

### Création
1. Naviguer vers l'écran Transactions
2. Appuyer sur le FAB (+)
3. Le modal s'ouvre avec toggle Dépense/Recette
4. Remplir les champs et valider

### Édition
1. Appuyer sur une transaction existante dans la liste
2. Le modal s'ouvre pré-rempli
3. Modifier un champ et valider

### Suppression
1. Ouvrir une transaction en édition
2. Appuyer sur "Supprimer"
3. Confirmer dans le dialog

## Tests

```bash
cd flutter && flutter test test/src/features/transactions/presentation/widgets/transaction_form_test.dart
```

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` | Widget du formulaire (NOUVEAU) |
| `flutter/lib/src/features/transactions/presentation/transactions_screen.dart` | Écran liste — ouverture du modal (MODIFIÉ) |
| `flutter/lib/src/localization/app_fr.arb` | Labels i18n (MODIFIÉ) |
| `flutter/test/src/features/transactions/presentation/widgets/transaction_form_test.dart` | Tests widget (NOUVEAU) |

## Widgets communs utilisés

| Widget | Import | Usage |
|--------|--------|-------|
| `AppModal` | `common_widgets/app_modal.dart` | Conteneur modal |
| `AppToggle` | `common_widgets/app_toggle.dart` | Toggle Dépense/Recette |
| `AppFormField` | `common_widgets/app_form_field.dart` | Wrapper champs avec label + erreur |
| `SelectPicker` | `common_widgets/select_picker.dart` | Sélection du compte |
| `CategoryPicker` | `common_widgets/category_picker.dart` | Sélection de la catégorie |

## Providers Riverpod utilisés

| Provider | Usage |
|----------|-------|
| `transactionNotifierProvider` | CRUD transactions (create, update, delete) |
| `accountNotifierProvider` | Liste des comptes (pour SelectPicker) |
| `categoryNotifierProvider` | Liste des catégories (pour CategoryPicker) |
