# API Contracts — 076-budget-category-tracking

## Endpoints modifiés

### GET /api/budgets/overview

Enrichi avec les dépenses non budgétées.

**Response** (200 OK):
```json
{
  "mois": "2026-03",
  "totalBudget": 1500.00,
  "totalDepense": 1200.00,
  "devise": "EUR",
  "items": [
    {
      "budgetId": "uuid",
      "categoryId": "uuid",
      "categoryNom": "Alimentation",
      "categoryIcone": "fork-knife",
      "categoryCouleur": "#f59e0b",
      "montantBudgetNormalise": 500.00,
      "montantDepense": 350.00,
      "devise": "EUR",
      "percentage": 70.0
    }
  ],
  "unbudgetedItems": [
    {
      "categoryId": "uuid",
      "categoryNom": "Cadeaux",
      "categoryIcone": "gift",
      "categoryCouleur": "#8b5cf6",
      "montantDepense": 120.00
    }
  ],
  "unbudgetedTotal": 120.00
}
```

### GET /api/budgets/history?month=yyyy-MM

Enrichi avec les dépenses non budgétées du mois historique.

**Response** (200 OK):
```json
{
  "mois": "2026-01",
  "totalBudget": 1400.00,
  "totalDepense": 1100.00,
  "devise": "EUR",
  "items": [
    {
      "categoryId": "uuid",
      "categoryNom": "Alimentation",
      "categoryIcone": "fork-knife",
      "categoryCouleur": "#f59e0b",
      "montantBudget": 500.00,
      "montantDepense": 420.00,
      "devise": "EUR",
      "tauxChange": 1.0,
      "percentage": 84.0
    }
  ],
  "unbudgetedItems": [
    {
      "categoryId": "uuid",
      "categoryNom": "Cadeaux",
      "categoryIcone": "gift",
      "categoryCouleur": "#8b5cf6",
      "montantDepense": 80.00
    }
  ],
  "unbudgetedTotal": 80.00
}
```

## Endpoints existants (inchangés)

| Méthode | Path | Description |
|---------|------|-------------|
| GET | /api/budgets | Liste tous les budgets (+ ?includeInactive=true) |
| GET | /api/budgets/:id | Détail d'un budget |
| POST | /api/budgets | Créer un budget |
| PUT | /api/budgets/:id | Modifier un budget |
| DELETE | /api/budgets/:id | Supprimer un budget |

## Effets de bord (nouveaux)

### POST /api/transactions, PUT /api/transactions/:id, DELETE /api/transactions/:id

Effet de bord ajouté : après toute opération sur une transaction de type DEPENSE, `BudgetService.checkThresholdsForCategory()` est appelé pour vérifier les seuils du budget associé à la catégorie de la transaction.

**Notifications générées** (via WebSocket STOMP + table notifications) :
- `BUDGET_THRESHOLD` : une fois par mois quand les dépenses atteignent le seuil configuré
- `BUDGET_EXCEEDED` : une fois par mois quand les dépenses atteignent 100%

### PUT /api/budgets/:id (actif toggle)

Le champ `actif` est déjà dans `BudgetRequest`. Aucune modification d'endpoint nécessaire. Les frontends envoient `actif: false` pour désactiver.
