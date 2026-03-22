# Quickstart: Formulaire Abonnement (Flutter)

**Date**: 2026-02-23
**Feature**: 045-flutter-subscription-form

## Prérequis

- Flutter >= 3.27 installé
- Dépendances existantes suffisantes (pas de nouveau package)
- Dépendances features : KKS-94 (AppModal), KKS-95 (AppFormField), KKS-96 (SelectPicker), KKS-97 (CategoryPicker), KKS-115 (Notifiers CRUD)

## Fichiers à créer

| Fichier | Type | Description |
|---------|------|-------------|
| `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` | Widget | Formulaire principal (ConsumerStatefulWidget) |
| `flutter/test/src/features/subscriptions/presentation/widgets/subscription_form_test.dart` | Test | Widget tests du formulaire |

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `flutter/lib/src/localization/app_fr.arb` | Ajouter clés i18n `subscriptionForm*` |
| `flutter/lib/src/localization/app_en.arb` | Ajouter clés i18n `subscriptionForm*` |
| `flutter/lib/src/routing/app_router.dart` | Ajouter `case ModalType.subscription:` dans le switch modal |
| `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` | Intégrer le bouton FAB d'ouverture du modal |

## Pattern de référence

Le fichier `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` est le modèle exact à suivre :

1. `ConsumerStatefulWidget` avec callbacks `onSaved`, `onDeleted?`, `onCancelled`
2. `TextEditingController` initialisés dans `initState()`, disposés dans `dispose()`
3. Pré-remplissage dans `build()` avec guard `_initialized`
4. Validation via méthodes `_validateNom()`, `_validateMontant()` retournant `String?`
5. Flag `_showErrors` activé au premier submit
6. Soumission : build domain object → callback → close modal / catch error
7. Layout : `Column` > `Row`(nom+montant) > date > compte > catégorie > actif > boutons

## Commandes utiles

```bash
# Lancer les tests
cd flutter && flutter test test/src/features/subscriptions/

# Régénérer le code (si modifications Freezed/Drift)
cd flutter && dart run build_runner build --delete-conflicting-outputs

# Lancer sur simulateur
cd flutter && flutter run

# Analyse statique
cd flutter && flutter analyze
```

## Clés i18n à ajouter

```
subscriptionFormNameField → "Nom"
subscriptionFormAmountField → "Montant"
subscriptionFormDateField → "Date de début"
subscriptionFormAccountPicker → "Compte"
subscriptionFormCategoryPicker → "Catégorie"
subscriptionFormActiveSwitch → "Actif"
subscriptionFormSaveButton → "Enregistrer"
subscriptionFormUpdateButton → "Modifier"
subscriptionFormDeleteButton → "Supprimer"
subscriptionFormDeleteConfirmTitle → "Supprimer l'abonnement"
subscriptionFormDeleteConfirmMessage → "Êtes-vous sûr de vouloir supprimer cet abonnement ? Cette action est irréversible."
subscriptionFormNoAccounts → "Créez un compte dans les paramètres"
subscriptionFormNoCategories → "Créez une catégorie d'abord"
```
