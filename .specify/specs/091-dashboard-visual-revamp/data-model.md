# Data Model: Dashboard Visual Revamp

**Branch**: `091-dashboard-visual-revamp` | **Date**: 2026-03-15

## Aucune modification de données

Cette feature est purement visuelle (CSS/SCSS + HTML template mineur). Aucune entité, aucun DTO, aucune table n'est créée ou modifiée.

### Données consommées (lecture seule, existantes)

| Donnée | Source | Utilisée par |
|--------|--------|--------------|
| `BudgetOverviewItem.percentage` | `BudgetService.getOverview()` | Couleur des barres de budget |
| `BudgetOverviewItem.seuilNotification` | `BudgetService.getOverview()` | Seuil warning des barres (si exposé) |
| `Transaction.category.icone` | `TransactionService.getAll()` | Cercle emoji (déjà implémenté via ListItem) |
| `Account.solde`, `Account.currency` | `AccountService.getAll()` | Montant patrimoine hero card |
| `MonthlySummary.totalRecettes/totalDepenses` | `TransactionService.getSummary()` | Badges variation |

### Note sur seuilNotification

Le `BudgetOverviewItem` actuel expose `percentage` mais pas `seuilNotification`. Deux options :
1. **Utiliser le seuil hardcodé 80%** (déjà en place dans le composant budget-summary)
2. **Exposer `seuilNotification` dans le DTO** (nécessite un changement backend mineur)

Décision : conserver le seuil hardcodé 80% pour cette feature visuelle. Le composant budget-summary utilise déjà `item.percentage >= 80` pour la classe `--warning`. Ce comportement est cohérent avec le défaut backend.
