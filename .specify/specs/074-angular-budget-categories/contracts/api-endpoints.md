# API Contracts: Budget Endpoints

Endpoints consommés par le frontend Angular. Backend déjà implémenté (KKS-073).

## Endpoints

### POST /api/budgets — Créer un budget

```
Request:
  Content-Type: application/json
  Authorization: Bearer <jwt>
  Body: {
    "categoryId": "uuid",
    "montant": 500.00,
    "frequence": "MENSUEL",
    "currency": "EUR",          // optionnel, défaut EUR
    "seuilNotification": 80     // optionnel, défaut 80
  }

Response: 201 Created
  Body: BudgetResponse
```

### GET /api/budgets — Lister les budgets

```
Request:
  Authorization: Bearer <jwt>
  Query: ?includeInactive=false  // optionnel

Response: 200 OK
  Body: BudgetResponse[]
```

### GET /api/budgets/overview — Aperçu mensuel courant

```
Request:
  Authorization: Bearer <jwt>

Response: 200 OK
  Body: BudgetOverviewResponse
```

### GET /api/budgets/history — Historique d'un mois

```
Request:
  Authorization: Bearer <jwt>
  Query: ?month=2026-03  // requis, format yyyy-MM

Response: 200 OK
  Body: BudgetHistoryResponse
```

### GET /api/budgets/{id} — Obtenir un budget

```
Request:
  Authorization: Bearer <jwt>

Response: 200 OK
  Body: BudgetResponse
```

### PUT /api/budgets/{id} — Modifier un budget

```
Request:
  Content-Type: application/json
  Authorization: Bearer <jwt>
  Body: BudgetRequest (mêmes champs que POST)

Response: 200 OK
  Body: BudgetResponse
```

### DELETE /api/budgets/{id} — Supprimer un budget

```
Request:
  Authorization: Bearer <jwt>

Response: 204 No Content
```

## Codes d'erreur attendus

| Code | Cas |
|------|-----|
| 400 | Validation échouée (montant négatif, catégorie manquante) |
| 401 | JWT invalide ou expiré |
| 404 | Budget ou catégorie non trouvé |
| 409 | Budget déjà existant pour cette catégorie (contrainte unique) |
