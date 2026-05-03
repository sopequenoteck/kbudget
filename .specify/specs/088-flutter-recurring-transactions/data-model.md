# Data Model: Flutter Recurring Transactions & Subscription Payments

**Feature**: 088-flutter-recurring-transactions
**Date**: 2026-03-15

## Nouveaux modèles

### RecurringTransaction (Freezed)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | String | non | UUID |
| montant | double | non | Montant de la transaction |
| libelle | String | non | Libellé |
| type | TransactionType | non | DEPENSE / RECETTE |
| frequency | Frequency | non | HEBDOMADAIRE / MENSUEL / ANNUEL |
| nextOccurrence | DateTime | non | Prochaine date d'échéance |
| recurringActive | bool | non | Statut actif |
| categoryName | String | oui | Nom catégorie (dénormalisé) |
| categoryIcon | String | oui | Icône catégorie |
| categoryColor | String | oui | Couleur catégorie |
| accountName | String | oui | Nom du compte |
| accountCurrency | Currency | oui | Devise du compte |

**Statut dérivé** (calculé côté client) :
- `overdue` : `nextOccurrence < today`
- `today` : `nextOccurrence == today`
- `upcoming` : `nextOccurrence > today`

### SubscriptionPayment (Freezed)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | String | non | UUID |
| montant | double | non | Montant payé |
| date | DateTime | non | Date du paiement |
| subscriptionName | String | oui | Nom de l'abonnement |
| accountName | String | oui | Nom du compte utilisé |

### SubscriptionTotalPaid (Freezed)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| subscriptionId | String | non | UUID abonnement |
| subscriptionName | String | oui | Nom abonnement |
| totalPaid | double | non | Total cumulé |
| paymentCount | int | non | Nombre de paiements |

## Modèles existants modifiés

Aucun modèle existant n'est modifié. Les DTOs sont créés pour mapper les réponses API.

## Enums modifiés

### NotificationType — ajout

- `recurringTransactionDue` → mappe vers `RECURRING_TRANSACTION_DUE` backend

### EntityType — ajout

- `recurringTransaction` → mappe vers `RECURRING_TRANSACTION` backend

## DTOs (data/remote/dtos/)

### RecurringTransactionResponse (json_serializable)

Mappe directement vers `RecurringTransaction` domain model. Inclut `category` (nested object) et `account` (nested object) dénormalisés dans les champs plats du model.

### SubscriptionPaymentResponse (json_serializable)

Mappe directement vers `SubscriptionPayment` domain model.

## Relations

```
RecurringTransaction ─── consommé par ──→ RecurringListNotifier ──→ RecurringListScreen
                    └── créé par ──→ RecurringTransactionRemoteDataSource (Dio)

SubscriptionPayment ─── consommé par ──→ SubscriptionNotifier ──→ SubscriptionDetailScreen
                   └── créé par ──→ SubscriptionRemoteDataSource (Dio, endpoints enrichis)

NotificationModel ─── actions ──→ RecurringListNotifier.validate/skip
                 └── actions ──→ SubscriptionNotifier.pay
                 └── deep link ──→ go_router → RecurringListScreen / SubscriptionDetailScreen
```

## Repository

### RecurringTransactionRepository (interface)

```
listActive() → Future<List<RecurringTransaction>>
validate(String id) → Future<void>
skip(String id) → Future<RecurringTransaction>
deactivate(String id) → Future<RecurringTransaction>
```

### SubscriptionRepository (enrichissement interface existante)

```
pay(String id) → Future<SubscriptionPayment>          # NEW
getPayments(String id) → Future<List<SubscriptionPayment>>  # NEW
getTotalPaid(String id) → Future<SubscriptionTotalPaid>      # NEW
```
