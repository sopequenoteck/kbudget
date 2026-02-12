# Implementation Plan: Réorganisation complète du Dashboard

**Branch**: `021-dashboard-redesign` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/021-dashboard-redesign/spec.md`

## Summary

Réorganiser le dashboard pour regrouper tous les KPI financiers en haut (2 rangées : budget mensuel + abos/dettes), supprimer les résumés texte dupliqués des sections, et afficher des listes pures en dessous. Ajouter un token sémantique pour la couleur abonnements (bleu). Mini-cards cliquables pour navigation rapide.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: Angular (Signals, standalone, OnPush), SCSS design tokens, Router
**Storage**: N/A (données via services REST existants — TransactionService, SubscriptionService, DebtService)
**Testing**: Vitest 4.x via `npx vitest run`
**Target Platform**: PWA mobile-first (375px+), desktop responsive
**Project Type**: Web (frontend uniquement — pas de modification backend)
**Performance Goals**: KPI zone visible sans scroll sur mobile 375px, pas de régression de chargement
**Constraints**: Pas de nouvelle dépendance, pas de modification backend, tokens existants du DS
**Scale/Scope**: 1 composant modifié (dashboard), 3 fichiers SCSS modifiés (tokens + themes)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Commentaire |
|----------|--------|-------------|
| I. API-First | N/A | Pas de modification backend |
| II. Sécurité par défaut | N/A | Pas de changement de sécurité |
| III. Simplicité & YAGNI | PASS | Modification d'un seul composant, pas d'abstraction prématurée. Mini-card en CSS pur dans le dashboard (pas de composant shared) |
| IV. Mobile-First UX | PASS | KPI visible sans scroll sur 375px. Navigation rapide via mini-cards cliquables |
| V. Testabilité | PASS | Computed signals testables unitairement (monthlySubTotal, totalJeDois, totalOnMeDoit existent déjà) |
| VI. Observabilité | N/A | Pas de changement backend/logging |
| VII. Self-Hosted Ready | N/A | Pas de nouvelle dépendance infra |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/021-dashboard-redesign/
├── spec.md              # Spécification
├── plan.md              # Ce fichier
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (N/A — pas de nouveau modèle)
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/
├── app/
│   └── features/
│       └── dashboard/
│           ├── dashboard.ts       # Composant TS (modifier)
│           ├── dashboard.html     # Template (modifier)
│           └── dashboard.scss     # Styles (modifier)
└── styles/
    ├── tokens/
    │   └── _primitives.scss       # Ajouter couleur abonnements (modifier)
    └── themes/
        ├── _light.scss            # Ajouter --color-subscription (modifier)
        └── _dark.scss             # Ajouter --color-subscription (modifier)
```

**Structure Decision**: Frontend uniquement. 3 fichiers du dashboard modifiés + 3 fichiers SCSS modifiés pour le token de couleur abonnements.

## Complexity Tracking

> Aucune violation de constitution — tableau non requis.
