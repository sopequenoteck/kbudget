# Quickstart: Formulaire Dette Flutter

**Feature**: `047-flutter-debt-form` | **Date**: 2026-02-23

## Prérequis

- Flutter >= 3.27 installé
- Branche `047-flutter-debt-form` checked out

## Démarrage rapide

```bash
cd flutter
flutter pub get
flutter run
```

## Vérification

1. Lancer l'app sur un simulateur/device
2. Appuyer sur le FAB (+) → sélectionner "Nouvelle dette"
3. Vérifier que la modale s'ouvre avec le toggle Emprunt/Prêt
4. Remplir personne, montant, date
5. Appuyer sur "Enregistrer" → la dette apparaît dans la liste
6. Taper sur la dette → vérifier le mode édition (champs pré-remplis, switch remboursé, bouton supprimer)

## Tests

```bash
cd flutter
flutter test test/src/features/debts/
```

## Fichiers clés

| Fichier | Rôle |
| ------- | ---- |
| `lib/src/features/debts/presentation/widgets/debt_form.dart` | Widget formulaire (nouveau) |
| `lib/src/routing/app_router.dart` | Intégration modale (modifié) |
| `lib/src/localization/app_fr.arb` | Clés i18n (modifié) |
| `lib/src/features/debts/application/debt_notifier.dart` | Notifier CRUD (existant) |
| `lib/src/domain/models/debt.dart` | Modèle Freezed (existant) |
