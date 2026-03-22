# Data Model: 074-angular-budget-categories

Ce document décrit les interfaces TypeScript côté Angular pour consommer l'API Budget (KKS-073).

## Interfaces

### Budget (réponse API)

```typescript
export interface Budget {
  id: string;
  montant: number;
  currency: string;            // 'EUR' | 'USD' | 'GBP' | 'CHF' | 'XOF'
  frequence: string;           // 'HEBDOMADAIRE' | 'MENSUEL' | 'ANNUEL'
  seuilNotification: number;   // 0-100
  actif: boolean;
  category: CategoryResponse;  // { id, nom, icone, couleur }
  spent: number;               // montant dépensé période courante
  updatedAt: string;
}
```

### BudgetRequest (création/modification)

```typescript
export interface BudgetRequest {
  categoryId: string;
  montant: number;
  frequence: string;           // 'HEBDOMADAIRE' | 'MENSUEL' | 'ANNUEL'
  currency?: string;           // défaut: 'EUR'
  seuilNotification?: number;  // défaut: 80
  actif?: boolean;
}
```

### BudgetOverview (dashboard + écran principal)

```typescript
export interface BudgetOverview {
  month: string;               // 'yyyy-MM'
  totalBudget: number;
  totalSpent: number;
  percentage: number;
  currency: string;
  items: BudgetOverviewItem[];
}

export interface BudgetOverviewItem {
  budgetId: string;
  categoryId: string;
  categoryNom: string;
  categoryIcone: string;
  categoryCouleur: string;
  montantBudget: number;
  montantBudgetNormalise: number;  // normalisé en mensuel
  currency: string;
  montantDepense: number;
  percentage: number;
  frequence: string;
}
```

### BudgetHistory (mois passés)

```typescript
export interface BudgetHistory {
  month: string;               // 'yyyy-MM'
  totalBudget: number;
  totalSpent: number;
  percentage: number;
  currency: string;
  items: BudgetHistoryItem[];
}

export interface BudgetHistoryItem {
  categoryId: string;
  categoryNom: string;
  categoryIcone: string;
  categoryCouleur: string;
  montantBudget: number;
  currency: string;
  tauxChange: number | null;
  montantDepense: number;
  percentage: number;
  createdAt: string;
}
```

### CategoryResponse (réutilisée)

```typescript
// Déjà existante dans l'app — interface de la réponse catégorie
export interface CategoryResponse {
  id: string;
  nom: string;
  icone: string;
  couleur: string;
}
```

## Relations

```
BudgetRequest ──POST/PUT──► API ──► BudgetResponse (Budget)
                                         │
                                         └──► CategoryResponse (nested)

GET /budgets/overview ──► BudgetOverview
                              └──► BudgetOverviewItem[] (inclut "Autre")

GET /budgets/history?month=yyyy-MM ──► BudgetHistory
                                           └──► BudgetHistoryItem[]
```

## Validation (formulaire Reactive Forms)

| Champ | Validators | Message erreur |
|-------|-----------|----------------|
| `categoryId` | `Validators.required` | "La catégorie est requise" |
| `montant` | `Validators.required`, `Validators.min(0.01)` | "Le montant doit être supérieur à 0" |
| `frequence` | `Validators.required` | "La fréquence est requise" |
| `currency` | Optionnel (défaut 'EUR') | — |
| `seuilNotification` | `Validators.min(0)`, `Validators.max(100)` | "Le seuil doit être entre 0 et 100" |

## Enums (constantes)

```typescript
export const FREQUENCIES = [
  { value: 'HEBDOMADAIRE', label: 'Hebdomadaire' },
  { value: 'MENSUEL', label: 'Mensuel' },
  { value: 'ANNUEL', label: 'Annuel' },
] as const;
```
