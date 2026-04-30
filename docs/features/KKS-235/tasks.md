# Tasks — KKS-235 : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

> Date : 2026-04-30
> Issue : KKS-235
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)
> Contracts : [contracts.md](./contracts.md)
> Data Model : [data-model.md](./data-model.md)
> Research : [research.md](./research.md)

---

## Phase 1 : Setup

- [x] [T-001] Vérifier branche `feature/KKS-235` active et workspace propre — Réf: setup
- [x] [T-002] [P] Ajouter dépendance `net.coobird:thumbnailator:0.4.20` dans `api/pom.xml` — Réf: RES-001 / NFR-006
- [x] [T-003] [P] Ajouter dépendance `flutter_image_compress: ^2.x` dans `flutter/pubspec.yaml` — Réf: RES-012 / CX-002
- [x] [T-004] Configurer `api/src/main/resources/application.yaml` : `app.storage.avatars.path: ${AVATAR_STORAGE_PATH:./data/avatars}` + vérifier multipart limits ≥ 2 MB — Réf: NFR-008 / RES-003
- [x] [T-005] Lancer audit pré-implémentation des tests existants `BudgetServiceTest` et `BudgetSnapshotServiceTest` — Réf: R-001 (mitigation risque migrations CASCADE) — VERTS
- [x] [T-006] [P] Vérifier que `cd api && mvn clean compile` passe (avec Thumbnailator) — Réf: setup
- [x] [T-007] [P] Vérifier que `cd app && ng lint` passe (sans nouvelle dépendance) — Réf: setup — 2 erreurs préexistantes KKS-233 corrigées en passant
- [x] [T-008] [P] Vérifier que `cd flutter && flutter pub get && flutter analyze` passe — Réf: setup

**Checkpoint** : Les 3 stacks compilent sans warning, tests budget existants verts (filet de sécurité avant migrations CASCADE), branche feature active.

---

## Phase 2 : Fondations (bloquantes)

> Toutes ces tâches doivent être terminées avant d'attaquer les User Stories.

- [x] [T-010] [P1] Créer migration `V32__add_user_avatar_path.sql` (ALTER TABLE users ADD COLUMN avatar_path VARCHAR(512) NULL) — Réf: MIG-002
- [x] [T-011] [P1] [P] Créer migration `V33__patch_budgets_user_fk_cascade.sql` (DROP/ADD FK avec ON DELETE CASCADE) — Réf: MIG-003 / R-001
- [x] [T-012] [P1] [P] Créer migration `V34__patch_budget_snapshots_user_fk_cascade.sql` (DROP/ADD FK avec ON DELETE CASCADE) — Réf: MIG-004 / R-001
- [x] [T-013] [P1] [P] Créer migration `V35__patch_refresh_tokens_user_fk_cascade.sql` (no-op documentaire — `refresh_tokens.user_id` avait déjà CASCADE depuis V6) — Réf: RES-008
- [x] [T-014] [P1] Étendre `User.java` : ajout `@Column(name = "avatar_path", length = 512) String avatarPath` — Réf: data-model.md User
- [x] [T-015] [P1] Étendre `UserRepository.java` : ajout `Optional<User> findByEmailAndDisabledAtIsNull(String email)` + `long countActiveAdmins()` — Réf: FR-020, FR-021, RES-005
- [x] [T-016] [P1] Modifier `AuthService.login()` pour utiliser `findByEmailAndDisabledAtIsNull` — Réf: FR-020
- [x] [T-017] [P1] Modifier `JwtFilter.doFilterInternal()` pour utiliser `findByEmailAndDisabledAtIsNull` — Réf: FR-020 / RES-005 — `StompAuthInterceptor` aussi mis à jour pour cohérence sécurité
- [x] [T-018] [P1] [P] Créer `config/StorageProperties.java` (`@ConfigurationProperties(prefix = "app.storage")` avec sous-record `Avatars(String path)`) — Réf: NFR-008 / RES-003
- [x] [T-019] [P1] [P] Créer `util/ImageMimeValidator.java` (validation magic numbers JPEG `FF D8 FF` et PNG `89 50 4E 47 0D 0A 1A 0A`) + tests unitaires — Réf: NFR-002 / RES-002

