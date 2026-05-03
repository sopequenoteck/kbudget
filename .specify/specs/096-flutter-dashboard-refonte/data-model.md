# Data Model: Refonte Dashboard Flutter

**Feature**: 096-flutter-dashboard-refonte | **Date**: 2026-03-20

## Entites modifiees

### DashboardState (Freezed — modification)

Etat agrege du dashboard. Fichier : `flutter/lib/src/features/dashboard/application/dashboard_state.dart`

| Champ | Type | Default | Action | Notes |
|-------|------|---------|--------|-------|
| accounts | List\<Account\> | [] | CONSERVER | Comptes actifs pour calcul patrimoine |
| defaultAccount | Account? | null | CONSERVER | Compte par defaut (hero card Angular) |
| currentSummary | MonthlySummary? | null | AJOUTER | Totaux revenus/depenses mois courant |
| previousSummary | MonthlySummary? | null | AJOUTER | Totaux revenus/depenses mois precedent |
| recentTransactions | List\<Transaction\> | [] | CONSERVER | 5 dernieres transactions |
| activeCurrency | Currency | Currency.eur | CONSERVER | Devise selectionnee via pill |
| exchangeRates | List\<ExchangeRate\> | [] | CONSERVER | Taux pour conversions |
| currencies | List\<Currency\> | [Currency.eur] | CONSERVER | Devises utilisateur ordonnees |
| userName | String? | null | CONSERVER | Prenom pour salutation |
| isLoading | bool | true | CONSERVER | Chargement initial |
| error | String? | null | CONSERVER | Message d'erreur |
| monthlySummaries | List\<MonthlySummary\> | [] | SUPPRIMER | Remplace par currentSummary/previousSummary |
| selectedMonth | int | now.month | SUPPRIMER | Plus de MonthSelector |
| selectedYear | int | now.year | SUPPRIMER | Plus de MonthSelector |
| isSummaryLoading | bool | false | SUPPRIMER | Plus de chargement separe |
| subscriptionMonthlyTotal | double | 0.0 | SUPPRIMER | Plus de MiniCards |
| activeSubscriptionCount | int | 0 | SUPPRIMER | Plus de MiniCards |
| debtNetBalance | double | 0.0 | SUPPRIMER | Plus de MiniCards |
| activeDebtCount | int | 0 | SUPPRIMER | Plus de MiniCards |

### Calculs derives (dans DashboardNotifier, pas dans le state)

| Calcul | Formule | Notes |
|--------|---------|-------|
| patrimoine total | sum(account.solde converti en activeCurrency) pour tous comptes actifs | Via CurrencyConverter existant |
| hasMissingRate | true si au moins un compte n'a pas de taux de conversion | Indicateur warning |
| net du mois | currentSummary.totalRecettes - currentSummary.totalDepenses | En devise principale |
| patrimoine debut mois | patrimoine (en devise principale) - net du mois | Approximation |
| variation % | (net du mois / patrimoine debut mois) * 100 | null si patrimoine debut = 0 |
| variation revenus | currentSummary.totalRecettes - previousSummary.totalRecettes | Delta absolu |
| variation depenses | currentSummary.totalDepenses - previousSummary.totalDepenses | Delta absolu |
| devise secondaire | currencies[1] si currencies.length >= 2 et != activeCurrency, sinon currencies[0] si != activeCurrency, sinon null | Aligne sur Angular |

## Entites existantes reutilisees (sans modification)

| Entite | Fichier | Usage |
|--------|---------|-------|
| Account | domain/models/account.dart | Solde, devise, nom, icone pour patrimoine |
| Transaction | domain/models/transaction.dart | Liste recentes, categoryId, montant, type, date, account |
| MonthlySummary | domain/models/monthly_summary.dart | totalRecettes, totalDepenses, bilan, currency |
| ExchangeRate | domain/models/exchange_rate.dart | Taux pour conversions |
| Category | domain/models/category.dart | Icone et couleur pour transactions |
| Currency | domain/enums/enums.dart | Enum devise |

## Pas de nouvelle table/migration

Aucun changement de schema de donnees. Le dashboard consomme les APIs existantes.
