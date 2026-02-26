# Quickstart: Flutter — Écran Abonnements Liste

**Date**: 2026-02-23 | **Branch**: `046-flutter-subscriptions-list`

## Prérequis

- Flutter >= 3.27 installé
- Branche `046-flutter-subscriptions-list` checkoutée
- Dépendances installées : `cd flutter && flutter pub get`

## Lancer l'app

```bash
cd flutter && flutter run
```

## Régénérer le code (après modification des modèles Freezed)

```bash
cd flutter && dart run build_runner build --delete-conflicting-outputs
```

## Lancer les tests

```bash
# Tous les tests
cd flutter && flutter test

# Tests de la feature uniquement
cd flutter && flutter test test/src/features/subscriptions/

# Tests de l'utilitaire date
cd flutter && flutter test test/src/utils/next_renewal_date_test.dart
```

## Vérification rapide

1. Ouvrir l'app → naviguer vers l'onglet Abonnements
2. Vérifier : carte total mensuel visible (si abonnements actifs existent)
3. Vérifier : filtre Tous/Actifs/Inactifs fonctionnel
4. Vérifier : badge "Inactif" visible sur les abonnements désactivés
5. Vérifier : sous-titre affiche la prochaine date de renouvellement
6. Vérifier : tap sur un item ouvre le formulaire d'édition en modal

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `lib/src/features/subscriptions/application/subscription_list_state.dart` | State Freezed (filtre, totaux) |
| `lib/src/features/subscriptions/application/subscription_notifier.dart` | Notifier avec filtre + summary |
| `lib/src/features/subscriptions/presentation/subscription_list_screen.dart` | Écran principal |
| `lib/src/domain/enums/subscription_status_filter.dart` | Enum filtre statut |
| `lib/src/utils/next_renewal_date.dart` | Calcul prochaine date |
