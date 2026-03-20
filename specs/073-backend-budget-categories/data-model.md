# Data Model: Backend Budget Categories

**Feature**: 073-backend-budget-categories
**Date**: 2026-03-08

## Entities

### Budget

| Field | Type | Constraints | Default | Notes |
|-------|------|-------------|---------|-------|
| id | UUID | PK, auto-generated | — | `@GeneratedValue(strategy = GenerationType.UUID)` |
| montant | BigDecimal(12,2) | NOT NULL, @Positive | — | Montant du budget |
| currency | Currency (enum) | NOT NULL | EUR | `@Enumerated(EnumType.STRING)`, `@Builder.Default` |
| frequence | Frequency (enum) | NOT NULL | — | HEBDOMADAIRE, MENSUEL, ANNUEL |
| seuilNotification | Integer | NOT NULL, @Min(0) @Max(100) | 80 | Pourcentage d'alerte |
| actif | Boolean | NOT NULL | true | `@Builder.Default` |
| updatedAt | LocalDateTime | — | auto | `@UpdateTimestamp` |
| category | Category (FK) | NOT NULL, UNIQUE with user | — | `@ManyToOne(LAZY)`, ON DELETE CASCADE |
| user | User (FK) | NOT NULL | — | `@ManyToOne(LAZY)` |

**Contrainte unique**: `(category_id, user_id)` — un seul budget par categorie par utilisateur.

**Table SQL**: `budgets`

### BudgetSnapshot

| Field | Type | Constraints | Default | Notes |
|-------|------|-------------|---------|-------|
| id | UUID | PK, auto-generated | — | `@GeneratedValue(strategy = GenerationType.UUID)` |
| montantBudget | BigDecimal(12,2) | NOT NULL | — | Montant budget fige |
| currency | Currency (enum) | NOT NULL | — | Devise du budget au moment du snapshot |
| tauxChange | BigDecimal(20,6) | nullable | — | Taux de conversion vers devise principale (null si meme devise) |
| montantDepense | BigDecimal(12,2) | NOT NULL | — | Total depenses du mois pour cette categorie |
| mois | String(7) | NOT NULL | — | Format YYYY-MM |
| createdAt | LocalDateTime | NOT NULL, updatable=false | auto | `@CreationTimestamp` |
| category | Category (FK) | NOT NULL | — | `@ManyToOne(LAZY)`, ON DELETE CASCADE |
| user | User (FK) | NOT NULL | — | `@ManyToOne(LAZY)` |

**Contrainte unique**: `(mois, category_id, user_id)` — un seul snapshot par mois, categorie et utilisateur.

**Table SQL**: `budget_snapshots`

**PAS de FK vers Budget** — les snapshots survivent a la suppression du budget (FR-015).

## Relationships

```
User 1──* Budget *──1 Category
User 1──* BudgetSnapshot *──1 Category

Budget ← pas de FK ← BudgetSnapshot
```

- Category supprimee → CASCADE supprime Budget ET BudgetSnapshot
- Budget supprime (hard delete) → BudgetSnapshot conserve

## Enums modifies

### Frequency (existant)

```
MENSUEL, ANNUEL → HEBDOMADAIRE, MENSUEL, ANNUEL
```

### Feature (existant)

```
SUBSCRIPTIONS, DEBTS, SHOP → SUBSCRIPTIONS, DEBTS, SHOP, BUDGETS
```

## Normalisation mensuelle

| Frequence | Formule | Exemple |
|-----------|---------|---------|
| HEBDOMADAIRE | montant * 4.33 | 100 → 433.00 |
| MENSUEL | montant | 500 → 500.00 |
| ANNUEL | montant / 12 | 1200 → 100.00 |

Constante : `WEEKS_PER_MONTH = BigDecimal.valueOf(4.33)`

## Indexes

| Table | Index | Colonnes |
|-------|-------|----------|
| budgets | idx_budgets_user_id | user_id |
| budgets | idx_budgets_category_id | category_id |
| budget_snapshots | idx_snapshots_user_id | user_id |
| budget_snapshots | idx_snapshots_category_id | category_id |
| budget_snapshots | idx_snapshots_mois | mois |
