# Data Model: Écran Transactions (liste + filtres)

**Feature**: 012-transaction-list
**Date**: 2026-02-11

## Entités utilisées (existantes)

Aucune nouvelle entité. Cette feature consomme les modèles existants.

### Transaction (existant — `core/models/transaction.model.ts`)

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| id | string (UUID) | oui | Identifiant unique |
| montant | number | oui | Montant de la transaction |
| libelle | string | oui | Description courte |
| type | TransactionType | oui | DEPENSE ou RECETTE |
| date | string (ISO) | oui | Date de la transaction |
| category | Category \| null | non | Catégorie associée |
| note | string \| null | non | Note libre |

### Category (existant — `core/models/category.model.ts`)

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| id | string (UUID) | oui | Identifiant unique |
| nom | string | oui | Nom de la catégorie |
| icone | string | oui | Emoji de la catégorie |
| couleur | string | oui | Couleur hex |

### MonthlySummary (existant — `core/models/transaction.model.ts`)

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| month | number | oui | Mois (1-12) |
| year | number | oui | Année |
| totalRecettes | number | oui | Somme des recettes du mois |
| totalDepenses | number | oui | Somme des dépenses du mois |
| solde | number | oui | totalRecettes - totalDepenses |

## État local du composant (nouveau)

| Signal | Type | Défaut | Description |
|--------|------|--------|-------------|
| selectedMonth | number | Mois courant (1-12) | Mois sélectionné |
| selectedYear | number | Année courante | Année sélectionnée |
| typeFilter | 'ALL' \| 'DEPENSE' \| 'RECETTE' | 'ALL' | Filtre type actif |
| loading | boolean | true | Chargement en cours |
| error | boolean | false | Erreur de chargement |
| transactions | Transaction[] | [] | Transactions brutes (toutes) |
| summary | MonthlySummary \| null | null | Résumé mensuel |

## Données dérivées (computed)

| Signal | Type | Source | Description |
|--------|------|--------|-------------|
| selectedMonthLabel | string | selectedMonth + selectedYear | Label "Février 2026" |
| filteredTransactions | Transaction[] | transactions + selectedMonth + selectedYear + typeFilter | Transactions filtrées et triées par date desc |
