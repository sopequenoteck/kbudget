# API Contract: Accounts (multi-currency)

## Modifications aux endpoints existants

### POST /api/accounts — Créer un compte

**Request** (AccountRequest modifié) :
```json
{
  "nom": "Compte Togo",
  "type": "COURANT",
  "soldeInitial": 50000,
  "icone": "🏦",
  "couleur": "#3b82f6",
  "actif": true,
  "currency": "XOF"          // NEW - optionnel, défaut = user.defaultCurrency
}
```

**Response** (AccountResponse modifié) :
```json
{
  "id": "uuid",
  "nom": "Compte Togo",
  "type": "COURANT",
  "soldeInitial": 50000,
  "solde": 50000,
  "icone": "🏦",
  "couleur": "#3b82f6",
  "isDefault": false,
  "actif": true,
  "currency": "XOF"          // NEW
}
```

**Règles** :
- Si `currency` absent → `user.defaultCurrency`
- Si `currency` invalide (pas dans l'enum) → 400

### PUT /api/accounts/{id} — Modifier un compte

**Request** : Identique à POST mais `currency` est ignoré (immuable FR-002). Si la valeur envoyée diffère de l'existante → 400 avec message "La devise d'un compte ne peut pas être modifiée".

### GET /api/accounts — Lister les comptes

**Response** : Chaque `AccountResponse` inclut `currency`.

### GET /api/accounts/{id} — Détail compte

**Response** : `AccountResponse` avec `currency`.

### POST /api/accounts/transfer — Virement

**Validation ajoutée** : Si `fromAccount.currency != toAccount.currency` → 400

```json
{
  "error": "Le virement entre comptes de devises différentes n'est pas autorisé"
}
```

### AccountSummary (nested dans TransactionResponse, SubscriptionResponse)

```json
{
  "id": "uuid",
  "nom": "Compte Principal",
  "icone": "🏦",
  "couleur": "#3b82f6",
  "currency": "EUR"           // NEW
}
```
