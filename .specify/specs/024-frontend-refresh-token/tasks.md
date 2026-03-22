# Tasks: Frontend Refresh Token

**Input**: Design documents from `/specs/024-frontend-refresh-token/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Inclus — les fichiers de tests existants (`auth.spec.ts`, `auth.interceptor.spec.ts`) doivent être mis à jour pour couvrir les nouveaux comportements (Constitution V. Testabilité).

**Organization**: Tâches groupées par user story. Chaque story est indépendamment testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Foundational (Prérequis bloquants)

**Purpose**: Mise à jour du modèle et des méthodes de stockage — requis par TOUTES les user stories

**CRITICAL**: Aucune user story ne peut démarrer avant la fin de cette phase

- [x] T001 Ajouter le champ `refreshToken: string` à l'interface `AuthResponse` dans `app/src/app/core/models/auth.model.ts`
- [x] T002 Ajouter la gestion du refresh token au stockage dans `app/src/app/core/services/auth.ts` : constante `STORAGE_REFRESH_TOKEN_KEY = 'budget_refresh_token'`, modifier `saveAuth()` pour stocker `response.refreshToken` dans localStorage, modifier `clearAuth()` pour supprimer `budget_refresh_token`, ajouter méthode `getRefreshToken(): string | null` (lecture localStorage avec try/catch comme `getToken()`)

**Checkpoint**: Le modèle et le stockage sont prêts — les user stories peuvent démarrer

---

## Phase 2: User Story 1 — Renouvellement transparent de session (Priority: P1) MVP

**Goal**: Quand l'access token expire, le système renouvelle automatiquement via POST /auth/refresh et rejoue la requête. Les requêtes concurrentes sont sérialisées.

**Independent Test**: Effectuer une requête API avec un access token expiré et un refresh token valide → la requête aboutit sans intervention utilisateur.

### Implementation

- [x] T003 [US1] Ajouter méthode `refreshAccessToken()` à AuthService dans `app/src/app/core/services/auth.ts` : appel `this.apiService.post<AuthResponse>('/auth/refresh', { refreshToken })`, puis `saveAuth()` avec la nouvelle réponse (rotation des tokens FR-007). Retourne `Observable<AuthResponse>`
- [x] T004 [US1] Réécrire l'intercepteur HTTP dans `app/src/app/core/interceptors/auth.interceptor.ts` : ajouter `/auth/refresh` à `PUBLIC_PATHS`, remplacer le `catchError` actuel par une logique de refresh sur 401 (appeler `authService.refreshAccessToken()`, rejouer la requête clonée avec le nouveau token FR-003), ajouter `BehaviorSubject<boolean>` pour sérialiser les requêtes concurrentes (FR-004), ajouter un header custom `_retry` sur les requêtes rejouées pour éviter les boucles infinies (FR-008)
- [x] T005 [P] [US1] Mettre à jour les tests AuthService dans `app/src/app/core/services/auth.spec.ts` : tests pour `refreshAccessToken()` (succès avec rotation, échec 401), tests pour `getRefreshToken()`, tests pour `saveAuth()` stockant le refresh token
- [x] T006 [P] [US1] Mettre à jour les tests intercepteur dans `app/src/app/core/interceptors/auth.interceptor.spec.ts` : test refresh automatique sur 401 avec replay de la requête, test sérialisation de N requêtes concurrentes (une seule requête de refresh émise), test anti-boucle (requête _retry ne déclenche pas de nouveau refresh), test exclusion de `/auth/refresh` des routes interceptées

**Checkpoint**: Le renouvellement transparent fonctionne. L'utilisateur ne perçoit aucune interruption (SC-001, SC-002, SC-005).

---

## Phase 3: User Story 2 — Déconnexion propre avec révocation (Priority: P2)

**Goal**: Le logout révoque le refresh token côté serveur (POST /auth/logout) avant de nettoyer le stockage local. Fire-and-forget — l'échec de l'appel API ne bloque pas la déconnexion.

**Independent Test**: Se déconnecter puis vérifier que l'ancien refresh token est rejeté par le serveur.

### Implementation

- [x] T007 [US2] Modifier `logout()` dans `app/src/app/core/services/auth.ts` : avant `clearAuth()` et `router.navigate(['/auth'])`, appeler `this.apiService.post('/auth/logout', { refreshToken })` en fire-and-forget (FR-006). L'appel ne doit pas bloquer — utiliser `firstValueFrom()` avec `catchError` qui ignore l'erreur
- [x] T008 [US2] Ajouter tests pour le logout avec révocation dans `app/src/app/core/services/auth.spec.ts` : test appel POST /auth/logout avec le refresh token, test fire-and-forget (erreur réseau ne bloque pas le nettoyage local), test `budget_refresh_token` supprimé du localStorage après logout

**Checkpoint**: La déconnexion révoque le token côté serveur (SC-003).

---

## Phase 4: User Story 3 — Déconnexion forcée après échec du refresh (Priority: P2)

**Goal**: Si le refresh échoue (401, token révoqué, token expiré), l'utilisateur est automatiquement déconnecté et redirigé vers /auth. Les erreurs réseau ne déclenchent PAS de déconnexion.

**Independent Test**: Effectuer une requête API avec un access token expiré et un refresh token invalide → redirection vers /auth en < 2s.

**Note**: La logique de base est implémentée dans T004 (chemin d'erreur du refresh). Cette phase renforce et teste spécifiquement les scénarios d'échec.

### Implementation

- [x] T009 [US3] Vérifier et renforcer le chemin d'erreur dans l'intercepteur `app/src/app/core/interceptors/auth.interceptor.ts` : distinguer erreur 401 sur refresh (→ `logout()` + redirect, FR-005) de erreur réseau sur refresh (→ propager l'erreur sans déconnexion, edge case spec)
- [x] T010 [US3] Ajouter tests intercepteur pour les scénarios d'échec dans `app/src/app/core/interceptors/auth.interceptor.spec.ts` : test 401 sur le refresh → logout appelé + redirect /auth, test erreur réseau (status 0) sur le refresh → pas de logout + erreur propagée, test refresh token absent → logout immédiat sans tenter de refresh

**Checkpoint**: L'échec du refresh déclenche une déconnexion propre (SC-004). Les erreurs réseau sont gérées sans déconnexion.

---

## Phase 5: User Story 4 — Persistance du refresh token entre sessions (Priority: P3)

**Goal**: À la réouverture de l'app, si l'access token est expiré mais le refresh token est présent, tenter un renouvellement automatique avant de forcer une reconnexion.

**Independent Test**: Fermer l'app avec un access token expiré et un refresh token valide, la rouvrir → session restaurée sans reconnexion.

### Implementation

- [x] T011 [US4] Modifier `restoreSession()` dans `app/src/app/core/services/auth.ts` : si l'access token est expiré et qu'un refresh token existe dans localStorage, appeler `refreshAccessToken()` (FR-009). Sur succès : restaurer la session (set `currentUser`). Sur échec : appeler `clearAuth()` (pas de redirect — l'auth guard s'en charge)
- [x] T012 [US4] Ajouter tests pour restoreSession avec refresh dans `app/src/app/core/services/auth.spec.ts` : test access token expiré + refresh token valide → refresh automatique + session restaurée, test access token expiré + refresh token expiré/absent → clearAuth appelé, test access token valide → pas de refresh (comportement existant inchangé)

**Checkpoint**: L'utilisateur retrouve sa session sans se reconnecter après fermeture de l'app.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation globale et correction des régressions

- [x] T013 Lancer la suite complète de tests (`cd app && npx vitest run`) et corriger les régressions sur les tests existants
- [x] T014 Exécuter la validation quickstart.md : connexion → vérifier `budget_refresh_token` dans localStorage → supprimer `budget_token` → naviguer → vérifier le refresh automatique → se déconnecter → vérifier le nettoyage

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Pas de dépendance — peut démarrer immédiatement
- **US1 (Phase 2)**: Dépend de Phase 1. **MVP — implémenter en premier**
- **US2 (Phase 3)**: Dépend de Phase 1. Indépendant de US1
- **US3 (Phase 4)**: Dépend de US1 (logique de refresh dans l'intercepteur) + US2 (logout avec révocation)
- **US4 (Phase 5)**: Dépend de Phase 1 + T003 (méthode `refreshAccessToken()`)
- **Polish (Phase 6)**: Dépend de toutes les phases précédentes

### User Story Dependencies

```
Phase 1 (Foundational)
  ├── US1 (P1) ─────┐
  ├── US2 (P2) ─────┼── US3 (P2) dépend de US1 + US2
  │                  │   (chemin d'erreur du refresh + logout avec révocation)
  └── US4 (P3)      │
       └── dépend uniquement de T003 (refreshAccessToken)
```

### Within Each User Story

- Service methods avant intercepteur
- Implémentation avant tests (tests [P] peuvent être parallélisés entre eux)

### Parallel Opportunities

- T001 et T002 : séquentiels (T002 dépend du type modifié en T001)
- T005 et T006 : parallélisables (fichiers différents)
- T007 et T011 : parallélisables après Phase 1 (US2 et US4 sont indépendants)
- T008 et T012 : parallélisables (tests dans le même fichier mais sections différentes)
- US2 et US4 : parallélisables (pas de dépendance mutuelle)

---

## Parallel Example: User Story 1

```bash
# Après T003 et T004, lancer les tests en parallèle :
Task T005: "Tests AuthService refreshAccessToken dans auth.spec.ts"
Task T006: "Tests intercepteur refresh 401 dans auth.interceptor.spec.ts"
```

## Parallel Example: US2 + US4

```bash
# Après Phase 1, lancer en parallèle :
Task T007: "Modifier logout() dans auth.ts"           # US2
Task T011: "Modifier restoreSession() dans auth.ts"    # US4
# ⚠️ Même fichier mais sections différentes — possible si pas de conflit
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Foundational (T001, T002)
2. Compléter Phase 2: US1 (T003, T004, T005, T006)
3. **STOP et VALIDER**: Le refresh automatique fonctionne
4. Le MVP est déployable — l'utilisateur ne perd plus sa session

### Incremental Delivery

1. Phase 1 → Fondation prête
2. Phase 2 (US1) → Refresh transparent fonctionne (MVP)
3. Phase 3 (US2) → Logout révoque le token (sécurité renforcée)
4. Phase 4 (US3) → Échec du refresh gère proprement la déconnexion
5. Phase 5 (US4) → Persistance entre sessions (confort UX)
6. Phase 6 → Validation globale

---

## Notes

- 5 fichiers modifiés, 0 fichiers créés
- Tous les changements sont dans `app/src/app/core/` (models, services, interceptors)
- Le backend est déjà implémenté (commit `5793e8f`)
- Commiter après chaque phase complétée
- Pense à vérifier `/sync-doc` après le dernier commit