**Checkpoint** : Backend démarre avec les 4 nouvelles migrations appliquées (V32-V35), tests d'intégration login filtrent disabled_at, `StorageProperties` injecté.

---

## Phase 3 : User Stories (par priorité)

### P1 — Critiques

#### US-001 — Page Mon compte accessible et déconnexion fonctionnelle

> Couvre FR-001, FR-002, FR-012, FR-013, NFR-001, NFR-005, NFR-009, SC-001, SC-002, SC-011

- [x] [T-020] [P] [P1] [US1] Créer route lazy-loaded `/settings/account` dans `app/src/app/features/settings/settings.routes.ts` — Réf: FR-001
- [x] [T-021] [P] [P1] [US1] Créer skeleton `MonCompteComponent` (HTML/SCSS standalone OnPush signals-first) avec 4 sections vides — Réf: FR-002
- [x] [T-022] [P1] [US1] Modifier `app/src/app/features/settings/settings.html` : ajouter ligne "Mon compte" → chevron vers `/settings/account` ; **retirer le bouton Déconnexion existant** (déplacé dans Mon compte) — Réf: FR-012 (bug fix)
- [x] [T-023] [P1] [US1] Brancher handler `logout()` dans `MonCompteComponent` (appel `authService.logout()` + `router.navigate(['/login'])` + résilience si `/auth/logout` échoue) — Réf: FR-012, FR-013
- [x] [T-024] [P] [P1] [US1] Ajouter row "Déconnexion" dans `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` section "Zone de danger" — Réf: FR-012, NFR-005
- [x] [T-025] [P1] [US1] Test E2E Angular ciblé : login → settings → account → logout → redirect login (vérification SC-001, SC-011) — Réf: SC-001, SC-011
- [x] [T-026] [P] [P1] [US1] Documenter scénarios manuels US-001 dans `docs/manual-test-plan.md` — Réf: SC-001

#### US-002 — Modifier identité (nom + avatar)

> Couvre FR-003, FR-004, FR-005, FR-006, FR-007, NFR-002, NFR-006, NFR-008, SC-003, SC-004

- [x] [T-027] [P] [P1] [US2] Renommer `dto/request/UpdateUserRequest.java` → `UpdateProfileRequest.java` + ajouter commentaire de garde "Self-service profile fields ONLY. Email is admin-managed (cf. KKS-235 §FR-007)" — Réf: FR-003, FR-007, RES-007, I-001
- [x] [T-028] [P1] [US2] Adapter callsites de `UpdateProfileRequest` dans `UserController` et tests — Réf: FR-003 (dépend de T-027)
- [x] [T-029] [P] [P1] [US2] Créer DTO `dto/response/AvatarMetadataResponse.java` — Réf: contracts.md
- [x] [T-030] [P1] [US2] Créer `service/AvatarStorageService.java` : méthodes `store`, `read`, `delete`, `computeEtag` + `@PostConstruct` création dossier — Réf: FR-004, FR-005, FR-006, NFR-002, NFR-006, NFR-008, FR-022 (logs INFO)
- [x] [T-031] [P1] [US2] Ajouter endpoint `POST /api/users/me/avatar` dans `UserController` (multipart, validation MIME, redim Thumbnailator, stocker path, return AvatarMetadataResponse) — Réf: FR-004
- [x] [T-032] [P1] [US2] Ajouter endpoint `GET /api/users/me/avatar` dans `UserController` (lecture binaire + ETag SHA-256 + If-None-Match → 304) — Réf: FR-005, RES-004
- [x] [T-033] [P1] [US2] Ajouter endpoint `DELETE /api/users/me/avatar` dans `UserController` — Réf: FR-006
- [x] [T-034] [P1] [US2] Tests d'intégration avatar : `should_upload_avatar_when_valid_jpg`, `should_reject_when_invalid_mime`, `should_reject_when_file_too_large`, `should_serve_avatar_with_etag`, `should_return_304_when_etag_matches`, `should_delete_avatar_when_authenticated` — Réf: SC-004
- [x] [T-035] [P1] [US2] Tests unitaires `AvatarStorageService` (toutes orientations EXIF couvertes) + `ImageMimeValidator` (JPG, PNG, GIF rejeté, fichier maquillé rejeté) — Réf: R-003, NFR-002
- [x] [T-036] [P] [P1] [US2] Créer composant `lib/avatar-upload/avatar-upload.component.{ts,html,scss}` (signals-first, inputs `currentAvatarUrl`/`userInitials`, outputs `upload`/`delete`/`validationError`) — Réf: FR-004, FR-006, RES-010
- [x] [T-037] [P] [P1] [US2] Créer `core/services/avatar.service.ts` (méthodes `upload`, `delete`, `getUrl` + signals `avatarUrl`/`etag`) — Réf: FR-004, FR-005, FR-006
- [x] [T-038] [P1] [US2] Implémenter section Identité dans `MonCompteComponent` (intégration `<app-avatar-upload>` + champ nom inline éditable + champ email read-only avec mention "Géré par l'admin") — Réf: FR-003, FR-007 (dépend T-021, T-036, T-037)
- [x] [T-039] [P] [P1] [US2] Créer widget Flutter `flutter/lib/src/features/user_profile/presentation/widgets/avatar_picker.dart` (image_picker → flutter_image_compress → Dio upload) — Réf: FR-004, RES-012
- [x] [T-040] [P1] [US2] Étendre `ProfileSettingsScreen` Flutter section Identité + étendre `UserProfileRepositoryRemote` avec `uploadAvatar`/`deleteAvatar` — Réf: FR-003, FR-004, FR-006, NFR-005

