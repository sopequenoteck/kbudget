# Implementation Plan: Guard d'authentification

**Branch**: `003-auth-guard` | **Date**: 2026-02-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-auth-guard/spec.md`

## Summary

Implémenter un guard d'authentification fonctionnel (`CanActivateFn`) pour protéger toutes les routes nécessitant une session active. Le guard vérifie l'état d'authentification via `AuthService.isAuthenticated()`, redirige vers `/auth` avec un `returnUrl` si non authentifié, et valide que le `returnUrl` est une route interne.

## Technical Context

**Language/Version**: TypeScript 5.8+ / Angular 21
**Primary Dependencies**: `@angular/router` (Router, CanActivateFn, ActivatedRouteSnapshot, RouterStateSnapshot), `AuthService` (existant)
**Storage**: localStorage via AuthService (existant, pas de modification)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: PWA mobile-first (navigateurs modernes)
**Project Type**: web (frontend uniquement pour cette feature)
**Performance Goals**: Redirection instantanée (< 50ms), aucun appel réseau
**Constraints**: Pas de dépendance externe supplémentaire, réutiliser AuthService existant
**Scale/Scope**: 1 guard fonctionnel, modification du routing principal, tests unitaires

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature frontend-only, aucun endpoint API modifié |
| II. Sécurité par défaut | PASS | Le guard complète la protection JWT backend en empêchant la navigation frontend vers des routes protégées sans token valide |
| III. Simplicité & YAGNI | PASS | Guard fonctionnel simple (`CanActivateFn`), pas de classe abstraite ni de pattern complexe |
| IV. Mobile-First UX | PASS | Redirection transparente avec conservation du `returnUrl` pour UX fluide |
| V. Testabilité | PASS | Guard testable unitairement via mock d'AuthService et Router |
| VI. Observabilité | N/A | Pas de logging côté frontend pour le guard (AuthService log déjà les erreurs de token) |
| VII. Self-Hosted Ready | N/A | Aucune dépendance externe ajoutée |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/003-auth-guard/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   └── guards/
│       ├── auth.guard.ts          # Guard fonctionnel (CanActivateFn)
│       └── auth.guard.spec.ts     # Tests unitaires du guard
├── app.routes.ts                  # Modification: ajout canActivate sur routes protégées
└── features/
    └── auth/
        └── auth.routes.ts         # Inchangé (route publique)
```

**Structure Decision**: Le guard est placé dans `core/guards/` conformément à la structure existante (`core/services/`, `core/models/`). Seuls 2 fichiers sont créés et 1 fichier modifié.

## Complexity Tracking

Aucune violation des principes — tableau non requis.
