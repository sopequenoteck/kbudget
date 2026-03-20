# API Contract: Budget Categories

**Base path**: `/api/budgets`
**Auth**: JWT Bearer token (toutes les routes)
**Feature toggle**: BUDGETS (403 si desactive)

## Endpoints

### POST /budgets — Creer un budget

**Request**:
```json
{
  "categoryId": "uuid",
  "montant": 500.00,
  "frequence": "MENSUEL",
  "currency": "EUR",
  "seuilNotification": 80
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| categoryId | UUID | oui | Categorie existante du user |
| montant | BigDecimal | oui | @Positive |
| frequence | Frequency | oui | HEBDOMADAIRE, MENSUEL, ANNUEL |
| currency | Currency | non | Defaut: EUR |
| seuilNotification | Integer | non | @Min(0) @Max(100), defaut: 80 |

**Response 201**:
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
    "icone": "fork-knife",
    "couleur": "#f59e0b",
    "isSystem": true
  },
  "spent": null,
  "updatedAt": "2026-03-08T10:30:00"
}
```

**Erreurs**: 400 (validation), 409 (budget deja existant pour cette categorie), 404 (categorie non trouvee)

---

### GET /budgets — Lister les budgets

**Query params**:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| includeInactive | boolean | false | Inclure les budgets desactives |

**Response 200**: `BudgetResponse[]` — chaque budget inclut `spent` (montant depense du mois courant).

---

### GET /budgets/{id} — Consulter un budget

**Response 200**: `BudgetResponse` avec `spent` calcule.

**Erreurs**: 404 (non trouve)

---

### PUT /budgets/{id} — Modifier un budget

**Request**:
```json
{
  "categoryId": "uuid",
  "montant": 600.00,
  "frequence": "MENSUEL",
  "currency": "EUR",
  "seuilNotification": 90,
  "actif": false
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| actif | Boolean | non | Permet desactivation temporaire |

**Response 200**: `BudgetResponse` mis a jour.

**Erreurs**: 400 (validation), 404 (non trouve), 409 (conflit si changement categoryId vers categorie deja budgetee)

---

### DELETE /budgets/{id} — Supprimer un budget

**Response 204**: No content. Hard delete. Snapshots conserves.

**Erreurs**: 404 (non trouve)

---

### GET /budgets/overview — Tableau de bord du mois courant

**Aucun parametre**.

**Response 200**:
```json
{
  "month": "2026-03",
  "totalBudget": 1500.00,
  "totalSpent": 890.00,
  "percentage": 59.33,
  "currency": "EUR",
  "items": [
    {
      "budgetId": "uuid",
      "categoryId": "uuid",
      "categoryNom": "Alimentation",
      "categoryIcone": "fork-knife",
      "categoryCouleur": "#f59e0b",
      "montantBudget": 500.00,
      "montantBudgetNormalise": 500.00,
      "currency": "EUR",
      "montantDepense": 320.00,
      "percentage": 64.00,
      "frequence": "MENSUEL"
    }
  ]
}
```

**Calculs**:
- `totalBudget`: somme des `montantBudgetNormalise` convertis en devise principale
- `totalSpent`: somme des `montantDepense` du mois courant (sans conversion — montants dans la devise des transactions)
- `percentage`: `(totalSpent / totalBudget) * 100`, arrondi 2 decimales
- `montantBudgetNormalise`: HEBDO * 4.33, MENSUEL * 1, ANNUEL / 12
- Conversion devise via taux de change si budget.currency != currencies[0]

**Erreurs**: 400 (taux de change manquant pour une devise)

---

### GET /budgets/history — Historique d'un mois passe

**Query params**:

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| month | String | oui | Format YYYY-MM (mois passe uniquement) |

**Response 200**:
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
      "categoryIcone": "fork-knife",
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

**Comportement**:
- Si snapshots existent pour ce mois → retourne les snapshots
- Si pas de snapshots → les cree a la volee (lazy) a partir des budgets actifs **au moment de la consultation**, puis retourne
- Si mois courant ou futur → 400 Bad Request
- Si aucun budget ni depense pour ce mois → liste vide

**Limitation**: Les snapshots lazy sont bases sur les budgets actifs au moment de la consultation. Un budget supprime ou desactive entre le mois cible et la date de consultation ne sera pas capture.

**Erreurs**: 400 (mois invalide ou mois courant/futur)

## DTOs

### BudgetRequest (record)

```java
public record BudgetRequest(
    @NotNull UUID categoryId,
    @NotNull @Positive BigDecimal montant,
    @NotNull Frequency frequence,
    Currency currency,
    @Min(0) @Max(100) Integer seuilNotification,
    Boolean actif
) {}
```

### BudgetResponse (record)

```java
public record BudgetResponse(
    UUID id,
    BigDecimal montant,
    String currency,
    String frequence,
    Integer seuilNotification,
    Boolean actif,
    CategoryResponse category,
    BigDecimal spent,
    LocalDateTime updatedAt
) {}
```

### BudgetOverviewResponse (record)

```java
public record BudgetOverviewResponse(
    String month,
    BigDecimal totalBudget,
    BigDecimal totalSpent,
    BigDecimal percentage,
    String currency,
    List<BudgetOverviewItemResponse> items
) {}
```

### BudgetOverviewItemResponse (record)

```java
public record BudgetOverviewItemResponse(
    UUID budgetId,
    UUID categoryId,
    String categoryNom,
    String categoryIcone,
    String categoryCouleur,
    BigDecimal montantBudget,
    BigDecimal montantBudgetNormalise,
    String currency,
    BigDecimal montantDepense,
    BigDecimal percentage,
    String frequence
) {}
```

### BudgetHistoryResponse (record)

```java
public record BudgetHistoryResponse(
    String month,
    BigDecimal totalBudget,
    BigDecimal totalSpent,
    BigDecimal percentage,
    String currency,
    List<BudgetHistoryItemResponse> items
) {}
```

### BudgetHistoryItemResponse (record)

```java
public record BudgetHistoryItemResponse(
    UUID categoryId,
    String categoryNom,
    String categoryIcone,
    String categoryCouleur,
    BigDecimal montantBudget,
    String currency,
    BigDecimal tauxChange,
    BigDecimal montantDepense,
    BigDecimal percentage,
    LocalDateTime createdAt
) {}
```
