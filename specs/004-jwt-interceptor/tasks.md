# Tasks: Intercepteur HTTP JWT

**Input**: Design documents from `/specs/004-jwt-interceptor/`
**Prerequisites**: plan.md (required), spec.md (required), research.md

**Tests**: Tests unitaires inclus — le plan (research.md R6) prévoit des tests avec HttpTestingController.

**Organization**: Tasks groupées par user story pour permettre une implémentation et des tests indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend**: `app/src/app/` (Angular 21, monorepo)

---

## Phase 1: Setup

**Purpose**: Création du répertoire et du squelette de l'intercepteur

- [ ] T001 Créer le répertoire `app/src/app/core/interceptors/` et le fichier squelette `app/src/app/core/interceptors/auth.interceptor.ts` avec une `HttpInterceptorFn` qui passe la requête sans modification (pass-through)
- [ ] T002 Enregistrer l'intercepteur dans `app/src/app/app.config.ts` : remplacer `provideHttpClient()` par `provideHttpClient(withInterceptors([authInterceptor]))` avec les imports nécessaires

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Configuration des tests pour l'intercepteur — DOIT être complétée avant l'implémentation des user stories

**CRITICAL**: Les tests servent de filet de sécurité pour toute l'implémentation qui suit

- [ ] T003 Créer le fichier de test `app/src/app/core/interceptors/auth.interceptor.spec.ts` avec la configuration TestBed (init `getTestBed().initTestEnvironment()` dans le fichier), provision de `provideHttpClient(withInterceptors([authInterceptor]))`, `provideHttpClientTesting`, mock de `AuthService` (getToken, logout) et mock de `Router` (navigate). Vérifier qu'un test de base passe (requête pass-through)

**Checkpoint**: La base de test est fonctionnelle — `cd app && npx vitest run` passe

---

## Phase 3: User Story 1 - Requêtes authentifiées automatiques (Priority: P1) MVP

**Goal**: L'intercepteur injecte automatiquement le header `Authorization: Bearer <token>` sur toutes les requêtes API quand un token est disponible

**Independent Test**: Effectuer une requête vers un endpoint protégé après connexion et vérifier que le header d'autorisation est présent dans la requête sortante

### Tests for User Story 1

- [ ] T004 [US1] Écrire les tests dans `app/src/app/core/interceptors/auth.interceptor.spec.ts` : (1) should_add_auth_header_when_token_exists — mock getToken retourne un token, vérifier que la requête sortante a le header `Authorization: Bearer <token>` ; (2) should_send_request_without_header_when_no_token — mock getToken retourne null, vérifier absence du header ; (3) should_add_same_header_to_concurrent_requests — deux requêtes simultanées, vérifier que les deux ont le header

### Implementation for User Story 1

- [ ] T005 [US1] Implémenter l'injection du token dans `app/src/app/core/interceptors/auth.interceptor.ts` : utiliser `inject(AuthService)` pour récupérer le token via `getToken()`, cloner la requête avec `req.clone({ setHeaders: { Authorization: 'Bearer ' + token } })` si le token existe, sinon passer la requête sans modification
- [ ] T006 [US1] Vérifier que les tests T004 passent — `cd app && npx vitest run`

**Checkpoint**: L'injection automatique du token fonctionne. MVP fonctionnel.

---

## Phase 4: User Story 2 - Exclusion des routes publiques (Priority: P2)

**Goal**: Les requêtes vers `/auth/login` et `/auth/register` ne reçoivent jamais le header d'autorisation, même si un token existe

**Independent Test**: Déclencher une requête de connexion et vérifier l'absence du header d'autorisation

### Tests for User Story 2

- [ ] T007 [US2] Écrire les tests dans `app/src/app/core/interceptors/auth.interceptor.spec.ts` : (1) should_not_add_header_when_url_is_login — requête vers `/api/auth/login`, token présent, vérifier absence du header ; (2) should_not_add_header_when_url_is_register — requête vers `/api/auth/register`, token présent, vérifier absence du header ; (3) should_add_header_when_url_is_other_api_route — requête vers `/api/transactions`, token présent, vérifier présence du header ; (4) should_not_add_header_when_url_is_absolute_external — requête vers `https://external.com/api`, token présent, vérifier absence du header

### Implementation for User Story 2

- [ ] T008 [US2] Ajouter la logique d'exclusion dans `app/src/app/core/interceptors/auth.interceptor.ts` : définir une liste de chemins publics (`/auth/login`, `/auth/register`), vérifier si l'URL contient un de ces chemins avant d'injecter le token. Ajouter la vérification que l'URL n'est pas absolue vers un domaine externe (commence par `http://` ou `https://`)
- [ ] T009 [US2] Vérifier que les tests T007 passent — `cd app && npx vitest run`

