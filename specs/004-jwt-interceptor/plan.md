# Implementation Plan: Intercepteur HTTP JWT

**Branch**: `004-jwt-interceptor` | **Date**: 2026-02-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-jwt-interceptor/spec.md`

## Summary

Implémenter un intercepteur HTTP fonctionnel Angular (`HttpInterceptorFn`) qui injecte automatiquement le token JWT dans les requêtes API, exclut les routes publiques d'authentification, et gère les réponses 401 en déconnectant l'utilisateur et le redirigeant vers la page de login.

## Technical Context

**Language/Version**: TypeScript 5.8+ / Angular 21
**Primary Dependencies**: `@angular/common/http` (HttpInterceptorFn, HttpHandlerFn, HttpRequest, HttpErrorResponse), `@angular/router` (Router), `AuthService` (existant)
**Storage**: localStorage via AuthService (existant, pas de modification)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: Web PWA mobile-first
**Project Type**: Web application (monorepo api/ + app/)
**Performance Goals**: Injection du header sans latence perceptible (< 1ms overhead par requête)
**Constraints**: Pas de modification de l'AuthService existant. Intercepteur fonctionnel (pas class-based).
**Scale/Scope**: Single-user app, ~10 endpoints API

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | L'intercepteur est côté frontend uniquement, il ne modifie pas l'API. Il consomme le contrat JWT existant (header `Authorization: Bearer`). |
| II. Sécurité par défaut | PASS | Le token est envoyé uniquement vers l'API interne. Les routes publiques sont exclues. Les 401 déclenchent une déconnexion. Pas de token envoyé vers des domaines tiers. |
| III. Simplicité & YAGNI | PASS | Une seule fonction (`HttpInterceptorFn`), pas de classe, pas d'abstraction. Liste d'exclusion inline. |
| IV. Mobile-First UX | PASS | Pas d'impact direct sur l'UX mobile. L'intercepteur est transparent. |
| V. Testabilité | PASS | L'intercepteur fonctionnel est testable unitairement via injection de mocks (AuthService, Router). Pattern AAA. |
| VI. Observabilité | N/A | Pas de backend impliqué. Côté frontend, les erreurs sont loguées via `console.error` dans AuthService. |
| VII. Self-Hosted Ready | PASS | Pas de dépendance externe ajoutée. |

**Gate Result**: PASS - Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/004-jwt-interceptor/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (N/A - pas de modèle de données)
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── interceptors/
│   │   └── auth.interceptor.ts       # HttpInterceptorFn (NOUVEAU)
│   │   └── auth.interceptor.spec.ts  # Tests unitaires (NOUVEAU)
│   ├── guards/
│   │   └── auth.guard.ts             # Existant (pas de modification)
│   ├── services/
│   │   ├── auth.ts                   # Existant (pas de modification)
│   │   └── api.ts                    # Existant (pas de modification)
│   └── models/
│       ├── auth.model.ts             # Existant
│       └── user.model.ts             # Existant
├── app.config.ts                     # MODIFIÉ : ajout withInterceptors([authInterceptor])
└── app.routes.ts                     # Existant (pas de modification)
```

**Structure Decision**: L'intercepteur va dans `core/interceptors/` suivant la convention Angular du projet. Un seul fichier source + un fichier test. La seule modification existante est l'enregistrement dans `app.config.ts`.

## Complexity Tracking

Aucune violation de la constitution. Tableau non applicable.
