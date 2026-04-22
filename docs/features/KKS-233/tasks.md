# Tasks — KKS-233 : Bootstrap du premier admin sur DB vide (pattern password généré au premier boot)

> Date : 2026-04-22
> Issue : KKS-233
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)
> Contrats : [contracts.md](./contracts.md)

---

## Phase 1 — Setup

- [x] `[T-001]` Vérifier la présence de `spring-boot-starter-validation` dans `api/pom.xml` (requis pour `@ConfigurationProperties @Validated` + Bean Validation sur DTOs). — Réf : FR-009, FR-017
- [x] `[T-002]` Vérifier la branche `feature/KKS-233` créée depuis `develop` (déjà effectué au début du flow devflow). — Réf : workflow projet

### Checkpoint Phase 1

**Condition de sortie** : dépendances Maven complètes, branche active, projet compile (`cd api && mvn clean compile`).

---

## Phase 2 — Fondations

- [x] `[T-010]` `[P]` Créer la migration Flyway `V30__add_user_is_admin.sql` avec `ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE`. — Réf : FR-012a
- [x] `[T-011]` `[P]` Créer la migration Flyway `V31__add_user_password_reset_required.sql` avec `ALTER TABLE users ADD COLUMN password_reset_required BOOLEAN NOT NULL DEFAULT FALSE`. — Réf : FR-002
- [x] `[T-012]` Modifier `api/src/main/java/fr/kksdev/budget/api/model/User.java` : ajouter les champs `@Column(name = "is_admin", nullable = false) private boolean isAdmin;` et `@Column(name = "password_reset_required", nullable = false) private boolean passwordResetRequired;` — dépend T-010, T-011. — Réf : FR-002, FR-012
- [x] `[T-013]` `[P]` Créer `api/src/main/java/fr/kksdev/budget/api/util/PasswordGenerator.java` (classe finale, constructeur privé, méthode statique `generate(int length)` avec `SecureRandom` + alphabet `[A-Za-z0-9]`). — Réf : FR-002, SC-007
- [x] `[T-014]` `[P]` Étendre `api/src/main/java/fr/kksdev/budget/api/config/JwtUtil.java` : ajouter la surcharge `generateToken(String email, Map<String, Object> extraClaims)` et la méthode `extractClaim(String token, String claimName)`. La surcharge simple `generateToken(String email)` délègue à `generateToken(email, Map.of())`. — Réf : FR-008, RES-003
- [x] `[T-015]` Modifier `api/src/main/java/fr/kksdev/budget/api/dto/response/AuthResponse.java` : ajouter le champ `boolean mustResetCredentials` (toujours présent, non-null primitive). Ne pas encore toucher aux consommateurs. — Réf : FR-007, RES-006
- [x] `[T-016]` `[P]` Créer `api/src/main/java/fr/kksdev/budget/api/config/BootstrapProperties.java` (record ou classe `@Data` avec `@ConfigurationProperties(prefix = "app.bootstrap") @Validated @Component` + champ `@NotBlank @Email String email` défaut `admin@localhost`). — Réf : FR-017, RES-005
- [x] `[T-017]` Modifier `api/src/main/resources/application.yaml` : ajouter la clé `app.bootstrap.email: ${BOOTSTRAP_EMAIL:admin@localhost}`. — Réf : FR-017, FR-002
- [x] `[T-018]` Extraire `UserOnboardingService` depuis `AcceptInviteService` (RES-001) : créer `api/src/main/java/fr/kksdev/budget/api/service/UserOnboardingService.java` avec le record `UserProvisioningRequest(email, rawPassword, displayName, currency, timezone, isAdmin, passwordResetRequired)` et la méthode `@Transactional provisionUser(UserProvisioningRequest)` qui appelle `userRepository.save`, `categoryService.seedSystemCategories`, `accountService.createDefaultAccount`, `preferenceService.createInitialPreference`. Ne touche pas encore à `AcceptInviteService`. — dépend T-012. — Réf : FR-002, FR-003, RES-001

### Checkpoint Phase 2

**Condition de sortie** : projet compile sans erreur. Migrations Flyway appliquées localement (`cd api && mvn flyway:info` ou démarrage app en profil dev). Entité `User` porte les nouveaux champs.

---

