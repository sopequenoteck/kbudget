# Implementation Plan: Service d'authentification frontend

**Branch**: `feature/002-auth-service` | **Date**: 2026-02-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-auth-service/spec.md`

## Summary

Implémenter un AuthService Angular signals-first qui gère l'authentification JWT (login, register, logout, détection d'expiration). Le service consomme les endpoints backend existants (POST `/api/auth/login` et `/api/auth/register`), stocke le token en localStorage, et expose un état réactif via signals pour l'ensemble de l'application.

## Technical Context

**Language/Version**: TypeScript 5.8+ (Angular 21)
**Primary Dependencies**: Angular 21 (HttpClient, Router, Signals), RxJS (HTTP uniquement)
**Storage**: localStorage (clés `budget_token` et `budget_user`)
**Testing**: Karma/Jasmine (Angular CLI default, hors scope contraintes constitution — celles-ci ciblent le backend Java)
**Target Platform**: Web PWA (mobile-first, navigateurs modernes)
**Project Type**: Web application (monorepo `api/` + `app/`)
**Performance Goals**: État auth mis à jour de manière synchrone (même tick, cf. SC-001)
**Constraints**: Pas de librairie externe pour décoder le JWT (utiliser `atob`), signals-first (pas de BehaviorSubject)
**Scale/Scope**: Single-user, 1 service + 2 interfaces + 2 modèles

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Le service consomme les endpoints REST existants. Les DTOs TypeScript reflètent les contrats backend. Aucune logique métier côté frontend. |
| II. Sécurité par défaut | PASS | Token JWT stocké côté client, jamais de mot de passe persisté. Les credentials transitent uniquement en POST body HTTPS. Token expiré détecté et nettoyé. |
| III. Simplicité & YAGNI | PASS | Un seul service, pas de pattern complexe. Signals natifs Angular, pas d'abstraction supplémentaire (pas de store NgRx, pas de facade). |
| IV. Mobile-First UX | PASS | Le service est agnostique UI — il sera consommé par les composants mobile-first (KKS-28 login screen). |
| V. Testabilité | PASS | Service injectable et testable unitairement. ApiService mockable. Token storage mockable via injection. |
| VI. Observabilité | PASS | Feature frontend — la constitution cible SLF4J/Logback (Java). Équivalent frontend : `console.error` sur token corrompu, échec localStorage, erreur réseau inattendue. Les erreurs métier sont propagées aux composants UI. Pas de `console.log` de debug en production. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance SaaS. JWT géré localement. URLs relatives via environment.apiUrl. |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/002-auth-service/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── auth-api.md      # Contrats API auth (endpoints consommés)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── services/
│   │   ├── api.ts              # ApiService existant (générique HTTP)
│   │   └── auth.ts             # AuthService (à créer)
│   ├── models/
│   │   ├── auth.model.ts       # Interfaces LoginRequest, RegisterRequest, AuthResponse
│   │   └── user.model.ts       # Interface UserInfo (nom, email)
│   ├── guards/                 # (vide — KKS-27)
│   └── interceptors/           # (vide — KKS-26)
```

**Structure Decision**: Feature frontend uniquement dans `app/src/app/core/`. Le service est un singleton (`providedIn: 'root'`) dans `core/services/`. Les modèles/interfaces dans `core/models/`. Pas de modification backend.

## Complexity Tracking

> Aucune violation — tableau non applicable.
