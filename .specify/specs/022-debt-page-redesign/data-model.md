# Data Model: Redesign page Dettes

**Date**: 2026-02-13 | **Branch**: `022-debt-page-redesign`

## Modèle existant (inchangé)

```typescript
// app/src/app/core/models/debt.model.ts

enum DebtType {
  EMPRUNT = 'EMPRUNT',  // "Je dois" — l'utilisateur a emprunté
  PRET = 'PRET',        // "On me doit" — l'utilisateur a prêté
}

interface Debt {
  id: string;
  personne: string;
  montant: number;
  sens: DebtType;
  date: string;          // ISO date string
  rembourse: boolean;
  category: Category | null;
}
```

## Structure computed signals (nouveau)

```
debts: Signal<Debt[]>                    // source: API GET /debts (toutes)
  │
  ├── activeDebts: Computed<Debt[]>      // filter: !rembourse
  │   ├── totalJeDois: Computed<number>  // sum(EMPRUNT.montant)   → KPI
  │   ├── totalOnMeDoit: Computed<number>// sum(PRET.montant)      → KPI
  │   └── netBalance: Computed<number>   // totalOnMeDoit - totalJeDois → KPI
  │
  └── filteredDebts: Computed<Debt[]>    // filter: statusFilter (ALL/EN_COURS/REMBOURSE)
      ├── debtsOnMeDoit: Computed<Debt[]>// filter: PRET, sort: date desc → Section 1
      │   └── sectionTotalOnMeDoit: Computed<number>  // sum → Header
      └── debtsJeDois: Computed<Debt[]>  // filter: EMPRUNT, sort: date desc → Section 2
          └── sectionTotalJeDois: Computed<number>    // sum → Header
```

## Mapping signal → UI

| Signal | Usage UI | Condition d'affichage |
|--------|----------|----------------------|
| `totalJeDois` | KPI card "Je dois" | `hasDebts()` |
| `totalOnMeDoit` | KPI card "On me doit" | `hasDebts()` |
| `netBalance` | KPI card "Solde net" | `hasDebts()` |
| `debtsOnMeDoit` | Section "On me doit" (liste) | `debtsOnMeDoit().length > 0` |
| `debtsJeDois` | Section "Je dois" (liste) | `debtsJeDois().length > 0` |
| `sectionTotalOnMeDoit` | Header section "On me doit" | Section visible |
| `sectionTotalJeDois` | Header section "Je dois" | Section visible |

## Aucun changement backend

- Pas de nouvelle entité
- Pas de nouveau endpoint
- Pas de migration
- L'API `GET /api/debts` existante retourne déjà toutes les dettes quand appelée sans paramètre
