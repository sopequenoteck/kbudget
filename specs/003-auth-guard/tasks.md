# Tasks: Guard d'authentification

**Input**: Design documents from `/specs/003-auth-guard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus — la constitution (Principe V: Testabilité) exige des tests unitaires.

**Organization**: Les user stories US1, US2, US3 (toutes P1) et US5 (P2) sont couvertes par le même guard fonctionnel. US4 (redirection post-login) concerne le composant login (KKS-28, hors scope). Les phases reflètent la séquence de build naturelle.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend**: `app/src/app/` (Angular PWA)

---

## Phase 1: Setup

**Purpose**: Création de la structure de fichiers pour le guard

- [ ] T001 Créer le répertoire `app/src/app/core/guards/`

---

## Phase 2: User Stories 1+2+5 — Guard fonctionnel (Priority: P1+P2) 🎯 MVP

**Goal**: Implémenter le guard qui vérifie l'authentification, autorise les utilisateurs authentifiés et redirige les non-authentifiés avec conservation du returnUrl

**Independent Test**: Appeler la fonction guard avec un AuthService mocké (authentifié/non-authentifié) et vérifier le retour (true ou UrlTree de redirection)

**Rationale du regroupement**: US1 (refus accès), US2 (autorisation accès) et US5 (session expirée) sont les deux faces de la même fonction : `isAuthenticated() ? true : redirect`. Ils ne peuvent pas être implémentés séparément.

### Implementation

- [ ] T002 [US1] Implémenter la fonction `authGuard` (CanActivateFn) dans `app/src/app/core/guards/auth.guard.ts` :
  - Injecter `AuthService` et `Router` via `inject()`
  - Si `authService.isAuthenticated()` est `true` → retourner `true` (couvre US2)
  - Si `false` → créer un `UrlTree` vers `/auth` avec queryParam `returnUrl` = `state.url` (couvre US1, US5)
  - Valider que `state.url` commence par `/` et ne commence pas par `//`, `http:` ou `https:` avant de l'utiliser comme returnUrl (FR-007, sécurité open redirect)

### Tests

- [ ] T003 [US1] Écrire les tests unitaires dans `app/src/app/core/guards/auth.guard.spec.ts` :
  - `should_allow_access_when_authenticated` : mock `isAuthenticated` = true → retourne `true`
  - `should_redirect_to_auth_when_not_authenticated` : mock `isAuthenticated` = false → retourne UrlTree `/auth`
  - `should_include_returnUrl_when_redirecting` : vérifie que le queryParam `returnUrl` contient l'URL demandée
  - `should_reject_external_returnUrl` : `state.url` = `https://evil.com` → returnUrl ignoré ou non inclus
  - `should_redirect_when_token_expired` : AuthService avec token expiré (isAuthenticated = false) → redirection (couvre US5)

**Checkpoint**: Le guard fonctionne en isolation. Les tests passent.

---

## Phase 3: User Story 3 — Routes protégées et publiques (Priority: P1)

**Goal**: Appliquer le guard sur les routes protégées tout en laissant les routes publiques (`/auth`) accessibles sans authentification

**Independent Test**: Vérifier dans la configuration de routing que `canActivate: [authGuard]` est présent sur dashboard, transactions, subscriptions, debts et wildcard, mais absent sur auth

### Implementation

- [ ] T004 [US3] Modifier `app/src/app/app.routes.ts` :
  - Importer `authGuard` depuis `./core/guards/auth.guard`
  - Ajouter `canActivate: [authGuard]` sur les routes : `dashboard`, `transactions`, `subscriptions`, `debts`
  - Ajouter `canActivate: [authGuard]` sur la route wildcard (`**`)
  - NE PAS ajouter le guard sur la route `auth` (FR-004)
  - NE PAS ajouter le guard sur la route redirect (`''` → `dashboard`) car le redirect vers dashboard déclenchera le guard

**Checkpoint**: Le routing est configuré. Navigation vers une route protégée sans token redirige vers `/auth?returnUrl=...`. La route `/auth` reste accessible.

---

## Phase 4: Polish & Validation

**Purpose**: Vérification finale et validation croisée

- [ ] T005 Exécuter les tests avec `cd app && npx vitest run` et vérifier que tous passent
- [ ] T006 Vérifier que ESLint passe avec `cd app && npx ng lint`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — peut démarrer immédiatement
- **Guard + Tests (Phase 2)**: Dépend de Phase 1 (répertoire créé)
- **Routes (Phase 3)**: Dépend de Phase 2 (guard implémenté et exporté)
- **Validation (Phase 4)**: Dépend de Phase 2 + Phase 3

### User Story Dependencies

- **US1+US2+US5 (Phase 2)**: Dépend de Setup uniquement. AuthService existe déjà (KKS-25).
- **US3 (Phase 3)**: Dépend de Phase 2 (le guard doit être exporté pour être importé dans les routes)
- **US4 (hors scope)**: Sera implémenté dans KKS-28 (écran de login) — le guard pose le `returnUrl`, le login le lit

### Within Each Phase

- T002 (guard) et T003 (tests) sont dans la même phase mais séquentiels : écrire le guard d'abord, puis les tests
- T004 dépend de T002 (import du guard)
- T005-T006 dépendent de tout le reste

### Parallel Opportunities

- T002 et T004 touchent des fichiers différents mais T004 importe T002 → séquentiel
- T005 et T006 peuvent être lancés en parallèle (vitest et eslint sont indépendants)

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2)

1. Créer le répertoire guards/
2. Implémenter le guard avec validation du returnUrl
3. Écrire et faire passer les tests
4. **STOP and VALIDATE**: Le guard fonctionne en isolation

### Incremental Delivery

1. Phase 1 + Phase 2 → Guard fonctionnel testé (MVP)
2. Phase 3 → Guard appliqué aux routes → Feature complète
3. Phase 4 → Validation finale → Prêt à merger

---

## Notes

- Scope minimal : 2 fichiers créés (`auth.guard.ts`, `auth.guard.spec.ts`), 1 fichier modifié (`app.routes.ts`)
- Aucune nouvelle dépendance npm
- US4 (returnUrl post-login) est hors scope — sera dans KKS-28
- Le guard retourne un `UrlTree` (pas `router.navigate()`) — c'est le pattern recommandé Angular pour les guards
- Commit après chaque phase
