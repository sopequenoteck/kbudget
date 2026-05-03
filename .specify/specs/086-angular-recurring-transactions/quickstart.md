# Quickstart: 086-angular-recurring-transactions

**Date**: 2026-03-15

## Prérequis

1. Backend KKS-085 déployé et accessible (`localhost:8080/api`)
2. Node.js et Angular CLI installés
3. Branche `086-angular-recurring-transactions` checked out

## Lancer le dev

```bash
# Backend (profil dev)
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev

# Frontend
cd app && ng serve
# → http://localhost:4200
```

## Vérifier les endpoints backend

```bash
# Lister les récurrences actives (remplacer TOKEN)
curl -H "Authorization: Bearer TOKEN" http://localhost:8080/api/transactions/recurring

# Historique paiements abonnement
curl -H "Authorization: Bearer TOKEN" http://localhost:8080/api/subscriptions/{id}/payments
```

## Tests

```bash
cd app && ng test
```

## Fichiers clés à modifier/créer

| Action | Fichier | Description |
|--------|---------|-------------|
| CRÉER  | `core/models/recurring-transaction.model.ts` | Interface RecurringTransactionResponse |
| CRÉER  | `core/models/subscription-payment.model.ts` | Interface SubscriptionPaymentResponse |
| CRÉER  | `core/services/recurring-transaction.ts` | Service signal-based |
| CRÉER  | `features/transactions/components/recurring-list/` | Écran liste récurrences |
| CRÉER  | `features/subscriptions/components/subscription-detail/` | Écran détail abonnement |
| UPDATE | `core/models/notification.model.ts` | +RECURRING_TRANSACTION_DUE |
| UPDATE | `core/services/subscription.ts` | +pay, +getPayments, +getTotalPaid |
| UPDATE | `features/transactions/transactions.routes.ts` | +route 'recurring' |
| UPDATE | `features/subscriptions/subscriptions.routes.ts` | +route ':id' |
| UPDATE | `shared/components/notification-panel/` | +actions récurrence/abonnement |

## Patterns à suivre

- **Services** : signal-based (`signal()`, `computed()`, `refreshTrigger`)
- **Composants** : standalone, `OnPush`, `inject()` pour DI
- **Templates** : `@if`, `@for` (Angular 21 control flow)
- **Feedback** : `ToastService.success()` / `.error()`
- **Routes** : lazy-loaded via `loadComponent`
