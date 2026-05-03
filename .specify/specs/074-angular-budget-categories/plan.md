# Implementation Plan: Budgets par catégorie — Angular

**Branch**: `074-angular-budget-categories` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/074-angular-budget-categories/spec.md`

## Summary

Implémenter le module Angular des budgets par catégorie : service signal-based consommant les 7 endpoints REST existants (KKS-073), section dashboard avec barres de progression, écran dédié avec sélecteur de mois et Doughnut Chart (ng2-charts/Chart.js), formulaire en modale (Reactive Forms), vue détaillée, et intégration navigation (sidebar + bottom nav + feature guard).

## Technical Context

**Language/Version**: TypeScript 5.9
**Primary Dependencies**: Angular 21, Angular Reactive Forms, ng2-charts (Chart.js), @ng-icons/phosphor-icons
**Storage**: N/A (server-only, pas de stockage local)
**Testing**: Vitest (existant dans le projet Angular)
**Target Platform**: Web PWA (mobile-first, desktop responsive)
**Project Type**: Frontend module dans monorepo existant
**Performance Goals**: Dashboard section < 2s, navigation mois < 1s
**Constraints**: Signals-first, OnPush, standalone components, inject() only
**Scale/Scope**: ~10 fichiers nouveaux, 1 dépendance ajoutée (ng2-charts)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Consomme les 7 endpoints REST existants (KKS-073). Pas de logique métier côté frontend. |
| II. Sécurité par défaut | PASS | JWT via intercepteur HTTP existant. Pas d'accès cross-user (filtrage backend). |
| III. Simplicité & YAGNI | PASS | Pattern identique aux modules existants (shop, transactions). Pas d'abstraction nouvelle. |
| IV. Mobile-First UX | PASS | Barres de progression tactiles, modale formulaire (2-3 interactions), responsive 320px+. |
| V. Testabilité | PASS | Tests unitaires service + composants avec mocks. |
| VI. Observabilité | N/A | Frontend uniquement — logging côté backend déjà en place. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance SaaS. Chart.js est une lib JS locale. |

## Project Structure

### Documentation (this feature)

```text
specs/074-angular-budget-categories/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── models/
│   │   ├── preference.model.ts    # MODIFIER — ajouter 'BUDGETS' au type Feature + FEATURES array
│   │   └── budget.model.ts        # NOUVEAU — interfaces Budget, BudgetOverview, BudgetHistory
│   └── services/
│       └── budget.ts              # NOUVEAU — BudgetService signal-based (CRUD + overview + history)
├── features/
│   ├── dashboard/
│   │   ├── dashboard.ts           # MODIFIER — ajouter section budgets (overview)
│   │   └── components/
│   │       └── budget-summary/
│   │           └── budget-summary.ts  # NOUVEAU — section dashboard (barres de progression, état vide)
│   └── budgets/
│       ├── budgets.routes.ts      # NOUVEAU — routes lazy-loaded (/budgets, /budgets/details)
│       ├── budget-list/
│       │   └── budget-list.ts     # NOUVEAU — écran principal (liste, sélecteur mois, Doughnut mini)
│       ├── budget-detail/
│       │   └── budget-detail.ts   # NOUVEAU — vue détaillée (Doughnut agrandi + liste)
│       └── components/
│           └── budget-form/
│               └── budget-form.ts # NOUVEAU — formulaire modale (Reactive Forms)
├── shared/
│   └── components/
│       └── shell/
│           └── shell.ts           # MODIFIER — ajouter case 'budget' dans le switch modal
└── app.routes.ts                  # MODIFIER — ajouter route /budgets avec featureGuard
```

**Structure Decision**: Module feature `budgets/` dans `features/`, identique au pattern `shop/`. Service dans `core/services/`. Modèles dans `core/models/`.

## Complexity Tracking

> Aucune violation de la constitution. Pas de déviation nécessaire.