#### US-003 — Changer son mot de passe

> Couvre FR-008, FR-009, FR-010, FR-011, FR-023, FR-024, FR-025, SC-005, SC-006, W-002

- [x] [T-041] [P] [P1] [US3] Créer DTO `dto/request/ChangePasswordRequest.java` (`@NotBlank currentPassword` + `@NotBlank @Size(min=12, max=100) newPassword`) — Réf: FR-008, FR-010
- [x] [T-042] [P] [P1] [US3] Modifier `dto/request/FirstLoginResetRequest.java` : passer `@Size(min=8)` à `@Size(min=12)` — Réf: FR-011
- [x] [T-043] [P1] [US3] Créer `service/UserPasswordService.java` avec méthode `changePassword(User, ChangePasswordRequest)` : BCrypt verify currentPassword → reject si identique → hash + persist → revoke refresh tokens → générer nouveau JWT + refresh + log INFO — Réf: FR-008, FR-009, FR-010, FR-022, FR-023, FR-024
- [x] [T-044] [P1] [US3] Ajouter endpoint `POST /api/users/me/password` dans `UserController` retournant `AuthResponse` — Réf: FR-008, FR-024
- [x] [T-045] [P1] [US3] Tests d'intégration change-password : `should_change_password_when_valid`, `should_reject_when_current_incorrect`, `should_reject_when_new_too_short`, `should_reject_when_new_equals_current`, `should_revoke_all_refresh_tokens_when_password_changed`, `should_return_new_jwt_when_password_changed`, `should_invalidate_old_refresh_token_after_change` — Réf: SC-005, SC-006, **W-002 du review-spec** (couverture nouveau JWT)
- [x] [T-046] [P] [P1] [US3] Créer `features/settings/account/change-password-dialog.component.ts` (form 3 champs + validation client min 12 + match) — Réf: FR-008
- [x] [T-047] [P1] [US3] Étendre `core/services/user.service.ts` avec `changePassword(req)` + appel mise à jour state Auth (nouveau JWT/refresh) — Réf: FR-008, FR-024 (dépend T-046)
- [x] [T-048] [P] [P1] [US3] Créer `flutter/lib/src/features/user_profile/presentation/widgets/change_password_sheet.dart` (bottom sheet) — Réf: FR-008
- [x] [T-049] [P1] [US3] Étendre `UserProfileRepositoryRemote` Flutter avec `changePassword(req)` + Notifier auth update — Réf: FR-008, NFR-005

### P2 — Importantes

#### US-004 — Exporter ses données (JSON + CSV)

> Couvre FR-014, FR-015, FR-016, FR-017, FR-017a, NFR-004, SC-007, SC-008, W-003 (perf JSON), R-007 (no password leak), I-004 (inclure invitations)

