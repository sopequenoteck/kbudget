# Quickstart: Flutter Recurring Transactions & Subscription Payments

**Feature**: 088-flutter-recurring-transactions
**Date**: 2026-03-15

## Prérequis

- Flutter >= 3.27 installé
- Backend API lancé (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Base de données avec des transactions récurrentes et abonnements existants

## Lancer le projet

```bash
cd flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # Générer Freezed/json_serializable
flutter run
```

## Vérifier la feature

1. **Écran Récurrences** : Naviguer vers `/transactions/recurring` (depuis le menu ou bottom nav)
2. **Valider une récurrence** : Swipe droite sur un item → confirmer
3. **Passer une récurrence** : Swipe gauche sur un item
4. **Désactiver** : Long press → bottom sheet → Désactiver → confirmer dans le dialog
5. **Détail abonnement** : Tap sur un abonnement → voir l'historique des paiements + total cumulé
6. **Payer un abonnement** : Bouton "Payer" dans le détail
7. **Notifications** : Recevoir une notification de récurrence → actions Valider/Passer

## Lancer les tests

```bash
cd flutter
flutter test test/src/features/recurring/
flutter test test/src/features/subscriptions/
```

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `domain/models/recurring_transaction.dart` | Modèle Freezed |
| `features/recurring/application/recurring_list_notifier.dart` | State management |
| `features/recurring/presentation/recurring_list_screen.dart` | Écran principal |
| `features/subscriptions/presentation/subscription_detail_screen.dart` | Détail + paiements |
| `features/notifications/presentation/notification_panel.dart` | Actions notification |
