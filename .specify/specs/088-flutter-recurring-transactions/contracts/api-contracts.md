# API Contracts: Flutter Recurring Transactions & Subscription Payments

**Feature**: 088-flutter-recurring-transactions
**Date**: 2026-03-15

## Endpoints consommés (backend existant KKS-085)

### Recurring Transactions

#### GET /api/transactions/recurring

Liste les transactions récurrentes actives.

**Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "montant": 50.00,
    "libelle": "Loyer",
    "type": "DEPENSE",
    "frequency": "MENSUEL",
    "nextOccurrence": "2026-03-15",
    "recurringActive": true,
    "category": {
      "id": "uuid",
      "nom": "Logement",
      "icone": "house",
      "couleur": "#4f46e5",
      "isSystem": false
    },
    "account": {
      "id": "uuid",
      "nom": "Compte courant",
      "icone": "bank",
      "couleur": "#f59e0b",
      "currency": "EUR"
    }
  }
]
```

#### POST /api/transactions/recurring/{id}/validate

Valide une récurrence : crée la transaction et avance nextOccurrence.

**Response** `201 Created`: `TransactionResponse` (la transaction créée)

#### PATCH /api/transactions/recurring/{id}/skip

Passe une récurrence : avance nextOccurrence sans créer de transaction.

**Response** `200 OK`: `RecurringTransactionResponse` (avec nextOccurrence mise à jour)

#### PATCH /api/transactions/recurring/{id}/deactivate

Désactive une récurrence.

**Response** `200 OK`: `RecurringTransactionResponse` (avec recurringActive=false)

### Subscription Payments

#### POST /api/subscriptions/{id}/pay

Paie un abonnement : crée une transaction DEPENSE liée.

**Response** `201 Created`:
```json
{
  "id": "uuid",
  "montant": 9.99,
  "date": "2026-03-15",
  "subscriptionName": "Netflix",
  "accountName": "Compte courant"
}
```

#### GET /api/subscriptions/{id}/payments

Liste l'historique des paiements d'un abonnement (ordre chronologique décroissant).

**Response** `200 OK`: `List<SubscriptionPaymentResponse>`

#### GET /api/subscriptions/{id}/payments/total

Total cumulé des paiements.

**Response** `200 OK`:
```json
{
  "subscriptionId": "uuid",
  "subscriptionName": "Netflix",
  "totalPaid": 119.88,
  "paymentCount": 12
}
```

## Error Handling

Tous les endpoints retournent les erreurs standard du backend :
- `401 Unauthorized` — JWT invalide/expiré
- `404 Not Found` — récurrence/abonnement inexistant
- `400 Bad Request` — validation échouée

Côté Flutter, les erreurs sont capturées par le notifier et propagées via `ListState.error` → affichées en snackbar.