- [x] [T-050] [P] [P2] [US4] Créer DTOs `dto/response/UserExportResponse.java` (record top-level avec `schemaVersion`, `exportedAt`, et tous les sous-DTOs) — Réf: FR-016, FR-017a, contracts.md, R-007 (DTO `UserDto` SANS password)
- [x] [T-051] [P2] [US4] Créer `service/UserExportService.java` méthode `exportJson(User) → UserExportResponse` (charge toutes entités via repositories existants, INCLUT `invitations` — résout I-004) — Réf: FR-014, FR-016, I-004
- [x] [T-052] [P2] [US4] Créer méthode `UserExportService.exportCsv(User, OutputStream)` (CSVPrinter + BOM UTF-8 + traduction Type français + streaming) — Réf: FR-015, FR-017
- [x] [T-053] [P] [P2] [US4] Ajouter endpoint `GET /api/users/me/export?format=json` dans `UserController` (Content-Disposition attachment) — Réf: FR-014
- [x] [T-054] [P] [P2] [US4] Ajouter endpoint `GET /api/users/me/export?format=csv` dans `UserController` (StreamingResponseBody) — Réf: FR-015
- [x] [T-055] [P2] [US4] Tests d'intégration export : `should_export_all_user_entities_when_format_json`, `should_export_transactions_only_when_format_csv`, `should_translate_transaction_type_in_csv`, `should_include_utf8_bom_in_csv`, `should_not_expose_password_hash_in_export`, `should_include_invitations_in_export` — Réf: SC-007, R-007, I-004
- [x] [T-056] [P] [P2] [US4] Créer `core/services/user-export.service.ts` Angular (méthodes `exportJson`/`exportCsv` avec déclenchement download via blob URL) + intégrer boutons dans MonCompte section Données — Réf: FR-014, FR-015 (dépend T-021)
- [x] [T-057] [P] [P2] [US4] Étendre `UserProfileRepositoryRemote` Flutter avec `exportJson`/`exportCsv` + intégrer boutons dans `ProfileSettingsScreen` section Données + sauvegarde locale via `path_provider`/`share_plus` — Réf: FR-014, FR-015, NFR-005
- [x] [T-058] [P2] [US4] Test de charge dédié export JSON sur 10 000 transactions (vérification SC-008 perf < 5 s) **et** SC additionnel ajouté pour export JSON ; documentation des résultats dans `docs/manual-test-plan.md` — Réf: NFR-004, SC-008, **W-003 du review-spec** (perf JSON)

### P3 — Nice to have

#### US-005 — Supprimer son compte (soft-delete)

> Couvre FR-018, FR-019, FR-020, FR-021, FR-022, SC-009, SC-010, W-004 (admin non-seul peut se supprimer)

- [x] [T-059] [P] [P3] [US5] Créer DTO `dto/request/DeleteAccountRequest.java` (`@NotBlank currentPassword` + `@AssertTrue boolean confirmed`) — Réf: FR-018
- [x] [T-060] [P3] [US5] Créer `service/UserDeletionService.java` méthode `softDelete(User, DeleteAccountRequest)` : check confirmed → BCrypt verify → check `countActiveAdmins() > 1` si admin → set `disabledAt = now()` → `revokeAllUserTokens` → log INFO — Réf: FR-018, FR-019, FR-020, FR-021, FR-022
- [x] [T-061] [P3] [US5] Ajouter endpoint `DELETE /api/users/me` dans `UserController` retournant 204 — Réf: FR-018
- [x] [T-062] [P3] [US5] Tests d'intégration soft-delete : `should_soft_delete_user_when_password_correct`, `should_reject_when_password_incorrect`, `should_reject_when_confirmed_false`, `should_reject_when_last_admin`, `should_succeed_when_admin_not_alone`, `should_block_login_after_soft_delete`, `should_revoke_all_refresh_tokens_on_soft_delete`, `should_keep_user_data_after_soft_delete` — Réf: SC-009, SC-010, **W-004 du review-spec** (admin non-seul OK)
- [x] [T-063] [P] [P3] [US5] Créer `features/settings/account/delete-account-confirm-dialog.component.ts` (form MDP + checkbox + bouton désactivé conditionnellement) — Réf: FR-018
- [x] [T-064] [P3] [US5] Étendre `core/services/user.service.ts` avec `deleteAccount(req)` + `authService.logout()` + redirect `/login` après succès — Réf: FR-018 (dépend T-063)
- [x] [T-065] [P] [P3] [US5] Créer `flutter/.../delete_account_sheet.dart` bottom sheet (parité Angular) — Réf: FR-018, NFR-005
- [x] [T-066] [P3] [US5] Étendre `UserProfileRepositoryRemote` Flutter avec `deleteAccount(req)` + redirection après succès — Réf: FR-018, NFR-005
- [x] [T-067] [P3] [US5] Test E2E suppression compte (Angular + Flutter) : confirmation → déconnexion → tentative login échoue — Réf: SC-009