**Checkpoint**: L'exclusion des routes publiques et la protection contre les domaines tiers fonctionnent

---

## Phase 5: User Story 3 - Déconnexion automatique sur session expirée (Priority: P3)

**Goal**: Sur réponse 401 du serveur, l'utilisateur est automatiquement déconnecté et redirigé vers la page de connexion, sans redirections en cascade

**Independent Test**: Simuler une réponse 401 du serveur et vérifier que le token est supprimé et l'utilisateur redirigé vers `/auth`

### Tests for User Story 3

- [ ] T010 [US3] Écrire les tests dans `app/src/app/core/interceptors/auth.interceptor.spec.ts` : (1) should_call_logout_when_401_received — simuler une réponse 401, vérifier que `AuthService.logout()` est appelé ; (2) should_not_call_logout_when_403_received — simuler une réponse 403, vérifier que `logout()` n'est PAS appelé et que l'erreur est propagée ; (3) should_call_logout_only_once_on_multiple_401 — simuler deux réponses 401 simultanées, vérifier que `logout()` n'est appelé qu'une seule fois ; (4) should_propagate_error_after_logout — simuler une 401, vérifier que l'erreur est toujours propagée au subscriber après le logout

### Implementation for User Story 3

- [ ] T011 [US3] Ajouter la gestion des erreurs 401 dans `app/src/app/core/interceptors/auth.interceptor.ts` : utiliser `pipe(catchError(...))` sur le `next(req)`, vérifier si l'erreur est une `HttpErrorResponse` avec status 401, appeler `AuthService.logout()` via le flag anti-cascade, puis re-throw l'erreur
- [ ] T012 [US3] Implémenter le flag anti-cascade dans `app/src/app/core/interceptors/auth.interceptor.ts` : variable booléen au niveau du module qui empêche les appels multiples à `logout()`, réinitialisé après un délai court (setTimeout)
- [ ] T013 [US3] Vérifier que les tests T010 passent — `cd app && npx vitest run`

**Checkpoint**: La gestion des 401 est complète. Toutes les user stories sont implémentées.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale, lint, et vérification de non-régression

- [ ] T014 Exécuter le lint complet — `cd app && npx ng lint` — corriger toute erreur
- [ ] T015 Exécuter tous les tests du projet — `cd app && npx vitest run` — vérifier que les tests existants (auth.spec.ts, auth.guard.spec.ts) passent toujours
- [ ] T016 Vérifier le build — `cd app && npx ng build` — aucune erreur de compilation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — commence immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 — BLOQUE toutes les user stories
- **User Story 1 (Phase 3)**: Dépend de Phase 2
- **User Story 2 (Phase 4)**: Dépend de Phase 3 (étend la logique d'injection)
- **User Story 3 (Phase 5)**: Dépend de Phase 3 (étend le pipe du handler)
- **Polish (Phase 6)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Indépendante — base de l'intercepteur
- **US2 (P2)**: Étend US1 en ajoutant les conditions d'exclusion avant l'injection
- **US3 (P3)**: Étend US1 en ajoutant le `catchError` après le `next(req)`

> Note : US2 et US3 modifient le même fichier (`auth.interceptor.ts`) mais à des emplacements différents (avant vs après l'appel `next`). Elles ne sont PAS parallélisables car elles dépendent du squelette créé en US1.

### Within Each User Story

- Tests DOIVENT être écrits et ÉCHOUER avant l'implémentation
- Implémentation → vérification des tests → checkpoint

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 : Setup (T001-T002)
2. Phase 2 : Foundational (T003)
3. Phase 3 : User Story 1 (T004-T006)
4. **STOP et VALIDER** : le header Authorization est injecté automatiquement
5. Commit intermédiaire possible

### Incremental Delivery

1. Setup + Foundational → squelette fonctionnel
2. US1 : Injection du token → MVP fonctionnel
3. US2 : Exclusion des routes publiques → sécurité renforcée
4. US3 : Gestion des 401 → UX complète
5. Polish : lint, build, non-régression

---

## Notes

- Tous les fichiers modifiés sont dans un seul fichier source (`auth.interceptor.ts`) + un fichier test (`auth.interceptor.spec.ts`) + une modification mineure (`app.config.ts`)
- Les user stories s'empilent séquentiellement car elles étendent la même fonction intercepteur
- Chaque story ajoute une couche de logique sans casser les précédentes
- Le nommage des tests suit la convention : `should_[résultat]_when_[condition]`
- Init TestBed directement dans le `.spec.ts` (pas de setupFiles — voir MEMORY.md)