## Phase 3 — User Stories

### Phase 3a — US1 (P1) : Premier démarrage sur DB vide

- [x] `[T-020]` `[P1]` `[US1]` Créer `api/src/main/java/fr/kksdev/budget/api/runner/BootstrapSeedRunner.java` : `@Component @Order(1) @RequiredArgsConstructor @Slf4j class BootstrapSeedRunner implements ApplicationRunner`. Logique : si `userRepository.count() == 0`, générer un password 32 chars via `PasswordGenerator.generate(32)`, appeler `userOnboardingService.provisionUser` avec `isAdmin=true, passwordResetRequired=true`, puis `log.warn(buildBanner(email, password))`. Méthode `buildBanner` utilise un text block Java. — dépend T-013, T-016, T-018. — Réf : FR-001, FR-002, FR-004, FR-005, FR-006
- [x] `[T-021]` `[P]` `[P1]` `[US1]` Créer `api/src/test/java/fr/kksdev/budget/api/util/PasswordGeneratorTest.java` : tests `should_return_string_of_requested_length_when_generating_password`, `should_contain_only_alphanumeric_chars_when_generating_password`, `should_produce_different_outputs_across_calls`. — dépend T-013. — Réf : SC-007
- [x] `[T-022]` `[P]` `[P1]` `[US1]` Créer `api/src/test/java/fr/kksdev/budget/api/config/BootstrapPropertiesTest.java` : test `should_fail_to_start_context_when_bootstrap_email_is_invalid` via `ApplicationContextRunner` avec property `app.bootstrap.email=not-an-email` → attendre `ConfigurationPropertiesBindException`. — dépend T-016. — Réf : FR-017
- [x] `[T-023]` `[P1]` `[US1]` Créer `api/src/test/java/fr/kksdev/budget/api/runner/BootstrapSeedRunnerTest.java` avec `@SpringBootTest` + profil test + DB vide : `should_seed_admin_user_with_is_admin_and_password_reset_required_flags_when_db_is_empty`, `should_seed_account_and_preferences_when_db_is_empty`, `should_log_banner_at_WARN_level_when_seeding`. — dépend T-020. — Réf : SC-002
- [x] `[T-024]` `[P]` `[P1]` `[US1]` Dans `BootstrapSeedRunnerTest`, test `should_use_custom_email_when_BOOTSTRAP_EMAIL_is_set` avec property `app.bootstrap.email=kelly@exemple.com`. — dépend T-020. — Réf : FR-002, SC-006

### Phase 3b — US2 (P1) : Reset forcé à la première connexion

Backend :