**Checkpoint** : Tous les FR-001 à FR-025 ont au moins une tâche couverte. Tests d'intégration backend passent (nominal + erreurs). Tests E2E par US passent.

---

## Phase 4 : Polish

- [x] [T-068] [P2] Implémenter mode offline page Mon compte côté Flutter (server-only via `FutureProvider`, widget `_OfflineState` quand `connectivityProvider.isOffline`) — Réf: NFR-005, RES-013, I-005
- [x] [T-069] [P2] [P] Mettre à jour `docs/api-examples.md` avec les 7 endpoints (request/response complets + scénarios erreurs) — Réf: DoD spec
- [x] [T-070] [P2] [P] Mettre à jour `docs/api-errors.md` avec les 11 nouveaux codes d'erreur (`INVALID_IMAGE_FORMAT`, `FILE_TOO_LARGE`, `STORAGE_ERROR`, `AVATAR_NOT_FOUND`, `PASSWORD_INCORRECT`, `PASSWORD_UNCHANGED`, `CONFIRMATION_REQUIRED`, `LAST_ADMIN_DELETION_FORBIDDEN`, `INVALID_EXPORT_FORMAT`) — Réf: DoD spec, contracts.md
- [x] [T-071] [P2] [P] Mettre à jour `docs/deployment.md` : variable d'env `AVATAR_STORAGE_PATH`, recommandations backup, permissions disque, monitoring espace — Réf: NFR-008, R-004
- [x] [T-072] [P3] [P] Mettre à jour `docs/manual-test-plan.md` avec scénarios complets Mon compte (4 sections × 5 US) — Réf: DoD spec
- [x] [T-073] [P2] [P] Lint + format Angular : `cd app && ng lint && npm run format` — Réf: DoD spec
- [x] [T-074] [P2] [P] Analyse statique Flutter : `cd flutter && flutter analyze` — Réf: DoD spec
- [x] [T-075] [P2] Test perf séparé upload+redim avatar vs service : ajouter SC-015 (upload+redim < 2s pour 2 MB) et SC-016 (service avatar avec ETag < 200 ms) dans `manual-test-plan.md` — Réf: NFR-006, **W-005 du review-spec** (séparation SC)
- [x] [T-076] [P1] Audit final agent `pre-commit-review` (code mort, duplication, secrets) avant commit — Réf: workflow CLAUDE.md
- [x] [T-077] [P1] Audit final agent `frontend-design-review` (cohérence DESIGN.md, tokens, patterns) — Réf: NFR-009, workflow CLAUDE.md
- [x] [T-078] [P2] Refactoring final si l'agent pre-commit identifie de la duplication (limité à la zone touchée) — Réf: workflow CLAUDE.md

**Checkpoint** : Lint + analyze passent sans warning. Tests backend (`mvn test`) + Angular (`ng test`) + Flutter (`flutter test`) verts. Documentation à jour. Pas de `console.log`/`System.out.println` résiduels. Audits agents PASS.

---

## Phase 5 : Dependencies & Execution Order

### Graphe de dépendances (vue macro)

