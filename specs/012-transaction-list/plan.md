# Implementation Plan: Écran Transactions (liste + filtres)

**Branch**: `012-transaction-list` | **Date**: 2026-02-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/012-transaction-list/spec.md`

## Summary

Implémenter l'écran principal des transactions : liste filtrable par mois/année et type (dépense/recette), résumé mensuel (recettes, dépenses, solde), et gestion des états loading/empty/error. Composant frontend uniquement — l'API et les services existent déjà.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/core` (signals, standalone, OnPush), `@angular/common` (NgClass), RxJS (HTTP uniquement)
**Storage**: N/A (composant présentationnel — données via TransactionService existant)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: PWA mobile-first (navigateur)
**Project Type**: web (monorepo `app/`)
**Performance Goals**: Chargement initial < 2s, filtrage type < 100ms (côté client)
**Constraints**: Pas de pagination (single-user, volume limité), filtrage mois/année côté client (API ne supporte pas le filtre date)
**Scale/Scope**: 1 écran, 3 fichiers à modifier, 0 nouveau composant partagé

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | API transactions + summary déjà exposée. Pas de nouveau endpoint. |
| II. Sécurité par défaut | PASS | Routes protégées par authGuard existant. Données filtrées par user côté API. |
| III. Simplicité & YAGNI | PASS | Modification de 3 fichiers existants. Pas de nouveau service ni composant partagé. Signals locaux pour les filtres. |
| IV. Mobile-First UX | PASS | Layout optimisé mobile. Flèches prev/next tactiles. Toggle buttons pour le filtre type. |
| V. Testabilité | PASS | Composant testable via TestBed. États loading/empty/error couverts par les acceptance scenarios. |
| VI. Observabilité | N/A | Composant frontend présentationnel — pas de logging requis. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance SaaS. |

## Project Structure

### Documentation (this feature)

```text
specs/012-transaction-list/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── features/
│   └── transactions/
│       ├── transactions.ts          # Composant principal (à implémenter)
│       ├── transactions.html        # Template (à implémenter)
│       └── transactions.scss        # Styles (à implémenter)
└── shared/
    ├── components/
    │   └── list-item/               # Réutilisé (existant)
    └── pipes/
        ├── amount.pipe.ts           # Réutilisé (existant)
        └── relative-date.pipe.ts    # Réutilisé (existant)
```

**Structure Decision**: Feature frontend uniquement. Les 3 fichiers stub existants dans `features/transactions/` sont modifiés. Aucun nouveau fichier source créé. Les composants partagés (ListItem, AmountPipe, RelativeDatePipe) sont importés tels quels.

## Complexity Tracking

> Aucune violation de la constitution. Pas de tracking nécessaire.

## Design

### Component Architecture

Le composant `Transactions` gère l'état local avec des signals :

**Signals d'état** :
- `selectedMonth: signal<number>` — mois sélectionné (1-12), défaut : mois courant
- `selectedYear: signal<number>` — année sélectionnée, défaut : année courante
- `typeFilter: signal<'ALL' | 'DEPENSE' | 'RECETTE'>` — filtre type actif, défaut : 'ALL'
- `loading: signal<boolean>` — état de chargement
- `error: signal<boolean>` — état d'erreur
- `transactions: signal<Transaction[]>` — toutes les transactions (brutes depuis l'API)
- `summary: signal<MonthlySummary | null>` — résumé mensuel depuis l'API

**Signals dérivés (computed)** :
- `selectedMonthLabel: computed<string>` — ex: "Février 2026" (Intl.DateTimeFormat)
- `filteredTransactions: computed<Transaction[]>` — filtre par mois/année + type, trié par date desc

**Data flow** :
1. À l'init et à chaque changement de mois/année → appel `getAll()` + `getSummary(month, year)`
2. Le filtrage par mois se fait côté client sur le résultat de `getAll()`
3. Le filtrage par type se fait sur `filteredTransactions` (computed, instantané)
4. Le résumé provient de `getSummary()` (calculé côté serveur)

### Template Structure

```
┌─────────────────────────────────┐
│  ◀  Février 2026  ▶            │  ← Month selector (prev/next)
├─────────────────────────────────┤
│  Recettes    Dépenses    Solde  │  ← Summary cards (3 montants)
│  +2 500 €   -1 800 €    700 €  │
├─────────────────────────────────┤
│  [Tous] [Dépenses] [Recettes]  │  ← Type filter toggle
├─────────────────────────────────┤
│  🛒 Courses                    │
│  Alimentation      -45,20 €    │  ← ListItem (icon, title,
│                    Aujourd'hui  │     subtitle, value, rightSubtitle)
│─────────────────────────────────│
│  💰 Salaire                    │
│  Revenus          +2 500,00 €  │
│                         Hier   │
│─────────────────────────────────│
│  ...                           │
└─────────────────────────────────┘
```

### ListItem Mapping

| ListItem input | Source Transaction |
|----------------|-------------------|
| `icon` | `transaction.category?.icone ?? '📝'` (icône par défaut si pas de catégorie) |
| `title` | `transaction.libelle` |
| `subtitle` | `transaction.category?.nom ?? ''` |
| `value` | `transaction.montant \| amount: transaction.type` |
| `rightSubtitle` | `transaction.date \| relativeDate` |
| `valueClass` | `transaction.type === 'RECETTE' ? 'amount-income' : 'amount-expense'` |

### Month Selector Behavior

- Bouton gauche `◀` : décrémenter le mois (passer à décembre N-1 si janvier)
- Bouton droit `▶` : incrémenter le mois (passer à janvier N+1 si décembre)
- Label central : `Intl.DateTimeFormat('fr-FR', { month: 'long', year: 'numeric' })`

### Error/Loading/Empty States

- **Loading** : spinner CSS centré + texte "Chargement..."
- **Error** : message "Erreur de chargement" + bouton "Réessayer" → relance `loadData()`
- **Empty** : icône + message "Aucune transaction" centré

### Refresh on CRUD

Le `TransactionService.refreshTrigger` est un signal qui s'incrémente après chaque create/update/delete. Le composant `Transactions` doit écouter ce signal via `effect()` pour recharger les données automatiquement après une opération CRUD (effectuée via le modal dans Shell).
