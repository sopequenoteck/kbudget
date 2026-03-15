# API Contracts: Transactions Recurrentes & Paiements Abonnements

**Date**: 2026-03-14 | **Branch**: `085-recurring-transactions-backend`

## Nouveaux Endpoints

### 1. POST /api/transactions/recurring — Creer une transaction recurrente

**Request**:
```json
{
  "montant": 800.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "categoryId": "uuid-category",
  "accountId": "uuid-account",
  "note": "Loyer mensuel appartement"
}
```

**Validation**:
- `montant`: @NotNull @Positive
- `libelle`: @NotBlank @Size(max=255)
- `type`: @NotNull (DEPENSE ou RECETTE)
- `frequency`: @NotNull (HEBDOMADAIRE, MENSUEL, ANNUEL)
- `nextOccurrence`: @NotNull @FutureOrPresent
- `categoryId`: UUID optionnel
- `accountId`: UUID optionnel (fallback compte par defaut)
- `note`: @Size(max=500) optionnel

**Response**: `201 Created`
```json
{
  "id": "uuid",
  "montant": 800.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "recurringActive": true,
  "category": { "id": "uuid", "nom": "Logement", "icone": "house", "couleur": "#...", "isSystem": false },
  "account": { "id": "uuid", "nom": "Compte courant", "icone": "bank", "couleur": "#...", "currency": "EUR" }
}
```

**Errors**: `400` (validation), `401` (non authentifie), `404` (account/category introuvable)

---

### 2. GET /api/transactions/recurring — Lister les recurrences actives

**Response**: `200 OK`
```json
[
  {
    "id": "uuid",
    "montant": 800.00,
    "libelle": "Loyer",
    "type": "DEPENSE",
    "frequency": "MENSUEL",
    "nextOccurrence": "2026-04-01",
    "recurringActive": true,
    "category": { "id": "uuid", "nom": "Logement", "icone": "house", "couleur": "#...", "isSystem": false },
    "account": { "id": "uuid", "nom": "Compte courant", "icone": "bank", "couleur": "#...", "currency": "EUR" }
  }
]
```

**Note**: Retourne uniquement les recurrences actives (`recurringActive = true`) de l'utilisateur authentifie, triees par `nextOccurrence` ASC.

---

### 3. POST /api/transactions/recurring/{id}/validate — Valider une occurrence

**Request**: Aucun body

**Response**: `201 Created` — Retourne la **nouvelle transaction creee** (pas la recurrence)
```json
{
  "id": "uuid-new-transaction",
  "montant": 800.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "date": "2026-04-01",
  "category": { "id": "uuid", "nom": "Logement", "icone": "house", "couleur": "#...", "isSystem": false },
  "account": { "id": "uuid", "nom": "Compte courant", "icone": "bank", "couleur": "#...", "currency": "EUR" },
  "note": null,
  "transferId": null,
  "productId": null,
  "productName": null,
  "debtId": null
}
```

**Side effects**:
- Cree une nouvelle Transaction standard (non recurrente)
- Avance `nextOccurrence` de la recurrence selon sa frequence
- Verifie les seuils budgetaires si DEPENSE avec categorie

**Errors**: `400` (recurrence desactivee), `401`, `404` (recurrence introuvable ou pas au user)

---

### 4. PATCH /api/transactions/recurring/{id}/skip — Passer une occurrence

**Request**: Aucun body

**Response**: `200 OK` — Retourne la recurrence mise a jour
```json
{
  "id": "uuid",
  "montant": 800.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-05-01",
  "recurringActive": true,
  "category": { ... },
  "account": { ... }
}
```

**Side effects**: Avance `nextOccurrence` sans creer de transaction.

**Errors**: `400` (recurrence desactivee), `401`, `404`

---

### 5. PATCH /api/transactions/recurring/{id}/deactivate — Desactiver une recurrence

**Request**: Aucun body

**Response**: `200 OK` — Retourne la recurrence desactivee
```json
{
  "id": "uuid",
  "montant": 800.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "recurringActive": false,
  "category": { ... },
  "account": { ... }
}
```

**Errors**: `400` (deja desactivee), `401`, `404`

---

### 6. POST /api/subscriptions/{id}/pay — Payer un abonnement

**Request**: Aucun body

**Response**: `201 Created`
```json
{
  "id": "uuid-transaction",
  "montant": 13.49,
  "date": "2026-03-14",
  "subscriptionName": "Netflix",
  "accountName": "Compte courant"
}
```

**Side effects**:
- Cree une Transaction (type=DEPENSE, subscriptionId=sub.id)
- La prochaine echeance sera calculee dynamiquement (dateDebut inchangee)
- Utilise `subscription.account` ou le compte par defaut si null
- Verifie les seuils budgetaires si categorie presente

**Errors**: `400` (abonnement inactif), `401`, `404`

---

### 7. GET /api/subscriptions/{id}/payments — Historique des paiements

**Response**: `200 OK`
```json
[
  {
    "id": "uuid-transaction",
    "montant": 13.49,
    "date": "2026-03-14",
    "subscriptionName": "Netflix",
    "accountName": "Compte courant"
  },
  {
    "id": "uuid-transaction-2",
    "montant": 13.49,
    "date": "2026-02-14",
    "subscriptionName": "Netflix",
    "accountName": "Compte courant"
  }
]
```

**Note**: Trie par date DESC. Inclut le cumul total dans un header ou champ additionnel (voir ci-dessous).

---

### 8. GET /api/subscriptions/{id}/payments/total — Cumul des paiements

**Response**: `200 OK`
```json
{
  "subscriptionId": "uuid",
  "subscriptionName": "Netflix",
  "totalPaid": 161.88,
  "paymentCount": 12
}
```

## DTOs

### RecurringTransactionRequest (nouveau)

| Champ | Type | Obligatoire | Validation |
|-------|------|-------------|------------|
| montant | BigDecimal | Oui | @NotNull @Positive |
| libelle | String | Oui | @NotBlank @Size(max=255) |
| type | TransactionType | Oui | @NotNull (DEPENSE ou RECETTE) |
| frequency | Frequency | Oui | @NotNull |
| nextOccurrence | LocalDate | Oui | @NotNull @FutureOrPresent |
| categoryId | UUID | Non | - |
| accountId | UUID | Non | - |
| note | String | Non | @Size(max=500) |

### RecurringTransactionResponse (nouveau)

| Champ | Type | Nullable |
|-------|------|----------|
| id | UUID | Non |
| montant | BigDecimal | Non |
| libelle | String | Non |
| type | TransactionType | Non |
| frequency | Frequency | Non |
| nextOccurrence | LocalDate | Non |
| recurringActive | Boolean | Non |
| category | CategoryResponse | Oui |
| account | AccountSummary | Oui |

### SubscriptionPaymentResponse (nouveau)

| Champ | Type | Nullable |
|-------|------|----------|
| id | UUID | Non |
| montant | BigDecimal | Non |
| date | LocalDate | Non |
| subscriptionName | String | Non |
| accountName | String | Non |
