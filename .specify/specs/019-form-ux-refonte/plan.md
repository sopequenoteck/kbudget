# Implementation Plan: Refonte UX formulaire Transaction

**Branch**: `019-form-ux-refonte` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/019-form-ux-refonte/spec.md`

## Summary

Refonte du formulaire de transaction pour une saisie rapide sur mobile. Le toggle Depense/Recette est deplace dans le header du modal via un slot de contenu projete. Les champs du formulaire passent d'un empilement vertical a un layout grille 2 colonnes (libelle+montant, categorie+date, note pleine largeur). La barre d'actions fusionne suppression et validation sur une seule ligne. Responsive : empilage en 1 colonne sous 400px.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/core` (signals, standalone, OnPush), `@angular/forms` (ReactiveFormsModule), `@angular/cdk` (a11y)
**Storage**: N/A (pas de changement de persistance)
**Testing**: Vitest 4.x via `npx vitest run`
**Target Platform**: PWA mobile-first (navigateurs modernes)
**Project Type**: Web application (monorepo `api/` + `app/`)
**Performance Goals**: Formulaire visible sans scroll sur 375px (iPhone SE)
**Constraints**: Breakpoint responsive a 400px, pas d'impact sur les autres formulaires
**Scale/Scope**: 3 composants modifies (Modal, Shell, TransactionForm), 0 nouveau fichier

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Pas de changement backend ni API |
| II. Securite par defaut | N/A | Pas de nouveau flux de donnees |
| III. Simplicite & YAGNI | PASS | Modification minimale de 3 composants existants, pas de nouvelle abstraction |
| IV. Mobile-First UX | PASS | Objectif principal : saisie en 2-3 interactions, layout grille compact |
| V. Testabilite | PASS | Scenarios acceptance definis, testables visuellement et fonctionnellement |
| VI. Observabilite | N/A | Pas de nouveau flux serveur |
| VII. Self-Hosted Ready | N/A | Changement frontend uniquement |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/019-form-ux-refonte/
├── spec.md              # Specification
├── plan.md              # This file
├── research.md          # Phase 0 output (minimal — no unknowns)
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── shared/components/
│   ├── modal/
│   │   ├── modal.html          # Ajouter slot ng-content[modal-header-actions]
│   │   └── modal.scss          # Adapter header layout (gap, margin-left auto)
│   └── shell/
│       ├── shell.ts            # Ajouter signal transactionType + handler
│       ├── shell.html          # Projeter toggle dans modal-header-actions
│       └── shell.scss          # Styles .type-toggle compact pour header
└── features/transactions/components/
    └── transaction-form/
        ├── transaction-form.ts     # input(type), retirer type du FormGroup
        ├── transaction-form.html   # Layout grille, actions fusionnees
        └── transaction-form.scss   # .form-row grid, retirer .type-toggle
```

**Structure Decision**: Web application existante. Modification de 3 composants dans le frontend Angular (`app/`). Aucun nouveau fichier, aucun changement backend.

## Complexity Tracking

> Aucune violation de la constitution — pas de tracking necessaire.
