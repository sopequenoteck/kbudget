# API Contract: Subscriptions (multi-currency)

## Modifications aux endpoints existants

### POST /api/subscriptions — Créer un abonnement

**Request** (SubscriptionRequest modifié) :
```json
{
  "nom": "Netflix",
  "montant": 13.49,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-01",
  "actif": true,
  "categoryId": "uuid-or-null",
  "accountId": "uuid-or-null",
  "currency": "EUR"            // NEW - voir règles ci-dessous
}
```

**Response** (SubscriptionResponse modifié) :
```json
{
  "id": "uuid",
  "nom": "Netflix",
  "montant": 13.49,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-01",
  "actif": true,
  "category": { ... },
  "account": { "id": "uuid", "nom": "Compte Principal", "icone": "🏦", "couleur": "#3b82f6", "currency": "EUR" },
  "currency": "EUR"            // NEW
}
```

**Règles devise** :
- Si `accountId` fourni → `currency` forcée à `account.currency` (valeur du request ignorée)
- Si `accountId` null et `currency` fourni → utilise la valeur du request
- Si `accountId` null et `currency` absent → `user.defaultCurrency`

### PUT /api/subscriptions/{id} — Modifier un abonnement

**Règles devise sur update** :
- Si `accountId` change vers un compte → `currency` forcée au nouveau `account.currency`
- Si `accountId` passe à null → `currency` du request ou conserve l'existante
- Si `accountId` inchangé et non-null → `currency` reste celle du compte (ignorée dans request)

### GET /api/subscriptions — Lister les abonnements

**Response** : Chaque `SubscriptionResponse` inclut `currency`.

### GET /api/subscriptions/{id} — Détail abonnement

**Response** : `SubscriptionResponse` avec `currency`.