```
Phase 1 Setup (T-001 à T-008)
   │
   ▼
Phase 2 Fondations
   ├── T-010 (V32) ──┐
   ├── T-011 (V33) [P]│
   ├── T-012 (V34) [P]│  Migrations en parallèle, app redémarre une fois
   ├── T-013 (V35) [P]│
   ├── T-014 (User entity) ──┤ après migrations
   ├── T-015 (Repository) ───┤ après T-014
   ├── T-016 (AuthService) ──┤ après T-015
   ├── T-017 (JwtFilter) ────┤ après T-015
   ├── T-018 (StorageProperties) [P]
   └── T-019 (ImageMimeValidator) [P]
   │
   ▼
Phase 3 User Stories (par priorité)
   │
   ├── US-001 (P1) — T-020 à T-026
   │      T-020 [P]
   │      T-021 [P]      ┐
   │      T-022          ├── peuvent démarrer en parallèle
   │      T-023 (dépend T-021, T-022)
   │      T-024 [P]
   │      T-025 (dépend T-023)
   │      T-026 [P]
   │
   ├── US-002 (P1) — T-027 à T-040
   │      T-027 [P] (renommage)
   │      T-028 (dépend T-027)
   │      T-029 [P]
   │      T-030 (dépend T-018, T-019)
   │      T-031 → T-032 → T-033 (séquentiels, même controller)
   │      T-034 (dépend T-031/032/033)
   │      T-035 [P] (tests unitaires en parallèle des intégration)
   │      T-036 [P], T-037 [P], T-039 [P]
   │      T-038 (dépend T-036, T-037)
   │      T-040 (dépend T-039)
   │
   ├── US-003 (P1) — T-041 à T-049
   │      T-041 [P], T-042 [P]
   │      T-043 (dépend T-041)
   │      T-044 (dépend T-043)
   │      T-045 (dépend T-043, T-044)
   │      T-046 [P], T-048 [P]
   │      T-047 (dépend T-046)
   │      T-049 (dépend T-048)
   │
   ├── US-004 (P2) — T-050 à T-058
   │      T-050 [P]
   │      T-051 (dépend T-050)
   │      T-052 (dépend T-050)
   │      T-053 [P] (dépend T-051)
   │      T-054 [P] (dépend T-052)
   │      T-055 (dépend T-053, T-054)
   │      T-056 [P] (dépend T-053)
   │      T-057 [P] (dépend T-054)
   │      T-058 (dépend T-053, T-054)
   │
   └── US-005 (P3) — T-059 à T-067
          T-059 [P]
          T-060 (dépend T-059)
          T-061 (dépend T-060)
          T-062 (dépend T-061)
          T-063 [P], T-065 [P]
          T-064 (dépend T-063)
          T-066 (dépend T-065)
          T-067 (dépend T-064, T-066)
   │
   ▼
Phase 4 Polish (T-068 à T-078)
   │
   ▼
Done
```

### US Dependencies

| User Story | Priorité | Tâches | Dépend de |
|---|---|---|---|
| **US-001** (Page + logout) | P1 | T-020 à T-026 | Phase 2 (T-010, T-014, T-015, T-016, T-017) |
| **US-002** (Identité) | P1 | T-027 à T-040 | T-010, T-014, T-018, T-019 (Phase 2) |
| **US-003** (Change password) | P1 | T-041 à T-049 | T-014, T-015 (Phase 2) + T-013 (V35 cascade refresh tokens) |
| **US-004** (Export) | P2 | T-050 à T-058 | T-014 + entités existantes en DB |
| **US-005** (Suppression) | P3 | T-059 à T-067 | T-010, T-014, T-015 (countActiveAdmins) + V29 disabled_at |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition / Pré-requis |
|---|---|---|
| **G1 (Setup)** | T-002, T-003, T-006, T-007, T-008 | T-001 (branche prête) |
| **G2 (Migrations)** | T-011, T-012, T-013 | T-010 démarré (cohérence numérotation, ordre Flyway) |
| **G3 (Fondations utilitaires)** | T-018, T-019 | T-001 (indépendantes des autres tâches) |
| **G4 (US-001 UI)** | T-020, T-021, T-024, T-026 | T-014 + T-017 (Phase 2) |
| **G5 (US-002 DTO + tests)** | T-027, T-029, T-035 (tests unitaires) | T-001 + T-018/019 |
| **G6 (US-002 Frontend)** | T-036, T-037, T-039 | T-027 |
| **G7 (US-003 DTOs)** | T-041, T-042 | T-001 |
| **G8 (US-003 UI)** | T-046, T-048 | T-044 livré côté backend |
| **G9 (US-004 endpoints)** | T-053, T-054 | T-051 et T-052 livrés |
| **G10 (US-004 UI)** | T-056, T-057 | T-053 + T-054 livrés |
| **G11 (US-005 UI)** | T-063, T-065 | T-061 livré |
| **G12 (Doc Polish)** | T-069, T-070, T-071, T-072, T-073, T-074 | Phase 3 complète |