- [x] `[T-025]` `[P]` `[P1]` `[US2]` Créer `api/src/main/java/fr/kksdev/budget/api/dto/request/FirstLoginResetRequest.java` (record avec `@NotBlank @Email @Size(max=255) email`, `@NotBlank @Size(min=8, max=100) password`, `@NotBlank @Size(min=1, max=100) displayName`). — Réf : FR-009
- [x] `[T-026]` `[P]` `[P1]` `[US2]` Créer `api/src/main/java/fr/kksdev/budget/api/exception/PasswordUnchangedException.java` + ajouter le handler dans `GlobalExceptionHandler` mappant vers `400 Bad Request` avec payload `{ error: "PASSWORD_UNCHANGED", message: "..." }`. — Réf : FR-011
- [x] `[T-027]` `[P1]` `[US2]` Créer `api/src/main/java/fr/kksdev/budget/api/config/PasswordResetRequiredFilter.java extends OncePerRequestFilter` : extraction du Bearer token, lecture du claim `mustResetCredentials`, allowlist paths `["/auth/first-login-reset", "/auth/logout"]`, réponse `403` avec payload JSON si gate actif hors allowlist. — dépend T-014. — Réf : FR-008
- [x] `[T-028]` `[P1]` `[US2]` Enregistrer `PasswordResetRequiredFilter` comme bean dans `SecurityConfig.securityFilterChain` après `JwtFilter` et avant `AdminAuthorizationFilter`. — dépend T-027. — Réf : FR-008
- [x] `[T-029]` `[P1]` `[US2]` Modifier `AuthService.login` : construire `Map<String, Object> extraClaims = user.isPasswordResetRequired() ? Map.of("mustResetCredentials", true) : Map.of()`, appeler `jwtUtil.generateToken(user.getEmail(), extraClaims)`, renvoyer `AuthResponse` avec `user.isPasswordResetRequired()`. — dépend T-014, T-015, T-012. — Réf : FR-007, FR-008
- [x] `[T-030]` `[P]` `[P1]` `[US2]` Modifier `RefreshTokenService.refreshAccessToken` : même logique d'émission du claim et du champ que T-029, basé sur l'état DB courant. — dépend T-014, T-015. — Réf : FR-007, FR-008
- [x] `[T-031]` `[P]` `[P1]` `[US2]` Modifier `AcceptInviteService.acceptInvite` : (a) déléguer la création du user à `userOnboardingService.provisionUser` (avec `isAdmin=false, passwordResetRequired=false`), (b) propager `mustResetCredentials=false` dans `AuthResponse`. — dépend T-015, T-018. — Réf : FR-007, RES-001
- [x] `[T-032]` `[P1]` `[US2]` Ajouter `AuthService.firstLoginReset(UUID userId, FirstLoginResetRequest request)` : `@Transactional`, charge user, vérifie `passwordResetRequired == true` en DB (sinon `AccessDeniedException` → 403), **vérifie unicité email si changement via `userRepository.existsByEmail(newEmail)` (sinon `ConflictException` → 409 avec payload `EMAIL_ALREADY_EXISTS`)**, vérifie password non inchangé via `passwordEncoder.matches` (sinon `PasswordUnchangedException` → 400), met à jour email/password/name, clear flag, émet nouveau JWT sans claim + refresh token, log INFO, retourne `AuthResponse` avec `mustResetCredentials=false`. — dépend T-025, T-026. — Réf : FR-010, FR-011, contracts.md §3.2
- [x] `[T-033]` `[P1]` `[US2]` Ajouter dans `AuthController.java` la méthode `firstLoginReset(@AuthenticationPrincipal UUID userId, @Valid @RequestBody FirstLoginResetRequest request)` → `POST /auth/first-login-reset`. — dépend T-032. — Réf : FR-009
- [x] `[T-034]` `[P]` `[P1]` `[US2]` Créer `api/src/test/java/fr/kksdev/budget/api/config/JwtUtilTest.java` : `should_include_extra_claims_when_generating_token`, `should_return_null_when_extracting_absent_claim`, `should_return_claim_value_when_extracting_present_claim`. — dépend T-014. — Réf : FR-008
- [x] `[T-035]` `[P]` `[P1]` `[US2]` Créer `api/src/test/java/fr/kksdev/budget/api/config/PasswordResetRequiredFilterTest.java` : `should_allow_access_when_claim_is_absent`, `should_allow_access_to_allowlisted_path_when_claim_is_true` (test `/auth/first-login-reset` ET `/auth/logout`), `should_return_403_when_claim_is_true_and_path_is_not_allowlisted`. — dépend T-027. — Réf : FR-008, SC-004
- [x] `[T-036]` `[P1]` `[US2]` Créer `api/src/test/java/fr/kksdev/budget/api/controller/AuthControllerFirstLoginResetIT.java` avec `@SpringBootTest + MockMvc` : `should_reset_credentials_and_return_new_jwt_when_all_valid`, `should_return_400_when_password_unchanged` (payload `PASSWORD_UNCHANGED`), `should_return_400_when_email_invalid`, `should_return_403_when_flag_is_already_false`, `should_return_409_when_email_already_used`, `should_block_protected_endpoint_with_old_jwt_and_allow_reset` (SC-004). — dépend T-033. — Réf : FR-009, FR-010, FR-011, SC-004
- [x] `[T-037]` `[P]` `[P1]` `[US2]` Adapter les tests existants de `AuthService.login` / `RefreshTokenService` / `AcceptInviteService` pour vérifier que `AuthResponse.mustResetCredentials` est toujours présent (avec valeurs attendues). — dépend T-029, T-030, T-031. — Réf : FR-007

Frontend Angular :

