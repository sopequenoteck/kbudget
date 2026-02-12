# Implementation Plan: Ecran Debts (liste + filtres)

**Branch**: `014-debt-list` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/014-debt-list/spec.md`

## Summary

Implementer l'ecran principal des dettes avec liste, double filtrage (statut via API + sens cote client), resume financier (total je dois / on me doit / solde net) et gestion des etats (loading, error, empty). Feature purement frontend utilisant les composants et services existants.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/core` (signals, standalone, OnPush), `@angular/common` (NgClass), composants existants (`ListItem`, `AmountPipe`, `RelativeDatePipe`)
**Storage**: N/A (donnees via DebtService existant, API REST backend)
**Testing**: Vitest 4.x via `npx vitest run`
**Target Platform**: PWA mobile-first (navigateurs modernes)
**Project Type**: web (monorepo api/ + app/)
**Performance Goals**: Chargement de la liste en moins de 2 secondes
**Constraints**: Mobile-first, design tokens existants, patterns Angular signals-first
**Scale/Scope**: Single-user, volume de dettes faible (dizaines)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Notes |
|----------|--------|-------|
| I. API-First | PASS | L'API REST des dettes existe deja (GET `/debts`, `?rembourse=true/false`). Pas de nouvel endpoint requis. |
| II. Securite par defaut | PASS | Les requetes HTTP passent par le JwtInterceptor existant. Filtrage par user authentifie cote backend. |
| III. Simplicite & YAGNI | PASS | Modification de 3 fichiers existants uniquement (debts.ts/html/scss). Pas de nouveau composant ni abstraction. |
| IV. Mobile-First UX | PASS | Layout flexbox column, design tokens responsive, resume visible sans defilement. |
| V. Testabilite | PASS | Composant testable via Vitest avec mocks du DebtService. |
| VI. Observabilite | PASS | Erreurs loggees en mode dev via `isDevMode()` (pattern existant). |
| VII. Self-Hosted Ready | PASS | Pas de dependance externe ajoutee. |

## Project Structure

### Documentation (this feature)

```text
specs/014-debt-list/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── spec.md              # Feature specification
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
app/src/app/
├── features/
│   └── debts/
│       ├── debts.ts           # MODIFIER — composant principal (signals, filtres, resume)
│       ├── debts.html         # MODIFIER — template (filtres, resume, liste, etats)
│       ├── debts.scss         # MODIFIER — styles (filtres, resume, liste, etats)
│       ├── debts.routes.ts    # EXISTANT — pas de modification
│       └── components/
│           └── debt-form/     # EXISTANT — pas de modification
├── core/
│   ├── services/
│   │   └── debt.ts            # EXISTANT — DebtService avec getAll(rembourse?)
│   └── models/
│       └── debt.model.ts      # EXISTANT — Debt, DebtRequest, DebtType
└── shared/
    ├── components/
    │   └── list-item/         # EXISTANT — ListItem (icon, title, subtitle, value, rightSubtitle, valueClass)
    └── pipes/
        ├── amount.pipe.ts     # EXISTANT — AmountPipe (supporte JE_DOIS/ON_ME_DOIT)
        └── relative-date.pipe.ts  # EXISTANT — RelativeDatePipe
```

**Structure Decision**: Feature purement frontend. Seuls 3 fichiers du composant `Debts` sont modifies (`debts.ts`, `debts.html`, `debts.scss`). Aucun nouveau fichier a creer. Suit le pattern identique aux ecrans `Transactions` (KKS-54) et `Subscriptions` (KKS-55).

## Complexity Tracking

Aucune violation de constitution. Pas de deviation necessaire.

## Design Decisions

### Pattern de reference : Subscriptions (KKS-55)

L'ecran des dettes suit le meme pattern que l'ecran des abonnements car :
- Filtre statut via API (identique a `actif?: boolean` → `rembourse?: boolean`)
- `firstValueFrom()` pour les appels async
- `effect()` pour reagir aux changements de filtre et au `refreshTrigger`
- Etats loading/error/empty identiques

### Differences avec Subscriptions

1. **Double filtre** : statut (API) + sens (client) au lieu d'un seul filtre
2. **Resume a 3 cartes** : total je dois / total on me doit / solde net (vs 1 carte "total mensuel")
3. **Couleurs semantiques** : `--color-debt-owe` (rouge) et `--color-debt-owed` (vert) au lieu de couleurs income/expense
4. **Icones par sens** : icone differente selon JE_DOIS vs ON_ME_DOIT

### Signals et computed

```
signals:
  - statusFilter: signal<'ALL' | 'EN_COURS' | 'REMBOURSE'>('ALL')
  - sensFilter: signal<'ALL' | 'JE_DOIS' | 'ON_ME_DOIT'>('ALL')
  - loading: signal<boolean>(true)
  - error: signal<boolean>(false)
  - debts: signal<Debt[]>([])

computed:
  - filteredDebts: computed() — filtre par sens cote client + tri par date desc
  - totalJeDois: computed() — somme des montants JE_DOIS des dettes filtrees
  - totalOnMeDoit: computed() — somme des montants ON_ME_DOIT des dettes filtrees
  - netBalance: computed() — totalOnMeDoit - totalJeDois
  - hasDebts: computed() — debts().length > 0
```

### Template structure

```
[Section filtre statut — 3 boutons toggle]
[Section filtre sens — 3 boutons toggle]
[Section resume — 3 cartes si hasDebts()]
[Section liste / etats — loading | error | empty | liste]
```

### Mapping ListItem

| ListItem input | Valeur |
|----------------|--------|
| icon | Emoji selon sens : `💸` (je dois) / `💰` (on me doit) |
| title | `debt.personne` |
| subtitle | Badge "Rembourse" si `debt.rembourse === true`, sinon vide |
| value | `debt.montant \| amount: debt.sens` |
| rightSubtitle | `debt.date \| relativeDate` |
| valueClass | `'debt-owe'` ou `'debt-owed'` selon sens |

### Classes CSS pour valueClass

Les classes `amount-income` et `amount-expense` existent dans `_utilities.scss`. Pour les dettes, on utilisera les memes tokens de couleur via des classes dediees dans le composant SCSS (`debt-owe` → `color: var(--color-debt-owe)` et `debt-owed` → `color: var(--color-debt-owed)`).
