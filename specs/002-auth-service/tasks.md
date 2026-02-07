# Tasks: Service d'authentification frontend

**Input**: Design documents from `/specs/002-auth-service/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/auth-api.md

**Tests**: Phase 7 dédiée aux tests unitaires du AuthService (T009-T013), conformément au principe V de la constitution.

**Organization**: Tasks groupées par user story pour une implémentation et un test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts depuis la racine du repo

---

## Phase 1: Setup

**Purpose**: Création de la structure de dossiers pour les nouveaux fichiers

- [x] T001 Créer le dossier models/ dans `app/src/app/core/models/`

---

## Phase 2: Foundational (Modèles + Squelette AuthService)

**Purpose**: Interfaces TypeScript et infrastructure du service partagées par TOUTES les user stories

**CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase

- [x] T002 [P] Créer les interfaces auth dans `app/src/app/core/models/auth.model.ts` — LoginRequest (`email: string`, `password: string`), RegisterRequest (`name?: string`, `email: string`, `password: string`), AuthResponse (`token: string`, `email: string`, `name: string`). AuthResponse est utilisé par `saveAuth()` pour stocker `{name, email}` dans `budget_user` (FR-003). Cf. data-model.md et contracts/auth-api.md pour les champs exacts.
- [x] T003 [P] Créer l'interface UserInfo dans `app/src/app/core/models/user.model.ts` — UserInfo (`name: string`, `email: string`). Représente l'utilisateur connecté côté frontend.
- [x] T004 Créer le squelette AuthService dans `app/src/app/core/services/auth.ts` — Service injectable (`providedIn: 'root'`), inject ApiService et Router. Déclarer : `currentUser = signal<UserInfo | null>(null)` (FR-010), `isAuthenticated = computed(() => this.currentUser() !== null)`. Constantes : `STORAGE_TOKEN_KEY = 'budget_token'`, `STORAGE_USER_KEY = 'budget_user'`. Méthodes privées : `decodeToken(token)` (base64url → JSON via atob, try/catch, cf. research.md R1 — si décodage échoue, logger `console.error('Token corrompu')` et retourner null), `isTokenExpired(token)` (compare exp avec Date.now()/1000 — si `exp` absent du payload, considérer le token comme expiré) (FR-006), `saveAuth(response: AuthResponse)` (stocke token dans `'budget_token'` et user au format JSON dans `'budget_user'` en localStorage, met à jour signal), `clearAuth()` (supprime localStorage, reset signal à null), `mapAuthError(error): string` (HTTP 400 → `error.error.message`, status 0 → "Impossible de contacter le serveur", 500+ → "Une erreur est survenue" — factorise le mapping d'erreur partagé entre login/register). Constructeur : lire token + user depuis localStorage (clés `'budget_token'` et `'budget_user'`), vérifier expiration, restaurer le signal si valide ou nettoyer si expiré/corrompu (cf. research.md R5, R6). Si `JSON.parse(localStorage['budget_user'])` échoue (JSON corrompu), nettoyer les deux clés (`'budget_token'` et `'budget_user'`) et rester déconnecté — loguer `console.error('budget_user corrompu')`. Méthode publique `getToken(): string | null` (lit le token, vérifie expiration, retourne null si expiré). Entourer tous les accès localStorage (getItem/setItem/removeItem) d'un try/catch — si localStorage échoue (navigation privée ou QuotaExceededError), loguer `console.error('localStorage indisponible')` et continuer en mode session volatile (les signals sont mis à jour normalement mais sans persistance, session perdue au rechargement). Cf. spec.md Edge Cases.

**Checkpoint**: Modèles et squelette AuthService prêts — les user stories peuvent commencer

---

## Phase 3: User Story 1 — Connexion utilisateur (Priority: P1) MVP

**Goal**: L'utilisateur peut se connecter avec email/mot de passe. Le token est stocké et l'état d'authentification passe à "connecté".

**Independent Test**: Appeler `authService.login({email, password})` avec des identifiants valides → vérifier que `localStorage['budget_token']` contient un JWT et que `authService.isAuthenticated()` retourne `true`.

### Implementation

- [x] T005 [US1] Implémenter la méthode `login(credentials: LoginRequest)` dans `app/src/app/core/services/auth.ts` — Appeler `this.apiService.post<AuthResponse>('/auth/login', credentials)`, sur succès appeler `saveAuth(response)`. Sur erreur : utiliser la méthode privée `mapAuthError(error)` pour mapper les erreurs (HTTP 400 → `error.error.message`, status 0 → "Impossible de contacter le serveur" + `console.error`, 500+ → "Une erreur est survenue"). Note : le GlobalExceptionHandler backend retourne toujours `{timestamp, status, message}` — le chemin d'accès est toujours `error.error.message`. Retourner un Observable qui émet l'AuthResponse ou propage l'erreur mappée via `catchError` + `throwError`. Cf. contracts/auth-api.md et FR-008 pour le mapping complet.

**Checkpoint**: La connexion fonctionne de bout en bout. MVP livrable.

---

## Phase 4: User Story 2 — Inscription utilisateur (Priority: P2)

**Goal**: Un nouvel utilisateur peut créer un compte et est automatiquement connecté après inscription.

**Independent Test**: Appeler `authService.register({name, email, password})` avec des données valides → vérifier que le token est stocké et `isAuthenticated()` retourne `true`.

### Implementation

- [x] T006 [US2] Implémenter la méthode `register(data: RegisterRequest)` dans `app/src/app/core/services/auth.ts` — Appeler `this.apiService.post<AuthResponse>('/auth/register', data)`, sur succès appeler `saveAuth(response)`. Même stratégie de mapping via `mapAuthError(error)` (méthode privée partagée avec T005). Messages spécifiques register : "Email déjà utilisé", Bean Validation concaténé "field: message; field: message". Même pattern Observable que login(). Note : le backend retourne 201 Created (pas 200) — Angular HttpClient traite tous les 2xx comme succès, donc aucun traitement spécial nécessaire. Cf. contracts/auth-api.md pour les formats de réponse 400.

**Checkpoint**: L'inscription fonctionne. L'utilisateur est auto-connecté après inscription.

---

## Phase 5: User Story 3 — Déconnexion (Priority: P3)

**Goal**: L'utilisateur connecté peut se déconnecter. Le token est supprimé et il est redirigé vers `/auth`.

**Independent Test**: Se connecter d'abord, puis appeler `authService.logout()` → vérifier que `localStorage['budget_token']` est null, `isAuthenticated()` retourne `false`, et la navigation est vers `/auth`.

### Implementation

- [x] T007 [US3] Implémenter la méthode `logout()` dans `app/src/app/core/services/auth.ts` — Appeler `clearAuth()` puis `this.router.navigate(['/auth'])`. Méthode synchrone, pas de retour Observable.

**Checkpoint**: La déconnexion fonctionne avec nettoyage complet et redirection.

---

## Phase 6: User Story 4 — Détection d'expiration de session (Priority: P4)

**Goal**: Un token expiré ou corrompu est détecté automatiquement et l'utilisateur est considéré comme déconnecté.

**Independent Test**: Mettre manuellement un token expiré dans `localStorage['budget_token']`, puis appeler `authService.getToken()` → retourne `null` et `isAuthenticated()` retourne `false`.

### Implementation

- [x] T008 [US4] Renforcer la détection d'expiration dans `getToken()` dans `app/src/app/core/services/auth.ts` — Si le token est expiré ou corrompu (décodeToken retourne null), appeler `clearAuth()` et retourner `null`. Ceci assure le nettoyage automatique lors de toute tentative d'utilisation du token par l'intercepteur (KKS-26) ou le guard (KKS-27). Le constructeur gère déjà le cas au démarrage (T004) ; cette tâche couvre le cas pendant l'utilisation active.

**Checkpoint**: Tout token expiré/corrompu est automatiquement détecté et nettoyé.

---

## Phase 7: Tests unitaires AuthService

**Purpose**: Valider le comportement du AuthService via tests unitaires (principe V constitution)

**CRITICAL**: Les tests DOIVENT passer avant la phase Polish

- [x] T009 [P] Tester login() dans `app/src/app/core/services/auth.spec.ts` — cas nominal (token stocké dans `localStorage['budget_token']`, user stocké dans `localStorage['budget_user']` au format JSON `{name, email}`, signal `currentUser()` contient `{name, email}` corrects, signal `isAuthenticated` → true), erreur 400 (message "Email ou mot de passe incorrect" mappé), erreur réseau (status 0 → "Impossible de contacter le serveur"), erreur 500 (message "Une erreur est survenue" mappé — couvre SC-004). Pattern AAA, nommage `should_[résultat]_when_[condition]`.
- [x] T010 [P] Tester register() dans `app/src/app/core/services/auth.spec.ts` — cas nominal (auto-connexion, `localStorage['budget_token']` et `localStorage['budget_user']` stockés, `currentUser()` contient `{name, email}` corrects, `isAuthenticated` → true), email déjà pris (400 avec `error.error.message` → "Email déjà utilisé"), validation Bean (400 avec `error.error.message` → chaîne concaténée "field: message; field: message", ex: "password: size must be between 6 and 2147483647"), erreur réseau (status 0 → "Impossible de contacter le serveur"), erreur 500 (message "Une erreur est survenue" mappé — couverture symétrique FR-008 avec T009). Mock ApiService.
- [x] T011 [P] Tester logout() dans `app/src/app/core/services/auth.spec.ts` — token supprimé de localStorage, signal `currentUser` → null, `isAuthenticated` → false, navigation vers `/auth` appelée.
- [x] T012 [P] Tester getToken() dans `app/src/app/core/services/auth.spec.ts` — token valide retourné, token expiré → null + `clearAuth()` appelé, token corrompu (base64 invalide) → null.
- [x] T013 Tester constructeur AuthService dans `app/src/app/core/services/auth.spec.ts` — restauration session avec token valide en localStorage, nettoyage avec token expiré, localStorage indisponible (spy throwant une erreur) → mode volatile sans crash, `budget_user` corrompu (JSON invalide en localStorage) → nettoyage des deux clés et état déconnecté.

**Checkpoint**: Tous les tests passent (`ng test`). AuthService conforme au principe V.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et intégration

- [x] T014 Exporter les modèles et le service via des barrel files si le pattern existe dans `app/src/app/core/` — Vérifier si un `index.ts` existe déjà dans `core/services/` ou `core/models/`. Si oui, ajouter les exports. Si non, ne pas créer de barrel (YAGNI).
- [x] T015 Exécuter `ng lint` et `npm run format:check` dans `app/` pour valider le code
- [x] T016 Valider les scénarios du quickstart.md : démarrer le backend, lancer le frontend, vérifier login/logout/session restore dans la console navigateur

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — démarrage immédiat
- **Foundational (Phase 2)**: Dépend de Phase 1 — **BLOQUE toutes les user stories**
- **US1 Connexion (Phase 3)**: Dépend de Phase 2
- **US2 Inscription (Phase 4)**: Dépend de Phase 2 — parallélisable avec US1
- **US3 Déconnexion (Phase 5)**: Dépend de Phase 2 — parallélisable avec US1/US2
- **US4 Expiration (Phase 6)**: Dépend de Phase 2 — parallélisable avec les autres
- **Tests (Phase 7)**: Dépend de toutes les user stories (Phases 3-6) — T009-T012 parallélisables, T013 indépendant
- **Polish (Phase 8)**: Dépend de Phase 7 (les tests DOIVENT passer avant Polish)

### User Story Dependencies

- **US1 (P1)**: Indépendante — utilise login() + saveAuth() + signaux. Couvre FR-008 pour les erreurs login (identifiants invalides, réseau, 500).
- **US2 (P2)**: Indépendante — utilise register() + saveAuth() (même pattern que US1). Couvre FR-008 pour les erreurs register (email pris, validation, réseau).
- **US3 (P3)**: Indépendante — utilise clearAuth() + Router
- **US4 (P4)**: Indépendante — renforce getToken() déjà créé en Phase 2

### Within Each User Story

- Modèles avant services (Phase 2 couvre tous les modèles)
- Squelette service avant méthodes métier
- Chaque méthode est autonome dans le même fichier `auth.ts`

### Parallel Opportunities

- **Phase 2**: T002 et T003 peuvent s'exécuter en parallèle (fichiers différents)
- **Phase 3-6**: Toutes les user stories sont parallélisables après Phase 2 (même fichier `auth.ts` mais méthodes indépendantes)
- En pratique (développeur solo), l'ordre séquentiel P1 → P2 → P3 → P4 est recommandé

---

## Parallel Example: Phase 2 (Foundational)

```text
# Lancer en parallèle :
T002: Créer auth.model.ts (LoginRequest, RegisterRequest, AuthResponse)
T003: Créer user.model.ts (UserInfo)