- [x] `[T-038]` `[P]` `[P1]` `[US2]` Modifier `app/src/app/core/models/auth.model.ts` : ajouter `mustResetCredentials: boolean` dans `AuthResponse`. Modifier `app/src/app/core/models/user.model.ts` : ajouter `mustResetCredentials: boolean` dans `UserInfo`. Créer `FirstLoginResetRequest` interface. — Réf : FR-007, FR-014
- [x] `[T-039]` `[P1]` `[US2]` Modifier `app/src/app/core/services/auth.ts` : (a) computed signal `mustResetCredentials`, (b) `saveAuth` persiste `response.mustResetCredentials` dans `UserInfo` et `localStorage`, (c) `restoreSession` relit le champ, (d) nouvelle méthode `firstLoginReset(payload: FirstLoginResetRequest): Observable<AuthResponse>` qui POST `/auth/first-login-reset` et enchaîne `saveAuth`. — dépend T-038. — Réf : FR-014, FR-015, RES-010
- [x] `[T-040]` `[P]` `[P1]` `[US2]` Créer `app/src/app/core/guards/password-reset.guard.ts` : redirige vers `/first-login-reset` si `authService.mustResetCredentials()` est `true`. — dépend T-039. — Réf : FR-014
- [x] `[T-041]` `[P]` `[P1]` `[US2]` Créer `app/src/app/core/guards/not-password-reset.guard.ts` : redirige vers `/` si `authService.mustResetCredentials()` est `false`. — dépend T-039. — Réf : FR-014
- [x] `[T-042]` `[P1]` `[US2]` Créer `app/src/app/features/auth/first-login-reset/first-login-reset.component.ts` (+ `.html`, `.scss`, `.spec.ts`) : standalone, OnPush, ReactiveForm avec 4 contrôles (email, password, passwordConfirm avec validator d'égalité, displayName), submit → `authService.firstLoginReset(...)` → navigation `/`. — dépend T-039. — Réf : FR-013, FR-015
- [x] `[T-043]` `[P1]` `[US2]` Ajouter la route `/first-login-reset` dans `app/src/app/app.routes.ts` (ou équivalent) avec `canActivate: [authGuard, notPasswordResetGuard]` et `loadComponent` vers `FirstLoginResetComponent`. — dépend T-040, T-041, T-042. — Réf : FR-013
- [x] `[T-044]` `[P1]` `[US2]` Appliquer `passwordResetGuard` sur toutes les routes protégées (après `authGuard`) dans `app.routes.ts`. — dépend T-040. — Réf : FR-014
- [x] `[T-045]` `[P1]` `[US2]` Modifier `LoginComponent` (ou le composant de login existant) : après succès, si `authService.mustResetCredentials()` → `router.navigateByUrl('/first-login-reset')` au lieu de la redirection nominale. — dépend T-039. — Réf : FR-014, FR-015
- [x] `[T-048]` `[P]` `[P1]` `[US2]` Adapter ou ajouter un test dans `login.component.spec.ts` : `should_redirect_to_first_login_reset_when_must_reset_credentials_is_true_after_login` avec mock `AuthService.login` retournant `mustResetCredentials: true`. — dépend T-045. — Réf : FR-014, FR-015
- [x] `[T-049]` `[P]` `[P1]` `[US2]` Ajouter un test ciblé dans `auth.spec.ts` (AuthService Angular) : `should_persist_must_reset_credentials_in_localStorage_after_saveAuth` + `should_restore_must_reset_credentials_from_localStorage_on_restoreSession`. Couvre la persistance du flag critique pour l'idempotence du guard après rechargement de page. — dépend T-039. — Réf : FR-014, RES-010
- [x] `[T-046]` `[P]` `[P1]` `[US2]` Créer `app/src/app/core/guards/password-reset.guard.spec.ts` et `not-password-reset.guard.spec.ts` : tests unitaires `should_redirect_to_first_login_reset_when_flag_true`, `should_allow_when_flag_false`, etc. — dépend T-040, T-041. — Réf : FR-014
- [x] `[T-047]` `[P]` `[P1]` `[US2]` Tests unitaires `first-login-reset.component.spec.ts` : rendu du formulaire, submit nominal avec mock `AuthService`, affichage erreur API, validateur d'égalité password. — dépend T-042. — Réf : FR-013, FR-015

### Phase 3c — US3 (P2) : Redémarrage avant reset

- [x] `[T-050]` `[P2]` `[US3]` Dans `BootstrapSeedRunnerTest`, ajouter les tests : `should_not_seed_when_users_already_exist` (SC-003) et `should_not_regenerate_password_on_restart` (démarre le contexte Spring deux fois, vérifie qu'aucune nouvelle bannière n'est loggée au second démarrage et que le user seul existant reste intact). — dépend T-020. — Réf : FR-005, FR-006, SC-003

### Phase 3d — US4 (P2) : Préservation du rôle admin après reset

- [x] `[T-051]` `[P]` `[P2]` `[US4]` Refactor `api/src/main/java/fr/kksdev/budget/api/config/AdminAuthorizationFilter.java` : remplacer `adminEmailResolver.isAdminEmail(u.getEmail())` par `u.isAdmin()`. Retirer la dépendance `AdminEmailResolver` du constructeur. — dépend T-012. — Réf : FR-012
- [x] `[T-052]` `[P]` `[P2]` `[US4]` Refactor `api/src/main/java/fr/kksdev/budget/api/service/UserService.java` : dans `toResponse`, remplacer `adminEmailResolver.isAdminEmail(...)` par `user.isAdmin()`. Retirer la dépendance `AdminEmailResolver` du constructeur. — dépend T-012. — Réf : FR-012
- [x] `[T-053]` `[P2]` `[US4]` Créer `api/src/main/java/fr/kksdev/budget/api/runner/AdminSyncRunner.java` : `@Component @Order(2) @RequiredArgsConstructor @Slf4j implements ApplicationRunner`, `@Transactional run` qui itère sur `adminEmailResolver.listAdminEmails()`, charge chaque user via `findByEmail`, filtre `!user.isAdmin()`, `setAdmin(true)` + save + log INFO. — dépend T-012. — Réf : FR-012b
- [x] `[T-054]` `[P2]` `[US4]` Créer `api/src/test/java/fr/kksdev/budget/api/runner/AdminSyncRunnerTest.java` avec `@SpringBootTest` : `should_promote_user_when_email_is_in_ADMIN_EMAILS_and_isAdmin_is_false`, `should_not_downgrade_user_when_isAdmin_true_and_email_absent_from_ADMIN_EMAILS` (scénario critique US4), `should_be_idempotent_on_successive_runs`. — dépend T-053. — Réf : FR-012b, US-004, SC-005
- [x] `[T-055]` `[P2]` `[US4]` Adapter les tests d'intégration existants couvrant `/admin/*` (`AdminUserControllerIT`, `InvitationControllerIT`, etc.) pour qu'ils créent désormais les users admin avec `isAdmin=true` en DB (au lieu de dépendre de `ADMIN_EMAILS`). Vérifier non-régression. — dépend T-051, T-052. — Réf : FR-012
- [x] `[T-056]` `[P2]` `[US4]` Test d'intégration bout-en-bout dans `AuthControllerFirstLoginResetIT` : `should_preserve_admin_access_after_reset_to_email_not_in_ADMIN_EMAILS` — seed admin, login, reset vers email absent de `ADMIN_EMAILS`, redémarrage simulé, appel `/admin/users` avec nouveau JWT → 200. — dépend T-053, T-033. — Réf : SC-005

### Phase 3e — US5 (P3) : Seed inopérant si DB peuplée

- [x] `[T-060]` `[P3]` `[US5]` Dans `BootstrapSeedRunnerTest`, ajouter le test `should_not_seed_when_db_contains_kelly_user_migrated_from_KKS_231` (simule une instance pré-existante avec un user ayant `is_admin=true`) → aucun nouveau user créé, aucun log bannière. — dépend T-020. — Réf : FR-005, SC-003

---

## Phase 4 — Polish

- [x] `[T-070]` Mettre à jour `docs/deployment.md` avec la section "Premier démarrage sur instance vierge" : les 5 étapes documentées dans FR-018 (docker compose up -d → récupération bannière → login UI → reset forcé → purge logs optionnelle). Inclure la bannière en exemple et la commande `docker compose logs api | grep -A 5 "FIRST BOOT"`. — Réf : FR-018, SC-001
- [x] `[T-071]` Vérifier manuellement via `git diff develop...HEAD -- flutter/` que la branche `feature/KKS-233` ne contient **aucune modification sous `flutter/`** (conformité FR-016). Consigner dans la PR description. — Réf : FR-016
- [x] `[T-072]` Lancer les tests complets : `cd api && mvn clean install` (doit passer 100%) + `cd app && ng test --watch=false` (doit passer 100%). Corriger toute régression induite par le refactor `AdminAuthorizationFilter` / `UserService.toResponse`. — dépend tous les T-0XX backend + frontend. — Réf : Testabilité (principe V)
- [x] `[T-073]` Test manuel du quickstart.md : exécuter la procédure complète sur une DB PostgreSQL vierge, chronométrer (SC-001 : < 5 min). Consigner le temps dans `review-log.md` pour la phase checklist. — dépend T-072. — Réf : SC-001
- [x] `[T-074]` Pre-commit review via l'agent `pre-commit-review` sur les fichiers staged (code mort, duplication, secrets, console.log, TODO). — Réf : workflow projet
- [x] `[T-075]` Frontend design review via l'agent `frontend-design-review` sur le composant `FirstLoginResetComponent` (cohérence DESIGN.md, tokens SCSS, accessibilité formulaire). — dépend T-042. — Réf : conventions projet

### Checkpoint Phase 4

**Condition de sortie** : tous les tests passent (backend + frontend), la procédure quickstart s'exécute en < 5 min sur DB vierge, aucune modification sous `flutter/`, pre-commit + design review PASS.

---

## Phase 5 — Dependencies & Execution Order

### Graphe de dépendances (DAG simplifié)

```
T-001 ──▶ T-002
             │
             ▼
┌────────── Phase 2 Fondations ──────────┐
│ T-010 ──┐                              │
│ T-011 ──┴──▶ T-012 ──▶ T-015 ──┐       │
│                        │        │       │
│ T-013 ──┐              │        │       │
│ T-014 ──┴──────────────┤        │       │
│                        ▼        ▼       │
│ T-016 ──┐              T-018────┤       │
│ T-017 ──┘                        │       │
└──────────────────────────────────┼──────┘
                                   │
                   ┌───────────────┼───────────────────┐
                   ▼               ▼                   ▼
              US1 (P1)        US2 (P1)           US4 (P2)
              T-020 ◀─T-013,                    T-051, T-052 ◀─T-012
                     T-016,                    T-053 ◀─T-012
                     T-018                     T-054 ◀─T-053
              T-021                             T-055 ◀─T-051, T-052
              T-022                             T-056 ◀─T-053, T-033
              T-023 ◀─T-020
              T-024 ◀─T-020

              US2 backend                       US3 (P2)
              T-025, T-026   [P]                T-050 ◀─T-020
              T-027 ◀─T-014
              T-028 ◀─T-027                     US5 (P3)
              T-029 ◀─T-014, T-015, T-012       T-060 ◀─T-020
              T-030 ◀─T-015, T-014 [P]
              T-031 ◀─T-015, T-018 [P]
              T-032 ◀─T-025, T-026
              T-033 ◀─T-032
              T-034 ◀─T-014 [P]
              T-035 ◀─T-027 [P]
              T-036 ◀─T-033
              T-037 ◀─T-029, T-030, T-031 [P]

              US2 frontend
              T-038 [P]
              T-039 ◀─T-038
              T-040 ◀─T-039 [P]
              T-041 ◀─T-039 [P]
              T-042 ◀─T-039
              T-043 ◀─T-040, T-041, T-042
              T-044 ◀─T-040
              T-045 ◀─T-039
              T-046 ◀─T-040, T-041 [P]
              T-047 ◀─T-042 [P]

         ┌────── Phase 4 Polish ─────────┐
         │ T-070                          │
         │ T-071                          │
         │ T-072 ◀─ toutes                │
         │ T-073 ◀─ T-072                 │
         │ T-074                          │
         │ T-075 ◀─ T-042                 │
         └────────────────────────────────┘
```

### US Dependencies

| User Story | Tâches | Dépend de (fondations) |
|-----------|--------|------------------------|
| US1 — Premier démarrage sur DB vide (P1) | T-020, T-021, T-022, T-023, T-024 | T-013, T-016, T-017, T-018 |
| US2 — Reset forcé (P1) | T-025 à T-047 | T-012, T-014, T-015, T-018 |
| US3 — Redémarrage avant reset (P2) | T-050 | T-020 |
| US4 — Préservation rôle admin (P2) | T-051, T-052, T-053, T-054, T-055, T-056 | T-012, T-033 (pour T-056) |
| US5 — Seed inopérant DB peuplée (P3) | T-060 | T-020 |

### Parallel Opportunities

**Groupe A — Fondations parallélisables** (après T-012 disponible) :
- T-013 (PasswordGenerator), T-014 (JwtUtil), T-015 (AuthResponse), T-016 (BootstrapProperties), T-017 (yaml)
- Tous `[P]`, exécutables par un même ou plusieurs devs en parallèle.

**Groupe B — Backend US2 parallélisable** (après T-014 et T-015) :
- T-025 (DTO), T-026 (Exception), T-030 (RefreshToken), T-031 (AcceptInvite), T-034 (JwtUtil tests), T-035 (Filter tests) — tous `[P]`.

**Groupe C — Frontend US2 parallélisable** (après T-039) :
- T-040 (guard), T-041 (guard), T-046 (tests guards), T-047 (tests component) — tous `[P]`.

**Groupe D — Refactor admin + tests parallélisables** :
- T-051 (AdminAuthorizationFilter), T-052 (UserService.toResponse) — indépendants, `[P]`.

**Groupe E — Tests de seed complémentaires** (après T-020) :
- T-023, T-024, T-050, T-060 — tous lisent le même runner mais testent des scénarios distincts, exécutables en parallèle sur des instances de test séparées.

**Groupe F — Polish final** :
- T-070 (doc), T-071 (diff Flutter), T-074 (pre-commit review) indépendants.

### Execution Order recommandé (single developer)

1. **Setup** : T-001, T-002.
2. **Fondations** (sérialisé naturellement) : T-010 & T-011 en parallèle, puis T-012. Ensuite **Groupe A** (T-013, T-014, T-016, T-017) en parallèle, puis T-015 et T-018.
3. **US1** (petit, par feature) : T-020, puis T-021, T-022, T-023, T-024 en parallèle.
4. **US2 backend** : T-025, T-026 en parallèle ; puis T-027 → T-028 ; puis T-029 ; T-030, T-031, T-034, T-035 en parallèle ; T-032 → T-033 ; T-036, T-037 en parallèle.
5. **US2 frontend** : T-038 ; T-039 ; T-040, T-041, T-042 (composant en parallèle) ; T-043 ; T-044, T-045 ; T-046, T-047 en parallèle.
6. **US4** (peut être démarré en parallèle de US2 backend) : T-051, T-052 en parallèle ; T-053 ; T-054 ; T-055 ; T-056 (dépend de T-033).
7. **US3 / US5** : T-050, T-060 (tests additionnels dans `BootstrapSeedRunnerTest`).
8. **Polish** : T-070 ; T-071 ; T-072 ; T-073 ; T-074 ; T-075.

---

## Implementation Strategy

### MVP First (livraison minimale fonctionnelle)

Le **MVP livrable** de ce ticket correspond à US1 + US2 ensemble :

- US1 (seed + bannière) **sans** US2 = compte créé inaccessible → inutile.
- US2 (reset endpoint + UI) **sans** US1 = endpoint existant mais jamais déclenché → inutile.

Les deux P1 doivent être livrées **en un seul incrément minimal** pour qu'un self-hoster puisse exécuter `docker compose up -d` + reset et accéder à l'app. Toutes les tâches T-020 à T-047 font partie du MVP.

US4 (préservation rôle admin) est techniquement dépendante du MVP : sans elle, le self-hoster perd son accès admin après reset → UX cassée. Elle doit donc accompagner les P1 dans la première livraison bien que classée P2.

### Incremental Delivery

Ordre de livraison (commits ou PRs successives au sein de la même branche) :

**Livraison 1 (fondations)** : T-001 à T-018.
- Valeur : la base technique est en place (migrations appliquées, services et utilitaires créés) mais aucun comportement visible ajouté.
- Test : `mvn test` passe, aucune régression.

**Livraison 2 (seed MVP — US1 + US4 partielle)** : T-020, T-021, T-022, T-023, T-024, T-050, T-051, T-052, T-053, T-054, T-055.
- Valeur : le bootstrap fonctionne en backend pur. Le refactor admin en DB est terminé. Un self-hoster qui exécute `docker compose up -d` voit la bannière et peut appeler l'endpoint (même sans UI) via curl.
- Test : tests d'intégration backend verts.

**Livraison 3 (reset endpoint — US2 backend)** : T-025 à T-037, T-056, T-060.
- Valeur : l'endpoint `POST /auth/first-login-reset` est exploitable via curl/Postman. Un self-hoster technique peut compléter son bootstrap.
- Test : `AuthControllerFirstLoginResetIT` passe.

**Livraison 4 (reset UI — US2 frontend)** : T-038 à T-047.
- Valeur : UX complète côté Angular. Le self-hoster n'a plus besoin de taper de curl. Promesse "docker compose up -d et c'est parti" tenue.
- Test : `ng test` passe.

**Livraison 5 (polish et doc)** : T-070, T-071, T-072, T-073, T-074, T-075.
- Valeur : documentation déploiement à jour, quickstart validé, reviews passées.
- Test : chronométrage SC-001 < 5 min confirmé.

---

## Requirements → Tasks mapping

| Requirement | Tâches couvrantes |
|-------------|-------------------|
| FR-001 (détection DB vide) | T-020 |
| FR-002 (seed user) | T-011, T-012, T-013, T-020 |
| FR-003 (Account + Preferences seed) | T-018, T-020 |
| FR-004 (log bannière WARN) | T-020 |
| FR-005 (pas de seed si DB non vide) | T-020, T-050, T-060 |
| FR-006 (pas de régénération) | T-020, T-050 |
| FR-007 (réponse login enrichie) | T-015, T-029, T-030, T-031, T-037, T-038 |
| FR-008 (JWT claim + gate) | T-014, T-027, T-028, T-029, T-030, T-034, T-035 |
| FR-009 (endpoint first-login-reset) | T-025, T-033 |
| FR-010 (logique reset + atomique) | T-032, T-033, T-036 |
| FR-011 (refus password identique) | T-026, T-032, T-036 |
| FR-012 (refactor admin DB) | T-010, T-012, T-051, T-052 |
| FR-012a (migration Flyway ALTER) | T-010 |
| FR-012b (synchroniseur démarrage) | T-053, T-054 |
| FR-013 (UI `/first-login-reset`) | T-042, T-043, T-047 |
| FR-014 (router guard Angular) | T-040, T-041, T-043, T-044, T-045, T-046, T-048, T-049 |
| FR-015 (redirection post-reset) | T-039, T-042, T-045, T-048 |
| FR-016 (pas de modif Flutter) | T-071 |
| FR-017 (fail-fast BOOTSTRAP_EMAIL invalide) | T-016, T-017, T-022 |
| FR-018 (mise à jour deployment.md) | T-070 |
| SC-001 (5 min parcours) | T-070, T-073 |
| SC-002 (seed nominal) | T-023 |
| SC-003 (pas de seed si DB peuplée) | T-050, T-060 |
| SC-004 (403 sur endpoints protégés) | T-035, T-036 |
| SC-005 (préservation admin reset) | T-054, T-056 |
| SC-006 (zéro config obligatoire) | T-017, T-024 |
| SC-007 (password 32 chars alphanum) | T-021 |

---

## Résumé tâches

| Phase | Total | P1 | P2 | P3 | Parallélisables |
|-------|-------|----|----|----|-----------------|
| 1 — Setup | 2 | — | — | — | — |
| 2 — Fondations | 9 | — | — | — | 5 |
| 3a — US1 (P1) | 5 | 5 | — | — | 3 |
| 3b — US2 (P1) | 25 | 25 | — | — | 12 |
| 3c — US3 (P2) | 1 | — | 1 | — | — |
| 3d — US4 (P2) | 6 | — | 6 | — | 2 |
| 3e — US5 (P3) | 1 | — | — | 1 | — |
| 4 — Polish | 6 | — | — | — | 2 |
| **Total** | **55** | **30** | **7** | **1** | **24** |

*(Les 17 tâches restantes sont en Phase 1, 2 ou 4, non taggées US.)*
