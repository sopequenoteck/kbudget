# Implementation Plan: Écran Subscriptions (liste + filtre actif)

**Branch**: `013-subscription-list` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-subscription-list/spec.md`

## Summary

Implémenter l'écran de liste des abonnements (Subscriptions) avec filtre actif/inactif, résumé du total mensuel, et gestion des états (loading, error, empty). Feature purement frontend — le backend (API REST + SubscriptionService Angular) existe déjà. Suit le pattern exact de l'écran Transactions (KKS-54).

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/core` (signals, standalone, OnPush), `@angular/common` (NgClass), RxJS (HTTP uniquement)
**Storage**: N/A (données via SubscriptionService existant, API REST backend)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: PWA mobile-first (navigateurs modernes)
**Project Type**: Web application (monorepo api/ + app/)
**Performance Goals**: Affichage liste < 2 secondes après navigation
**Constraints**: Signals-first, OnPush, pas de subscribe() manuel, pas de nouvelle dépendance
**Scale/Scope**: Single-user, volume faible (~50 abonnements max)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | API REST Subscriptions existe déjà (GET /subscriptions?actif=). Pas de nouvel endpoint requis. |
| II. Sécurité par défaut | PASS | JWT déjà en place, SubscriptionService utilise HttpClient avec JwtInterceptor. Filtrage par user côté backend. |
| III. Simplicité & YAGNI | PASS | Réutilise les composants existants (ListItem, AmountPipe, RelativeDatePipe). Pas de nouvelle abstraction. |
| IV. Mobile-First UX | PASS | Écran liste mobile-first, bouton FAB déjà câblé dans Shell. |
| V. Testabilité | PASS | Composant testable via Vitest, logique dans computed signals. |
| VI. Observabilité | PASS | Erreurs loggées via isDevMode() pattern existant. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée. |

## Project Structure

### Documentation (this feature)

```text
specs/013-subscription-list/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A - API exists)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── features/
│   └── subscriptions/
│       ├── subscriptions.ts         # Composant principal (à implémenter)
│       ├── subscriptions.html       # Template (à implémenter)
│       ├── subscriptions.scss       # Styles (à implémenter)
│       └── subscriptions.routes.ts  # Routes (existe déjà)
├── core/
│   ├── services/
│   │   └── subscription.ts          # Service CRUD (existe déjà)
│   └── models/
│       └── subscription.model.ts    # Interfaces (existe déjà)
└── shared/
    ├── components/
    │   └── list-item/               # Composant réutilisable (existe déjà)
    └── pipes/
        ├── amount.pipe.ts           # Pipe formatage montant (existe déjà)
        └── relative-date.pipe.ts    # Pipe date relative (existe déjà)
```

**Structure Decision**: Feature purement frontend. 3 fichiers à modifier dans `features/subscriptions/` (composant, template, styles) + 1 fichier de test à créer (`subscriptions.spec.ts`). Tous les composants partagés et services existent.
