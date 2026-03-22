# Implementation Plan: Frontend Refresh Token

**Branch**: `024-frontend-refresh-token` | **Date**: 2026-02-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/024-frontend-refresh-token/spec.md`

## Summary

Intégrer la gestion du refresh token côté frontend Angular : modifier le modèle `AuthResponse` pour inclure le `refreshToken`, adapter `AuthService` pour stocker/renouveler/révoquer les tokens, et réécrire l'intercepteur HTTP pour tenter un refresh automatique sur 401 avec sérialisation des requêtes concurrentes.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/common/http` (HttpInterceptorFn), `@angular/core` (signals, inject), RxJS (Observable, Subject, switchMap, catchError, shareReplay)
**Storage**: localStorage (clés `budget_token`, `budget_refresh_token`, `budget_user`)
**Testing**: Vitest 4.x + `@angular/core/testing` + `HttpTestingController`
**Target Platform**: PWA mobile-first (navigateurs modernes)
**Project Type**: Web application (monorepo `api/` + `app/`)
**Performance Goals**: Refresh transparent < 2s, pas de requête de refresh concurrente
**Constraints**: Single-user self-hosted, localStorage acceptable pour v1
**Scale/Scope**: 1 utilisateur, ~5 fichiers modifiés/créés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Le backend expose déjà `/auth/refresh` et `/auth/logout`. Le frontend consomme ces endpoints via DTOs typés |
| II. Sécurité par défaut | PASS | Refresh token révoqué au logout, rotation supportée (FR-007), pas de boucle infinie (FR-008) |
| III. Simplicité & YAGNI | PASS | Modification de 3 fichiers existants + mise à jour du modèle. Pas de nouvelle abstraction — utilisation de RxJS Subject pour la sérialisation |
| IV. Mobile-First UX | PASS | Refresh transparent = aucune interruption pour l'utilisateur mobile |
| V. Testabilité | PASS | Tests unitaires existants à mettre à jour (AuthService, intercepteur). Pattern AAA conservé |
| VI. Observabilité | PASS | Logging `isDevMode()` sur les événements refresh (tentative, succès, échec) — pattern existant dans AuthService |
| VII. Self-Hosted Ready | PASS | Pas de dépendance externe ajoutée. localStorage uniquement |

## Project Structure

### Documentation (this feature)

```text
specs/024-frontend-refresh-token/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── auth-refresh.md  # Contrats des endpoints refresh/logout
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
app/src/app/core/
├── models/
│   └── auth.model.ts          # MODIFIER — ajouter refreshToken à AuthResponse
├── services/
│   ├── auth.ts                # MODIFIER — stockage refresh token, méthodes refresh/logout API
│   └── auth.spec.ts           # MODIFIER — nouveaux tests refresh/logout
└── interceptors/
    ├── auth.interceptor.ts    # MODIFIER — logique refresh sur 401, sérialisation
    └── auth.interceptor.spec.ts # MODIFIER — nouveaux tests refresh interceptor
```

**Structure Decision**: Aucun nouveau fichier source — modification des 4 fichiers existants dans `core/`. Le modèle, le service et l'intercepteur sont déjà en place, il suffit de les enrichir.

## Complexity Tracking

| Point soulevé | Justification | Alternative rejetée |
|---------------|---------------|---------------------|
| `BehaviorSubject<boolean>` dans l'intercepteur vs convention signals-first | L'intercepteur HTTP (`HttpInterceptorFn`) opère dans le pipeline RxJS — sa signature impose `Observable<HttpEvent>`. Le `BehaviorSubject` coordonne des flux HTTP concurrents, ce qui est explicitement autorisé par la convention « RxJS limité aux flux HTTP et opérateurs complexes ». Il ne remplace pas un state de composant. | Signals : impossible — `Signal` est synchrone, ne peut pas coordonner des Observables HTTP. `firstValueFrom` : ne gère pas la sérialisation de N requêtes concurrentes. |
