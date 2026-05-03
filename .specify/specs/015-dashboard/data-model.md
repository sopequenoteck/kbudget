# Data Model: Écran Dashboard

**Feature**: 015-dashboard | **Date**: 2026-02-12

## Entités utilisées (existantes — aucune nouvelle entité)

### MonthlySummary

Source : `app/src/app/core/models/transaction.model.ts`

| Champ          | Type   | Description                        |
| -------------- | ------ | ---------------------------------- |
| month          | number | Mois (1-12)                        |
| year           | number | Année                              |
| totalRecettes  | number | Somme des recettes du mois         |
| totalDepenses  | number | Somme des dépenses du mois         |
| solde          | number | totalRecettes - totalDepenses      |

### Transaction

Source : `app/src/app/core/models/transaction.model.ts`

| Champ    | Type               | Description                  |
| -------- | ------------------ | ---------------------------- |
| id       | string             | UUID                         |
| montant  | number             | Montant de la transaction    |
| libelle  | string             | Libellé                      |
| type     | TransactionType    | DEPENSE ou RECETTE           |
| date     | string             | Date ISO                     |
| category | Category or null   | Catégorie associée           |
| note     | string or null     | Note optionnelle             |

### Subscription

Source : `app/src/app/core/models/subscription.model.ts`

| Champ     | Type             | Description                    |
| --------- | ---------------- | ------------------------------ |
| id        | string           | UUID                           |
| nom       | string           | Nom de l'abonnement            |
| montant   | number           | Montant                        |
| frequence | Frequency        | MENSUEL ou ANNUEL              |
| dateDebut | string           | Date de début ISO              |
| actif     | boolean          | Statut actif/inactif           |
| category  | Category or null | Catégorie associée             |

### Debt

Source : `app/src/app/core/models/debt.model.ts`

| Champ      | Type             | Description                  |
| ---------- | ---------------- | ---------------------------- |
| id         | string           | UUID                         |
| personne   | string           | Personne concernée           |
| montant    | number           | Montant                      |
| sens       | DebtType         | JE_DOIS ou ON_ME_DOIT        |
| date       | string           | Date ISO                     |
| rembourse  | boolean          | Statut de remboursement      |
| category   | Category or null | Catégorie associée           |

## Relations

```
Dashboard (composant)
  ├── MonthlySummary ← TransactionService.getSummary(month, year)
  ├── Transaction[]  ← TransactionService.getAll() → slice(0, 5)
  ├── Subscription[] ← SubscriptionService.getAll(true) → slice(0, 3)
  └── Debt[]         ← DebtService.getAll(false) → slice(0, 3)
```

## Calculs dérivés dans le Dashboard

| Signal computed       | Source                       | Logique                                              |
| --------------------- | ---------------------------- | ---------------------------------------------------- |
| selectedMonthLabel    | selectedMonth, selectedYear  | Formatage FR "février 2026"                          |
| recentTransactions    | transactions                 | Tri date DESC, slice(0, 5)                           |
| activeSubscriptions   | subscriptions                | Tri nom ASC, slice(0, 3)                             |
| monthlySubTotal       | subscriptions                | Somme (annuel/12 + mensuel) des actifs               |
| activeDebts           | debts                        | Filtre non remboursé, tri date DESC, slice(0, 3)     |
| totalJeDois           | debts                        | Somme JE_DOIS non remboursés                         |
| totalOnMeDoit         | debts                        | Somme ON_ME_DOIT non remboursés                      |
