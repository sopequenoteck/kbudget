# Tasks: Refresh Token JWT Backend

**Input**: Design documents from `/specs/023-jwt-refresh-token/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/auth-api.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Configuration)

**Purpose**: Mettre à jour la configuration JWT existante pour supporter les durées access/refresh distinctes

- [x] T001 Update JWT configuration properties in `api/src/main/resources/application.yaml` — rename `app.jwt.expiration` to `app.jwt.access-expiration` (900000 = 15 min), add `app.jwt.refresh-expiration` (2592000000 = 30 days)
- [x] T002 Update JwtUtil to use renamed property `app.jwt.access-expiration` in `api/src/main/java/fr/kksdev/budget/api/config/JwtUtil.java` — change `@Value("${app.jwt.expiration}")` to `@Value("${app.jwt.access-expiration}")`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Créer l'infrastructure data model et DTOs partagés par toutes les user stories

- [x] T003 [P] Create TokenStatus enum (ACTIVE, CONSUMED, REVOKED) in `api/src/main/java/fr/kksdev/budget/api/enums/TokenStatus.java`
- [x] T004 [P] Create Flyway migration V6__add_refresh_tokens.sql in `api/src/main/resources/db/migration/V6__add_refresh_tokens.sql` — table refresh_tokens with columns id (UUID PK), token (VARCHAR 64 UNIQUE), status (VARCHAR 20 DEFAULT ACTIVE), user_id (UUID FK → users ON DELETE CASCADE), created_at (TIMESTAMP), expires_at (TIMESTAMP), plus indexes on token (unique), user_id, status
- [x] T005 [P] Create ErrorResponse DTO in `api/src/main/java/fr/kksdev/budget/api/dto/response/ErrorResponse.java` — record with fields: String error, String message
- [x] T006 Create RefreshToken entity in `api/src/main/java/fr/kksdev/budget/api/model/RefreshToken.java` — @Entity @Table(name="refresh_tokens"), fields: UUID id (PK auto), String token (unique), TokenStatus status (@Enumerated STRING), User user (@ManyToOne LAZY), LocalDateTime createdAt (@CreationTimestamp), LocalDateTime expiresAt. Lombok: @Data @Builder @NoArgsConstructor @AllArgsConstructor
- [x] T007 Create RefreshTokenRepository in `api/src/main/java/fr/kksdev/budget/api/repository/RefreshTokenRepository.java` — JpaRepository<RefreshToken, UUID> with methods: Optional<RefreshToken> findByToken(String token), List<RefreshToken> findByUserAndStatus(User user, TokenStatus status), void deleteByExpiresAtBefore(LocalDateTime date)
- [x] T008 Modify AuthResponse to add refreshToken field in `api/src/main/java/fr/kksdev/budget/api/dto/response/AuthResponse.java` — add String refreshToken parameter to the record

**Checkpoint**: Foundation ready — entity, repository, DTOs, migration en place

---

## Phase 3: User Story 1 — Renouvellement transparent de session (Priority: P1) MVP

**Goal**: Le login/register retourne un refresh token en plus de l'access token. L'endpoint POST /auth/refresh accepte un refresh token valide et retourne un nouveau couple access + refresh token (rotation).

**Independent Test**: Appeler POST /api/auth/login → vérifier que la réponse contient `refreshToken`. Appeler POST /api/auth/refresh avec ce token → vérifier nouveau couple retourné et ancien token consommé.

### Implementation for User Story 1

- [x] T009 [P] [US1] Create RefreshRequest DTO in `api/src/main/java/fr/kksdev/budget/api/dto/request/RefreshRequest.java` — record with @NotBlank String refreshToken
- [x] T010b [P] [US1] Create token exception classes in `api/src/main/java/fr/kksdev/budget/api/exception/` — (1) TokenExpiredException extends RuntimeException, (2) TokenRevokedException extends RuntimeException, (3) TokenReusedException extends RuntimeException, (4) TokenInvalidException extends RuntimeException. Each carries a String errorCode (TOKEN_EXPIRED, TOKEN_REVOKED, TOKEN_REUSE_DETECTED, TOKEN_INVALID) and a user-facing message. Then create TokenExceptionHandler (@RestControllerAdvice) in same package — handles each exception type, returns ResponseEntity<ErrorResponse> with HTTP 401 and the appropriate error code/message from the exception.
- [x] T010 [US1] Create RefreshTokenService in `api/src/main/java/fr/kksdev/budget/api/service/RefreshTokenService.java` — @Service @Slf4j @Transactional with @Value("${app.jwt.refresh-expiration}") long refreshExpiration. Methods: (1) generateRefreshToken(User user) → creates RefreshToken entity with SecureRandom 32 bytes Base64url, status ACTIVE, expiresAt = now + refreshExpiration (from config), saves and returns token string. (2) refreshAccessToken(String refreshToken) → finds token in DB with @Lock(PESSIMISTIC_WRITE) to prevent concurrent refresh race conditions, validates status is ACTIVE and not expired, throws typed exceptions on failure (see T010b), marks old token CONSUMED, generates new refresh token, generates new access token via JwtUtil, returns AuthResponse. Log INFO on emission and renewal.
- [x] T011 [US1] Modify AuthService to generate refresh token on login and register in `api/src/main/java/fr/kksdev/budget/api/service/AuthService.java` — inject RefreshTokenService, call generateRefreshToken(user) in both login() and register() methods, include refreshToken in AuthResponse constructor
- [x] T012 [US1] Add POST /auth/refresh endpoint in `api/src/main/java/fr/kksdev/budget/api/controller/AuthController.java` — accepts @Valid @RequestBody RefreshRequest, calls refreshTokenService.refreshAccessToken(), returns AuthResponse 200 on success, returns ErrorResponse 401 on failure (TOKEN_EXPIRED, TOKEN_INVALID)

**Checkpoint**: Login retourne un refresh token, l'endpoint refresh fonctionne avec rotation

---

## Phase 4: User Story 2 — Déconnexion sécurisée avec révocation (Priority: P2)

**Goal**: L'endpoint POST /auth/logout révoque le refresh token fourni. Toute tentative de réutilisation est rejetée.

**Independent Test**: Appeler POST /api/auth/logout avec un refresh token valide → 204. Tenter POST /api/auth/refresh avec ce même token → 401 TOKEN_REVOKED.

### Implementation for User Story 2

- [x] T013 [P] [US2] Create LogoutRequest DTO in `api/src/main/java/fr/kksdev/budget/api/dto/request/LogoutRequest.java` — record with @NotBlank String refreshToken
- [x] T014 [US2] Add revokeRefreshToken method to RefreshTokenService in `api/src/main/java/fr/kksdev/budget/api/service/RefreshTokenService.java` — finds token in DB, validates it exists and status is ACTIVE, sets status to REVOKED, saves. Log INFO on revocation. Throw exception if token not found or already invalidated.
- [x] T015 [US2] Add POST /auth/logout endpoint in `api/src/main/java/fr/kksdev/budget/api/controller/AuthController.java` — accepts @Valid @RequestBody LogoutRequest, calls refreshTokenService.revokeRefreshToken(), returns 204 No Content on success, returns ErrorResponse 400 on failure (TOKEN_INVALID)
- [x] T016 [US2] Update refreshAccessToken in RefreshTokenService to return differentiated error for REVOKED tokens — if token found with status REVOKED, return ErrorResponse with error code TOKEN_REVOKED (distinct from TOKEN_EXPIRED and TOKEN_INVALID)

**Checkpoint**: Logout révoque le token, refresh rejette les tokens révoqués avec code distinct

---

## Phase 5: User Story 3 — Protection contre le vol de refresh token (Priority: P3)

**Goal**: Si un refresh token déjà CONSUMED est réutilisé, le système détecte le vol potentiel et révoque tous les refresh tokens actifs de l'utilisateur.

**Independent Test**: Effectuer un refresh (token A → token B). Tenter de réutiliser token A → 401 TOKEN_REUSE_DETECTED. Vérifier que token B est aussi révoqué (tentative de refresh avec B → 401 TOKEN_REVOKED).

### Implementation for User Story 3

- [x] T017 [US3] Add reuse detection logic to refreshAccessToken in `api/src/main/java/fr/kksdev/budget/api/service/RefreshTokenService.java` — if token found with status CONSUMED, call revokeAllUserTokens(user) and return ErrorResponse with error code TOKEN_REUSE_DETECTED. Log ERROR on reuse detection with userId and token context (constitution VI: security errors at ERROR level).
- [x] T018 [US3] Add revokeAllUserTokens method to RefreshTokenService in `api/src/main/java/fr/kksdev/budget/api/service/RefreshTokenService.java` — finds all tokens with status ACTIVE for the user (via findByUserAndStatus), sets all to REVOKED, saves. Log WARN with user email and count of revoked tokens.

**Checkpoint**: La chaîne complète fonctionne — rotation, révocation, détection de vol

---

## Phase 6: Tests & Polish

**Purpose**: Tests unitaires et d'intégration couvrant les 3 user stories, validation build

- [x] T019 [P] Create RefreshTokenServiceTest (unit tests) in `api/src/test/java/fr/kksdev/budget/api/service/RefreshTokenServiceTest.java` — mock RefreshTokenRepository and JwtUtil. Tests: should_generateRefreshToken_when_userProvided, should_returnNewTokenPair_when_validRefreshToken, should_markOldTokenConsumed_when_refreshSucceeds (US1), should_revokeToken_when_logoutCalled, should_throwException_when_tokenAlreadyRevoked (US2), should_revokeAllUserTokens_when_consumedTokenReused, should_returnReuseDetectedError_when_consumedTokenPresented (US3), should_returnExpiredError_when_tokenExpired
- [x] T020 [P] Create AuthControllerRefreshTest (integration tests) in `api/src/test/java/fr/kksdev/budget/api/controller/AuthControllerRefreshTest.java` — @SpringBootTest @AutoConfigureMockMvc with H2. Tests: POST /auth/login returns refreshToken (US1), POST /auth/refresh returns new token pair (US1), POST /auth/refresh rejects expired token with TOKEN_EXPIRED (US1), POST /auth/refresh without Authorization header succeeds with valid refresh token (FR-012), POST /auth/logout revokes token with 204 (US2), POST /auth/refresh rejects revoked token with TOKEN_REVOKED (US2), POST /auth/refresh detects reuse with TOKEN_REUSE_DETECTED (US3)
- [x] T021 Verify full build compiles and all tests pass — run `cd api && mvn clean install`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001, T002 must complete first for JwtUtil consistency)
- **US1 (Phase 3)**: Depends on Phase 2 — creates the core refresh service
- **US2 (Phase 4)**: Depends on Phase 3 — extends RefreshTokenService with revoke method
- **US3 (Phase 5)**: Depends on Phase 3 — extends refreshAccessToken with reuse detection
- **Tests & Polish (Phase 6)**: Depends on Phases 3, 4, 5

### User Story Dependencies

- **US1 (P1)**: Foundation → US1 (creates RefreshTokenService, refresh endpoint)
- **US2 (P2)**: Foundation → US1 → US2 (extends service with revoke, adds logout endpoint)
- **US3 (P3)**: Foundation → US1 → US3 (extends refresh logic with reuse detection)
- **US2 et US3** peuvent être développées en parallèle après US1

### Within Each User Story

- DTOs before services
- Services before controller endpoints
- Core logic before logging
- Story complete before moving to next priority

### Parallel Opportunities

- T003, T004, T005 can run in parallel (different files, no dependencies). T006 depends on T003, T007 depends on T006.
- T009, T010b, and T013 can run in parallel (different files, no dependencies). T010 depends on T010b (uses typed exceptions).
- T019 and T020 can run in parallel (different test files)
- US2 (Phase 4) and US3 (Phase 5) can run in parallel after US1 completion

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch all independent foundational tasks together:
Task: "Create TokenStatus enum in api/.../enums/TokenStatus.java"           # T003
Task: "Create Flyway migration V6__add_refresh_tokens.sql"                   # T004
Task: "Create ErrorResponse DTO in api/.../dto/response/ErrorResponse.java"  # T005
# Then sequentially:
Task: "Create RefreshToken entity (depends on TokenStatus enum)"             # T006
Task: "Create RefreshTokenRepository (depends on RefreshToken entity)"       # T007
Task: "Modify AuthResponse (depends on existing file)"                       # T008
```

## Parallel Example: Tests (Phase 6)

```bash
# Launch both test files together:
Task: "Create RefreshTokenServiceTest (unit tests)"      # T019
Task: "Create AuthControllerRefreshTest (integration)"   # T020
# Then:
Task: "Verify full build"                                # T021
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T008)
3. Complete Phase 3: User Story 1 (T009–T012)
4. **STOP and VALIDATE**: Login retourne un refresh token, refresh endpoint fonctionne
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Configuration et data model prêts
2. Add US1 → Refresh token fonctionnel (MVP)
3. Add US2 → Logout avec révocation
4. Add US3 → Détection de vol (sécurité complète)
5. Add Tests → Couverture unitaire et intégration
6. Each story adds security without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Backend uniquement — aucune modification frontend
- L'access token passe de 24h à 15 min (FR-008) — le frontend sera dégradé jusqu'à l'implémentation de l'auto-refresh côté Angular (feature séparée)
- Commit après chaque phase ou groupe logique de tâches
- Chaque checkpoint valide la story indépendamment
