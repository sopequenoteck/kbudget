# Data Model: Dashboard Finance

**Date**: 2026-03-15
**Feature**: 090-finance-dashboard

## Pas de nouvelle entite backend

Cette feature est frontend-only. Aucune nouvelle table, migration ou entite JPA n'est creee. Le dashboard consomme les DTOs existants retournes par les endpoints actuels.

## Modeles frontend enrichis

### Angular — Pas de nouveau modele

Les services existants retournent deja les types necessaires :
- `Account` (AccountService)
- `MonthlySummary` (TransactionService.getSummary) — `{ month, year, totalRecettes, totalDepenses, solde, currency }`
- `BudgetOverview` / `BudgetOverviewItem` (BudgetService.getOverview)
- `Transaction` (TransactionService.getAll)
- `ExchangeRate` (ExchangeRateService)
- `UserInfo` (UserService.getProfile)

Les donnees derivees (variation patrimoine, comparaison mois-1) sont calculees via `computed()` signals dans le composant dashboard.

### Flutter — Hors scope

L'adaptation Flutter fera l'objet d'une spec separee.

## Donnees derivees (calculs frontend Angular)

| Donnee derivee | Formule | Sources |
|---|---|---|
| Net du mois | totalRecettes - totalDepenses (mois courant) | MonthlySummary (mois courant) |
| Patrimoine debut de mois | totalBalance - netDuMois | TotalBalance + MonthlySummary |
| Variation patrimoine % | netDuMois / patrimoineDebutMois * 100 | Calcul derive |
| Variation revenus vs mois-1 | totalRecettes(mois) - totalRecettes(mois-1) | MonthlySummary (mois courant + mois-1) |
| Variation depenses vs mois-1 | totalDepenses(mois) - totalDepenses(mois-1) | MonthlySummary (mois courant + mois-1) |
| Contre-valeur | montant * tauxDeChange | ExchangeRate |
| Budgets tries par urgence | sort by percentage DESC, take 4 | BudgetOverview.items |

## Endpoints consommes (recap)

| Endpoint | Donnee dashboard | Appels |
|---|---|---|
| GET /accounts/total-balance | Patrimoine total | 1x au chargement + refresh |
| GET /transactions/summary?month=M&year=Y | Revenus/depenses + variation | 2x (mois courant + mois-1) |
| GET /budgets/overview | Resume budgets | 1x au chargement + refresh |
| GET /transactions | 5 dernieres transactions | 1x au chargement + refresh |
| GET /exchange-rates | Taux de change | 1x au chargement |
| GET /users/me | Nom utilisateur | 1x (deja charge par le shell) |
| GET /notifications/unread-count | Badge notifications | Polling existant (30s) |