### Tâches inter-US parallélisables

Les **3 US P1** (US-001, US-002, US-003) sont théoriquement parallélisables après la Phase 2 :
- Si 3 développeurs/agents disponibles : possible de faire les 3 US en parallèle (chaque US a son scope backend + frontend isolé).
- En pratique avec 1 agent par stack : recommandation séquentielle US-001 → US-002 → US-003 pour limiter les conflits sur `MonCompteComponent` et `UserController`.

---

## Implementation Strategy

### MVP First

Le **MVP** = US-001 + US-002 + US-003 (les 3 user stories P1) qui adressent :
- ✅ Page Mon compte fonctionnelle (entry point)
- ✅ Bouton déconnexion fixé (bug critique éliminé)
- ✅ Modification identité (nom + avatar)
- ✅ Sécurité de base (changement de mot de passe)

**Tâches MVP** : T-001 → T-049 (~ 50 tâches sur 78). C'est le **livrable minimum déployable**.

**Itération 2** (P2) : ajouter l'export de données (US-004, T-050 → T-058).

**Itération 3** (P3) : ajouter la suppression de compte (US-005, T-059 → T-067) + Polish.

### Incremental Delivery

| Livraison | Tâches | Valeur délivrée | Statut Linear |
|-----------|--------|-----------------|---|
| **L1 — Setup + Fondations** | T-001 à T-019 | Migrations DB en place + soft-delete actif côté auth (login bloqué si disabled_at) | "In Progress" |
| **L2 — MVP (3 US P1)** | T-020 à T-049 | Page Mon compte fonctionnelle, bug logout fixé, change-password opérationnel | "In Review" |
| **L3 — Export** | T-050 à T-058 | Export JSON + CSV transactions opérationnels, conformité RGPD améliorée | "In Review" |
| **L4 — Suppression compte** | T-059 à T-067 | Soft-delete avec garde dernier admin actif | "In Review" |
| **L5 — Polish + Docs** | T-068 à T-078 | Mode offline Flutter, docs API + deployment à jour, audits agents PASS | "Done" |

Chaque livraison peut faire l'objet d'un commit/PR séparé selon le workflow projet.

---

## Mapping Requirements → Tâches

| Requirement | Tâches |
|---|---|
| **FR-001** (route /settings/account) | T-020 |
| **FR-002** (4 sections page) | T-021, T-038, T-046, T-056, T-063 |
| **FR-003** (modifier nom) | T-027, T-028, T-038, T-040 |
| **FR-004** (POST avatar) | T-030, T-031, T-036, T-037, T-039, T-040 |
| **FR-005** (GET avatar + ETag) | T-030, T-032, T-037 |
| **FR-006** (DELETE avatar) | T-030, T-033, T-036, T-037 |
| **FR-007** (email read-only) | T-027 (DTO), T-038 (UI Angular), T-040 (UI Flutter) |
| **FR-008** (POST /me/password) | T-041, T-043, T-044, T-046, T-047, T-048, T-049 |
| **FR-009** (vérif BCrypt currentPassword) | T-043, T-045 |
| **FR-010** (newPassword ≥ 12 + ≠ current) | T-041, T-043, T-045 |
| **FR-011** (FirstLoginResetRequest min 12) | T-042 |
| **FR-012** (handler logout Angular) | T-022, T-023 |
| **FR-013** (résilience logout backend down) | T-023 |
| **FR-014** (export JSON) | T-050, T-051, T-053, T-056, T-057 |
| **FR-015** (export CSV) | T-052, T-054, T-056, T-057 |
| **FR-016** (entités exportées) | T-051, T-055 |
| **FR-017** (CSV entêtes français + BOM + Type traduit) | T-052, T-055 |
| **FR-017a** (structure JSON groupée + schemaVersion) | T-050, T-051 |
| **FR-018** (DELETE /me) | T-059, T-060, T-061, T-063, T-064, T-065, T-066 |
| **FR-019** (soft-delete via disabled_at) | T-060 |
| **FR-020** (login bloqué si disabled) | T-015, T-016, T-017, T-062 |
| **FR-021** (refus dernier admin) | T-015 (countActiveAdmins), T-060, T-062 |
| **FR-022** (logs SLF4J actions sensibles) | T-030, T-043, T-052, T-060 |
| **FR-023** (révoc refresh tokens au change MDP) | T-043, T-045 |
| **FR-024** (nouveau JWT device courant) | T-043, T-044, T-045, T-047, T-049 |
| **FR-025** (JWT autres devices expire naturellement) | T-045 (test couverture) |
| **NFR-001** (JWT obligatoire) | T-031, T-032, T-033, T-044, T-053, T-054, T-061 (annotation auth) |
| **NFR-002** (validation MIME magic numbers) | T-019, T-035 |
| **NFR-003** (email immuable self-service) | T-027 |
| **NFR-004** (perf export JSON < 5s pour 10K transactions) | T-058 |
| **NFR-005** (parité Angular/Flutter 100%) | T-024, T-039, T-040, T-048, T-049, T-057, T-065, T-066 |
| **NFR-006** (redim 256x256 JPEG 85%) | T-030, T-035 |
| **NFR-007** (logs ERROR avec userId) | T-030, T-043, T-052, T-060 |
| **NFR-008** (stockage disque local + property) | T-004, T-018, T-030, T-071 |
| **NFR-009** (réutilisation patterns DESIGN.md) | T-021, T-038, T-040, T-046, T-063, T-077 |

