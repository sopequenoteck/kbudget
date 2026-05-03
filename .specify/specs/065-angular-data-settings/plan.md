# Implementation Plan: Gestion donnees Angular (Data Settings)

**Branch**: `065-angular-data-settings` | **Date**: 2026-03-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/065-angular-data-settings/spec.md`

## Summary

Remplacer le placeholder `/settings/data` par un vrai composant `DataSettings` affichant les informations de connexion serveur (URL, statut en ligne/hors ligne), un bouton de test de connectivite manuel (ping `/actuator/health` avec mesure du temps de reponse), et une action de rechargement complet des donnees (confirmation + `window.location.reload()`). Feature Angular-only, aucune modification backend requise.

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21
**Primary Dependencies**: Angular HttpClient, Angular Router, Angular Signals
**Storage**: N/A (pas de persistance locale, lecture seule depuis le serveur)
**Testing**: Vitest (via `ng test`), composant + service
**Target Platform**: PWA web, mobile-first
**Project Type**: Frontend PWA (module Settings)
**Performance Goals**: Test de connectivite < 10s timeout, affichage statut < 3s au chargement
**Constraints**: Server-only (pas de mode local), URL API relative (`/api` via environment)
**Scale/Scope**: 1 composant, 1 service, 1 route (remplacement placeholder existant)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | OK | Utilise l'endpoint existant `/actuator/health` (public). Aucun nouveau endpoint backend requis. |
| II. Securite par defaut | OK | L'ecran est protege par `authGuard` (route Settings). Le health check cible un endpoint public Spring Actuator. |
| III. Simplicite & YAGNI | OK | 1 service + 1 composant. Pas d'abstraction complexe. Rechargement via `window.location.reload()` plutot que d'exposer des methodes `reload()` sur chaque service existant. |
| IV. Mobile-First UX | OK | Layout settings standard, responsive, memes patterns que les autres ecrans. |
| V. Testabilite | OK | Service testable unitairement (mock HttpClient). Composant testable via injection du service. |
| VI. Observabilite | N/A | Frontend uniquement, pas de logging backend supplementaire. |
| VII. Self-Hosted Ready | OK | Aucune dependance externe ajoutee. Health check cible le meme serveur. |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/065-angular-data-settings/
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
│   └── services/
│       └── health.ts                    # NOUVEAU — HealthService (ping + mesure latence)
└── features/
    └── settings/
        ├── settings.ts                  # MODIFIE — data.status: 'active', description mise a jour
        ├── settings.routes.ts           # MODIFIE — route data → DataSettings composant
        └── components/
            └── data-settings/
                ├── data-settings.ts     # NOUVEAU — composant DataSettings
                ├── data-settings.html   # NOUVEAU — template
                └── data-settings.scss   # NOUVEAU — styles
```

**Structure Decision**: Feature Angular-only. Ajout d'un service dans `core/services/` (pattern existant : `ApiService`, `ThemeService`, `AuthService`). Composant dans `features/settings/components/` (pattern existant : `appearance/`, `profile/`, `features/`). Pas de sous-dossier `contracts/` car aucun nouveau endpoint API.

## Design Decisions

### D1. URL du serveur affichee

L'URL API est relative (`/api` dans `environment.ts`). L'URL complete du serveur sera construite au runtime via `window.location.origin`. Affichage : `https://budget.kksdev.fr/api` (en prod) ou `http://localhost:4200/api` (en dev).

### D2. Health check via `/actuator/health`

Appel `GET` sur `{origin}/api/../actuator/health` (soit `{origin}/actuator/health`). Cet endpoint est declare public dans Spring Security (`/actuator/health`). Le `authInterceptor` Angular ajoutera le JWT mais ce n'est pas bloquant (l'endpoint l'ignore). Timeout : 10 secondes. Mesure de la latence via `Date.now()` avant/apres l'appel.

**Note** : L'appel se fait via `HttpClient` directement (pas via `ApiService` qui prefixe `/api`), car l'endpoint Actuator est hors du context path `/api`.

### D3. Rechargement des donnees

Approche choisie : `window.location.reload()` apres confirmation utilisateur. C'est la solution la plus simple et fiable car :
- Les services Angular utilisent `refreshTrigger = signal(0)` avec `refresh()` prive — pas d'API publique pour forcer un re-fetch
- Un reload complet remet tous les signaux a zero et re-declenche tous les fetches
- Pas de modification des services existants (YAGNI)
- UX acceptable pour une action rare de maintenance

Alternative rejetee : exposer une methode `reload()` publique sur chaque service (Transaction, Account, Category, Subscription, Debt, User, Preference, Currency) — trop invasif pour un gain marginal.

### D4. Indicateur de statut

Deux etats visuels :
- **En ligne** : badge vert + texte "En ligne" + temps de reponse (ex: "120 ms")
- **Hors ligne** : badge rouge + texte "Hors ligne" + message d'erreur contextuel

Messages d'erreur selon le type de failure :
- Timeout (10s) : "Delai de reponse depasse"
- Erreur reseau : "Serveur injoignable"
- Erreur HTTP 5xx : "Erreur serveur"
- Autre : "Erreur inconnue"

## Complexity Tracking

> Aucune violation de la constitution — pas de justification requise.
