# API Contracts — Budget Endpoints

Backend déjà implémenté (073-backend-budget-categories). Ces contrats documentent les endpoints consommés par le client Flutter.

Base URL: `/api/budgets`

## POST /budgets — Create

**Request:**
```json
{
  "categoryId": "uuid",
  "montant": 500.00,
  "frequence": "MENSUEL",
  "currency": "EUR",
  "seuilNotification": 80,
  "actif": true
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "montant": 500.00,
  "currency": "EUR",
  "frequence": "MENSUEL",
  "seuilNotification": 80,
  "actif": true,
  "category": {
    "id": "uuid",
    "nom": "Alimentation",
    "icone": "🍕",
    "couleur": "#f59e0b"
  },
  "spent": null,
  "updatedAt": "2026-03-08T10:30:00"
}
```

**Errors:** 400 (validation), 409 (category already has budget), 403 (feature disabled)

## GET /budgets?includeInactive=false — List

**Response (200):**
```json
[
  {
    "id": "uuid",
    "montant": 500.00,
    "currency": "EUR",
    "frequence": "MENSUEL",
    "seuilNotification": 80,
    "actif": true,
    "category": { "id": "uuid", "nom": "...", "icone": "...", "couleur": "..." },
    "spent": 320.50,
    "updatedAt": "2026-03-08T10:30:00"
  }
]
```

## GET /budgets/overview — Current Month Dashboard

**Response (200):**
```json
{
  "month": "2026-03",
  "totalBudget": 1500.00,
  "totalSpent": 980.50,
  "percentage": 65.37,
  "currency": "EUR",
  "items": [
    {
      "budgetId": "uuid",
      "categoryId": "uuid",
      "categoryNom": "Alimentation",
      "categoryIcone": "🍕",
      "categoryCouleur": "#f59e0b",
      "montantBudget": 500.00,
      "montantBudgetNormalise": 500.00,
      "currency": "EUR",
      "montantDepense": 320.50,
      "percentage": 64.10,
      "frequence": "MENSUEL"
    }
  ]
}
```

## GET /budgets/history?month=2026-02 — Past Month

**Response (200):**
```json
{
  "month": "2026-02",
  "totalBudget": 1500.00,
  "totalSpent": 1200.00,
  "percentage": 80.00,
  "currency": "EUR",
  "items": [
    {
      "categoryId": "uuid",
      "categoryNom": "Alimentation",
      "categoryIcone": "🍕",
      "categoryCouleur": "#f59e0b",
      "montantBudget": 500.00,
      "currency": "EUR",
      "tauxChange": null,
      "montantDepense": 450.00,
      "percentage": 90.00,
      "createdAt": "2026-03-01T00:00:00"
    }
  ]
}
```

**Errors:** 400 (invalid month format, future/current month)

## GET /budgets/{id} — Get by ID

**Response (200):** Same as single item in list response.

## PUT /budgets/{id} — Update

**Request:** Same as POST body.
**Response (200):** Same as POST response.

## DELETE /budgets/{id} — Delete

**Response (204):** No content.