---

## Résumé

| Phase | Total | P1 | P2 | P3 | Parallélisables |
|-------|-------|----|----|----|-----------------|
| **Phase 1 — Setup** | 8 | 0 | 0 | 0 | 5 |
| **Phase 2 — Fondations** | 10 | 10 | 0 | 0 | 5 |
| **Phase 3 — User Stories P1** | 30 | 30 | 0 | 0 | 12 |
| **Phase 3 — User Stories P2** | 9 | 0 | 9 | 0 | 5 |
| **Phase 3 — User Stories P3** | 9 | 0 | 0 | 9 | 3 |
| **Phase 4 — Polish** | 11 | 2 | 7 | 1 | 6 |
| **Total** | **77** | **42** | **16** | **10** | **36** |

> Note : la priorité (`[P1]`/`[P2]`/`[P3]`) sur les tâches Polish reflète l'importance opérationnelle (tests/audits = P1 ou P2 — bloquants au merge, refactoring = P3 — nice to have).

### Items review-spec absorbés en tasks

| Item review-spec | Tâche dédiée |
|---|---|
| **W-001** (assumption FK CASCADE) | Mitigation R-001 du plan + T-005 (audit pré-impl) |
| **W-002** (SC manquant nouveau JWT post-change-password) | T-045 (tests `should_return_new_jwt_when_password_changed`) |
| **W-003** (SC manquant perf export JSON) | T-058 (test de charge dédié) |
| **W-004** (admin non-seul peut se supprimer) | T-062 (test `should_succeed_when_admin_not_alone`) |
| **W-005** (SC-004 perf avatar séparé) | T-075 (séparation SC-015 upload+redim et SC-016 service) |
| **I-001** (DTO PUT /users/me strict) | T-027 (renommage UpdateProfileRequest) |
| **I-002** (cache HTTP avatar) | T-032 (ETag SHA-256) |
| **I-003** (property name) | T-018 (StorageProperties) |
| **I-004** (inclure invitations export) | T-051 + T-055 (vérification test) |
| **I-005** (mode offline Flutter) | T-068 |

**10/10 items review-spec absorbés** ✅

---

## Notes opérationnelles

- **Estimation globale** : ~3-4 jours de travail séquentiel pour un dev expérimenté full-stack, ou ~1.5-2 jours en parallélisant les frontends Angular/Flutter sur des branches feature séparées (mais cette feature reste sur `feature/KKS-235`).
- **Délégation Opus → Sonnet** : conformément à CLAUDE.md, les tâches d'implémentation backend sont à déléguer à `spring-boot-dev`, Angular à `angular-dev`, Flutter à `flutter-dev`, tests à `test-qa`. Opus orchestre, valide les architectures et lance les reviews.
- **Pre-commit obligatoire** : avant chaque commit, lancer agents `pre-commit-review` (CLAUDE.md) et `frontend-design-review` si fichiers UI touchés.
- **Sync doc** : après l'implémentation complète, lancer `/sync-doc` pour valider que la doc projet reste cohérente.
