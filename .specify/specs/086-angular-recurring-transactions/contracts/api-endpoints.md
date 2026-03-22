# API Endpoints Contract: 086-angular-recurring-transactions

**Date**: 2026-03-15
**Source**: Backend KKS-085 (existant, aucune modification requise)

## Transactions récurrentes

Base path: `/api/transactions/recurring`

### POST / — Créer une récurrence

**Request**: `RecurringTransactionRequest`
```json
{
  "montant": 50.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "categoryId": "uuid",
  "accountId": "uuid",
  "note": "Optionnel"
}
```

**Response**: `201 Created` → `RecurringTransactionResponse`
```json
{
  "id": "uuid",
  "montant": 50.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "recurringActive": true,
  "category": { "id": "uuid", "nom": "Logement", "icone": "🏠", "couleur": "#4f46e5" },
  "account": { "id": "uuid", "nom": "Compte courant" }
}
```

### GET / — Lister les récurrences actives

**Response**: `200 OK` → `RecurringTransactionResponse[]`

### POST /{id}/validate — Valider une occurrence

**Response**: `201 Created` → `TransactionResponse` (la transaction créée)

### PATCH /{id}/skip — Passer une occurrence

**Response**: `200 OK` → `RecurringTransactionResponse` (nextOccurrence avancée)

### PATCH /{id}/deactivate — Désactiver une récurrence

**Response**: `200 OK` → `RecurringTransactionResponse` (recurringActive = false)

## Paiements abonnements

Base path: `/api/subscriptions/{id}`

### POST /{id}/pay — Payer un abonnement

**Response**: `201 Created` → `SubscriptionPaymentResponse`
```json
{
  "id": "uuid",
  "montant": 9.99,
  "date": "2026-03-15",
  "subscriptionName": "Netflix",
  "accountName": "Compte courant"
}
```

### GET /{id}/payments — Historique des paiements

**Response**: `200 OK` → `SubscriptionPaymentResponse[]`

### GET /{id}/payments/total — Cumul des paiements

**Response**: `200 OK` → `Map<String, Object>`
```json
{
  "total": 119.88,
  "count": 12
}
```

## Erreurs communes

| Code | Situation |
|------|-----------|
| 404  | Récurrence ou abonnement introuvable |
| 400  | Récurrence déjà désactivée, validation invalide |
| 403  | Accès à une ressource d'un autre utilisateur |
