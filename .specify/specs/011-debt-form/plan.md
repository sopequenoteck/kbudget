# Implementation Plan: Formulaire Debt (modal)

**Branch**: `011-debt-form` | **Date**: 2026-02-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/011-debt-form/spec.md`
**Linear**: KKS-53

## Summary

Composant formulaire Angular standalone pour creer et editer une dette, affiche dans la modal du Shell. Utilise `ReactiveFormsModule` avec le pattern signals-first existant, le composant `FormField` pour les champs, et emet des evenements `saved`/`cancelled` sans appeler directement le backend. Integre un toggle segmente pour le sens EMPRUNT/PRET (valeurs enum JE_DOIS/ON_ME_DOIT) et une case a cocher pour le statut rembourse.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/forms` (ReactiveFormsModule), `@angular/core` (signals, input, output, inject), composants existants (`FormField`, `Shell`, `Modal`)
**Storage**: N/A (composant presentationnel — pas de persistance directe)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: PWA mobile-first (Chrome, Safari iOS, Firefox)
**Project Type**: Web application (monorepo api/ + app/)
**Performance Goals**: Affichage instantane du formulaire, pas de chargement visible en mode edition
**Constraints**: Mobile-first (360px min), design tokens SCSS uniquement, OnPush, standalone
**Scale/Scope**: Single-user, 1 composant + 1 integration shell + styles

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Notes |
|----------|--------|-------|
| I. API-First | PASS | Le formulaire emet `DebtRequest` (DTO existant). Pas d'entite JPA exposee. |
| II. Securite par defaut | PASS | Pas de manipulation de secrets. Les donnees transitent par les services existants (JWT gere par interceptor). |
| III. Simplicite & YAGNI | PASS | Un seul composant, pas d'abstraction. Reutilise `FormField` existant. Pattern identique a Transaction/Subscription forms. |
| IV. Mobile-First UX | PASS | Toggle segmente, date native, checkbox, responsive 360px+. Saisie rapide en 2-3 interactions. |
| V. Testabilite | PASS | Composant presentationnel testable via inputs/outputs. Pattern AAA. |
| VI. Observabilite | N/A | Composant frontend sans logging serveur. |
| VII. Self-Hosted Ready | PASS | Pas de dependance externe ajoutee. |

## Project Structure

### Documentation (this feature)

```text
specs/011-debt-form/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A — pas de nouveau endpoint)
├── checklists/          # Quality checklists
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── features/
│   └── debts/
│       └── components/
│           └── debt-form/
│               ├── debt-form.ts       # Composant (a creer)
│               ├── debt-form.html     # Template (a creer)
│               └── debt-form.scss     # Styles (a creer)
├── shared/
│   └── components/
│       └── shell/
│           ├── shell.ts              # Import + integration (a modifier)
│           └── shell.html            # Remplacement placeholder (a modifier)
└── core/
    ├── models/
    │   └── debt.model.ts             # Debt, DebtRequest, DebtType (existant)
    └── services/
        └── debt.ts                   # DebtService (existant)
```

**Structure Decision**: Feature frontend uniquement. 3 fichiers a creer dans `features/debts/components/debt-form/`, 2 fichiers existants a modifier dans `shared/components/shell/`. Aucun nouveau service, modele ou endpoint backend.
