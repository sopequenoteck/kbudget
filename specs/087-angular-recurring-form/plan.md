# Implementation Plan: Formulaire de création et conversion de transactions récurrentes (Angular)

**Branch**: `087-angular-recurring-form` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/087-angular-recurring-form/spec.md`

## Summary

Enrichir le formulaire de transaction Angular (`TransactionForm`) avec un toggle "Récurrente" qui affiche conditionnellement les champs fréquence et prochaine occurrence. Ajouter `RecurringTransactionRequest` et `create()` au service existant. Ajouter une action "Rendre récurrente" dans la liste des transactions qui ouvre le formulaire pré-rempli en mode récurrent.

## Technical Context

**Language/Version**: TypeScript 5.9
**Primary Dependencies**: Angular 21, Angular Reactive Forms, Angular Signals, @ng-icons/phosphor-icons
**Storage**: N/A (server-only, consomme API REST POST /transactions/recurring)
**Testing**: Vitest
**Target Platform**: PWA mobile-first (navigateur)
**Project Type**: Web application (frontend Angular)
**Performance Goals**: N/A (opération CRUD standard)
**Constraints**: Mobile-first UX, création en ≤4 interactions
**Scale/Scope**: Single-user, 2 fichiers modèle/service modifiés, 1 formulaire enrichi, 1 liste enrichie

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Backend POST /transactions/recurring déjà implémenté (KKS-085). Frontend consomme l'API existante. |
| II. Sécurité par défaut | PASS | Requêtes protégées par JWT via ApiService existant. Pas de nouvelle route publique. |
| III. Simplicité & YAGNI | PASS | Enrichissement minimal du formulaire existant. Pas de nouveau composant, pas d'abstraction. |
| IV. Mobile-First UX | PASS | Création en ≤4 interactions. Toggle simple, champs conditionnels. |
| V. Testabilité | PASS | Tests unitaires Vitest pour les scénarios de création/conversion. |
| VI. Observabilité | N/A | Frontend uniquement, logging côté backend déjà en place. |
| VII. Self-Hosted Ready | N/A | Pas de nouvelle dépendance infra. |

## Project Structure

### Documentation (this feature)

```text
specs/087-angular-recurring-form/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── api-endpoints.md
└── tasks.md
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── models/
│   │   └── recurring-transaction.model.ts    # + RecurringTransactionRequest
│   └── services/
│       └── recurring-transaction.ts          # + create()
├── features/
│   └── transactions/
│       ├── transactions.ts                   # + action "Rendre récurrente"
│       ├── transactions.html                 # + bouton/menu conversion
│       └── components/
│           └── transaction-form/
│               ├── transaction-form.ts       # + toggle récurrence + logique submit
│               ├── transaction-form.html     # + UI toggle + champs conditionnels
│               └── transaction-form.scss     # + styles toggle + champs conditionnels
└── (tests inline via *.spec.ts)
```

**Structure Decision**: Enrichissement de fichiers existants uniquement. Aucun nouveau fichier source à créer (modification de 7 fichiers existants).