# Puis séquentiellement :
T004: Créer AuthService skeleton (dépend de T002 + T003)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (T001)
2. Compléter Phase 2: Foundational (T002-T004)
3. Compléter Phase 3: US1 Connexion (T005)
4. **STOP et VALIDER**: Tester login + session restore + getToken
5. Le MVP est livrable : les issues KKS-26 (intercepteur) et KKS-27 (guard) peuvent démarrer

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. + US1 Connexion → **MVP** (login fonctionne)
3. + US2 Inscription → Nouveau comptes possibles
4. + US3 Déconnexion → Cycle auth complet
5. + US4 Expiration → Robustesse
6. Tests unitaires → Conformité principe V constitution
7. Polish → Code propre et validé

---

## Notes

- Tous les fichiers de cette feature sont dans `app/src/app/core/` (convention plan.md)
- Le service est dans un seul fichier `auth.ts` — les tâches US sont des méthodes, pas des fichiers séparés
- Conventions signals-first : `signal()`, `computed()`, `inject()` (cf. CLAUDE.md)
- Pas de `subscribe()` manuel — les composants consommeront les signals directement
- Le `saveAuth()` et `clearAuth()` privés factorisent la logique commune entre les stories
- Commit recommandé après chaque phase complétée
- Tests unitaires du AuthService couverts en Phase 7 (T009-T013). Fichier unique `auth.spec.ts` dans `core/services/`.
- Limitation connue : les appels login/register simultanés ne sont pas protégés (pas de mutex/debounce). Acceptable en contexte single-user — le dernier token reçu sera stocké sans corruption.
