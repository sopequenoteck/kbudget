# Implementation Plan: Feature Toggles Angular

**Branch**: `064-angular-feature-toggles` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/064-angular-feature-toggles/spec.md`
**Linear**: KKS-150

## Summary

Implémenter la gestion des feature toggles dans l'app Angular PWA en parité avec Flutter. Un `PreferenceService` signal-based communique avec l'API existante `GET/PUT /users/me/preferences`. L'écran Settings > Fonctionnalités permet d'activer/désactiver les 3 modules optionnels (Abonnements, Dettes, Boutique) et de réordonner la navigation. La sidebar et le FAB réagissent dynamiquement aux changements via `computed()`. Un guard fonctionnel protège les routes de modules désactivés.

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21
**Primary Dependencies**: Angular CDK (`@angular/cdk/drag-drop` pour le DnD), Angular Signals, Angular Router
**Storage**: Server-only (API REST `GET/PUT /users/me/preferences`) — pas de stockage local
**Testing**: Vitest (via `ng test`)
**Target Platform**: Web PWA mobile-first
**Project Type**: Frontend SPA (module d'une web application)
**Performance Goals**: Toggle reflété dans la sidebar en < 1 seconde (optimistic update)
**Constraints**: Server-only, signals-first, standalone components, OnPush change detection
**Scale/Scope**: Single-user, 3 features, 1 écran settings, modifications shell + FAB + router

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | L'API `GET/PUT /users/me/preferences` existe déjà (KKS-120). Le frontend consomme cette API. |
| II. Sécurité par défaut | PASS | Routes protégées par `authGuard` existant + nouveau `featureGuard`. API sécurisée par JWT. |
| III. Simplicité & YAGNI | PASS | Signal-based service simple (pas de store/NgRx). Guard fonctionnel paramétré. Pas d'abstraction superflue. |
| IV. Mobile-First UX | PASS | FAB conditionné par features activées. Settings accessibles en 1 tap. Toggle instantané (optimistic). |
| V. Testabilité | PASS | Service testable via mock d'ApiService. Guard testable. Composant testable avec DI. |
| VI. Observabilité | N/A | Feature frontend pure — pas de logging serveur ajouté. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée. |

**Gate result**: PASS — aucune violation.

### Post-Phase 1 re-check

| Principe | Statut | Notes |
|----------|--------|-------|
| III. Simplicité & YAGNI | PASS | Le `Feature` est un simple objet constant (pas une classe), le `PreferenceService` suit le pattern existant (signal + refreshTrigger + `firstValueFrom`). CDK DragDrop déjà installé. |
| IV. Mobile-First UX | PASS | Sidebar dynamique, FAB filtré, toggle instantané, confirmation avant suppression. |

## Project Structure

### Documentation (this feature)

```text
specs/064-angular-feature-toggles/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: research findings
├── data-model.md        # Phase 1: data model
├── quickstart.md        # Phase 1: quickstart guide
├── contracts/
│   └── preferences-api.md  # API contract reference
├── checklists/
│   └── requirements.md     # Spec quality checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── models/
│   │   └── preference.model.ts        # NEW: Feature enum + UserPreference interfaces
│   ├── services/
│   │   ├── preference.ts              # NEW: PreferenceService (API + signals)
│   │   └── preference.spec.ts         # NEW: Tests PreferenceService
│   └── guards/
│       ├── auth.guard.ts              # EXISTING (unchanged)
│       ├── feature.guard.ts           # NEW: featureGuard (CanActivateFn)
│       └── feature.guard.spec.ts      # NEW: Tests featureGuard
├── shared/components/
│   ├── shell/
│   │   ├── shell.ts                   # MODIFIED: inject PreferenceService, computed nav items
│   │   └── shell.html                 # MODIFIED: dynamic sidebar links
│   └── fab/
│       └── fab.ts                     # MODIFIED: filter actions by enabled features
├── features/
│   ├── settings/
│   │   ├── settings.ts                # MODIFIED: add "Fonctionnalités" section
│   │   ├── settings.routes.ts         # MODIFIED: add route "features"
│   │   └── components/features/
│   │       ├── features.ts            # NEW: feature toggles component
│   │       ├── features.html          # NEW: template (toggles + DnD nav order)
│   │       └── features.scss          # NEW: styles
│   └── shop/
│       └── shop-placeholder.ts        # NEW: "Coming soon" placeholder
└── app.routes.ts                      # MODIFIED: add /shop route with featureGuard
```

**Structure Decision**: Feature frontend-only dans le module Angular existant (`app/`). Fichiers ajoutés dans les répertoires existants (`core/models/`, `core/services/`, `core/guards/`, `features/settings/components/`, `features/shop/`). Aucun nouveau module ou librairie.

## Design Decisions

### D1 — Feature comme constantes (pas un TypeScript enum)

Le `Feature` Angular est défini comme un objet `const` avec des propriétés typées, **pas** un `enum` TypeScript. Chaque feature est une constante string (`'SUBSCRIPTIONS'`, `'DEBTS'`, `'SHOP'`) correspondant exactement aux valeurs du backend Java `Feature.java`. Un tableau `FEATURES` contient les métadonnées (label, icon emoji, description, route).

**Rationale**: Les enums TypeScript génèrent du code runtime inutile. Un `type Feature = 'SUBSCRIPTIONS' | 'DEBTS' | 'SHOP'` est plus léger et suffit pour le typage. Le tableau `FEATURES` permet l'itération et l'accès aux métadonnées. Les icônes sont des emojis (🔄, 🤝, 🏪) cohérents avec le reste de l'app (sidebar, FAB, settings).

### D2 — PreferenceService : chargement au login

Le `PreferenceService` expose une méthode `loadPreferences()` appelée après le succès de `authService.restoreSession()` ou `authService.login()`. L'état par défaut avant chargement : `enabledFeatures = []`, ce qui fait que la sidebar n'affiche que Accueil + Transactions.

**Rationale**: Server-only implique que l'état n'existe pas avant l'appel API. Le Shell utilise un `computed()` qui inclut les modules optionnels seulement quand `enabledFeatures` est non-vide. Pas de flash de contenu incorrect.

### D3 — featureGuard paramétré via route data

Le `featureGuard` lit `route.data['feature']` pour savoir quelle feature vérifier. Cela permet de paramétrer le guard par route sans créer un guard par feature.

```typescript
{ path: 'subscriptions', canActivate: [featureGuard], data: { feature: 'SUBSCRIPTIONS' }, ... }
```

### D4 — Mise à jour optimiste sans rollback

Comme Flutter, l'état signal est mis à jour immédiatement. L'appel API est fire-and-forget. En cas d'erreur, un message est affiché mais l'état local n'est pas rollbacké. Au prochain login, l'état sera resynchronisé depuis le serveur.

### D5 — navOrder envoyé uniquement lors du réordonnancement

Pour le toggle simple (activer/désactiver), le PUT envoie `enabledFeatures` sans `navOrder` — le backend auto-gère l'ordre. Pour le réordonnancement explicite (DnD), le PUT envoie les deux champs. Cela simplifie le code et réduit les risques d'erreur de validation côté backend.

## File Inventory

### Files to Create (9)

| File | Purpose | LOC est. |
|------|---------|----------|
| `app/src/app/core/models/preference.model.ts` | Feature type + FEATURES metadata (emojis) + UserPreference/Request interfaces | ~60 |
| `app/src/app/core/services/preference.ts` | PreferenceService (API calls, signals, toggle/reorder logic — pattern similaire à ThemeService) | ~100 |
| `app/src/app/core/guards/feature.guard.ts` | featureGuard (CanActivateFn) | ~15 |
| `app/src/app/features/settings/components/features/features.ts` | Feature toggles component (toggles + DnD) | ~120 |
| `app/src/app/features/settings/components/features/features.html` | Template | ~80 |
| `app/src/app/features/settings/components/features/features.scss` | Styles | ~60 |
| `app/src/app/features/shop/shop-placeholder.ts` | Placeholder "Coming soon" (inline template) | ~30 |
| `app/src/app/core/services/preference.spec.ts` | Tests unitaires PreferenceService | ~80 |
| `app/src/app/core/guards/feature.guard.spec.ts` | Tests unitaires featureGuard | ~50 |

### Files to Modify (6)

| File | Change | Impact |
|------|--------|--------|
| `app/src/app/app.routes.ts` | Ajouter routes `/shop` et guards `featureGuard` sur `/subscriptions`, `/debts`, `/shop` | Low |
| `app/src/app/features/settings/settings.routes.ts` | Ajouter route `features` | Low |
| `app/src/app/features/settings/settings.ts` | Ajouter section "Fonctionnalités" dans `SECTIONS[]` | Low |
| `app/src/app/shared/components/shell/shell.ts` | Injecter `PreferenceService`, `computed()` pour nav items dynamiques | Medium |
| `app/src/app/shared/components/shell/shell.html` | Remplacer liens sidebar hardcodés par `@for` sur `navItems()` | Medium |
| `app/src/app/shared/components/fab/fab.ts` | Filtrer `actions` computed par features activées | Low |

## Complexity Tracking

> Aucune violation de constitution détectée — tableau vide.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
