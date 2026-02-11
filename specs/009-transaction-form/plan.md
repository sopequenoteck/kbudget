# Implementation Plan: Formulaire Transaction (modal)

**Branch**: `009-transaction-form` | **Date**: 2026-02-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-transaction-form/spec.md`
**Linear**: KKS-51

## Summary

Composant formulaire Angular standalone pour créer et éditer une transaction, affiché dans la modal du Shell. Utilise `ReactiveFormsModule` avec le pattern signals-first existant, le composant `FormField` pour les champs, et émet des événements `saved`/`cancelled` sans appeler directement le backend. Intègre un toggle segmenté pour le type DEPENSE/RECETTE et un sélecteur de catégories via `CategoryService`.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/forms` (ReactiveFormsModule), `@angular/core` (signals, input, output, inject), composants existants (`FormField`, `Shell`, `Modal`)
**Storage**: N/A (composant présentationnel — pas de persistance directe)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: PWA mobile-first (Chrome, Safari iOS, Firefox)
**Project Type**: Web application (monorepo api/ + app/)
**Performance Goals**: Affichage instantané du formulaire, pas de chargement visible en mode édition
**Constraints**: Mobile-first (360px min), design tokens SCSS uniquement, OnPush, standalone
**Scale/Scope**: Single-user, 1 composant + 1 intégration shell + styles

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Notes |
|----------|--------|-------|
| I. API-First | PASS | Le formulaire émet `TransactionRequest` (DTO existant). Pas d'entité JPA exposée. |
| II. Sécurité par défaut | PASS | Pas de manipulation de secrets. Les données transitent par les services existants (JWT géré par interceptor). |
| III. Simplicité & YAGNI | PASS | Un seul composant, pas d'abstraction. Réutilise `FormField` existant. |
| IV. Mobile-First UX | PASS | Toggle segmenté, date native, responsive 360px+. Saisie rapide en 2-3 interactions. |
| V. Testabilité | PASS | Composant présentationnel testable via inputs/outputs. Pattern AAA. |
| VI. Observabilité | N/A | Composant frontend sans logging serveur. |
| VII. Self-Hosted Ready | PASS | Pas de dépendance externe ajoutée. |

## Project Structure

### Documentation (this feature)

```text
specs/009-transaction-form/
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
│   └── transactions/
│       └── components/
│           └── transaction-form/
│               ├── transaction-form.ts       # Composant (à créer)
│               ├── transaction-form.html     # Template (à créer)
│               └── transaction-form.scss     # Styles (à créer)
├── shared/
│   └── components/
│       └── shell/
│           ├── shell.ts                      # Import + intégration (à modifier)
│           └── shell.html                    # Remplacement placeholder (à modifier)
└── core/
    ├── models/
    │   ├── transaction.model.ts              # TransactionRequest (existant)
    │   └── category.model.ts                 # Category (existant)
    └── services/
        ├── transaction.ts                    # TransactionService (existant)
        └── category.ts                       # CategoryService (existant)
```

**Structure Decision**: Feature frontend uniquement. 3 fichiers à créer dans `features/transactions/components/transaction-form/`, 2 fichiers existants à modifier dans `shared/components/shell/`. Aucun nouveau service, modèle ou endpoint backend.
