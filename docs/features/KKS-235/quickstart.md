# Quickstart — KKS-235 : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

> Date : 2026-04-30
> Issue : KKS-235

---

## Pré-requis

- [x] Constitution lue (`.specify/memory/constitution.md` v2.1.2)
- [x] Spec validée ([spec.md](./spec.md) — review-spec PASS)
- [x] Clarify complété ([clarify-log.md](./clarify-log.md) — 5/5 résolus)
- [x] Research complétée ([research.md](./research.md) — 13 décisions)
- [x] Plan approuvé ([plan.md](./plan.md) — Constitution check PASS)
- [x] Data model documenté ([data-model.md](./data-model.md))
- [ ] Contracts générés (`/devflow.contracts`)
- [ ] Tasks générées (`/devflow.tasks`)

---

## Phase 1 — Setup

### Backend (api/)

```bash
# Vérifier qu'on est sur la bonne branche
cd /Users/kellysossoe/Code/Apps/budget
git status
# Doit afficher : "On branch feature/KKS-235"

# Ajouter Thumbnailator dans pom.xml (RES-001)
# <dependency>
#   <groupId>net.coobird</groupId>
#   <artifactId>thumbnailator</artifactId>
#   <version>0.4.20</version>
# </dependency>

cd api && mvn clean compile

# Vérifier l'absence de test régression sur budgets (R-001)
mvn test -Dtest=BudgetServiceTest,BudgetSnapshotServiceTest
```

### Flutter (flutter/)

```bash
# Ajouter flutter_image_compress dans pubspec.yaml (RES-012)
# dependencies:
#   flutter_image_compress: ^2.x

cd flutter && flutter pub get
cd flutter && flutter analyze
```

### Angular (app/)

Aucune nouvelle dépendance npm nécessaire (RES-010).

```bash
cd app && npm install
cd app && ng lint
```

**Vérification** : les 3 stacks compilent / passent le lint sans erreur, et le test des budgets passe avant toute migration.

---

## Phase 2 — Fondations Backend

### Fichiers à créer (ordre recommandé)

| Ordre | Fichier | Template/Base | Description |
|---|---|---|---|
| 1 | `db/migration/V32__add_user_avatar_path.sql` | KKS-233 V31 | ALTER TABLE users ADD avatar_path |
| 2 | `db/migration/V33__patch_budgets_user_fk_cascade.sql` | — | DROP/ADD FK CASCADE |
| 3 | `db/migration/V34__patch_budget_snapshots_user_fk_cascade.sql` | — | DROP/ADD FK CASCADE |
| 4 | `db/migration/V35__patch_refresh_tokens_user_fk_cascade.sql` | — | DROP/ADD FK CASCADE |
| 5 | `config/StorageProperties.java` | KKS-233 BootstrapProperties | @ConfigurationProperties pour `app.storage.avatars.*` |
| 6 | `util/ImageMimeValidator.java` | — | Validation magic numbers JPEG/PNG |
| 7 | `dto/request/UpdateProfileRequest.java` | (renommage de UpdateUserRequest) | Self-service profile, **PAS d'email** |
| 8 | `dto/request/ChangePasswordRequest.java` | KKS-232 AcceptInviteRequest | currentPassword + newPassword (min 12) |
| 9 | `dto/request/DeleteAccountRequest.java` | — | currentPassword + confirmed |
| 10 | `dto/response/AvatarMetadataResponse.java` | — | url + uploadedAt |
| 11 | `dto/response/UserExportResponse.java` | — | structure groupée par entité |
| 12 | `service/AvatarStorageService.java` | — | store/delete/read avatar |
| 13 | `service/UserPasswordService.java` | KKS-233 service pattern | changePassword (BCrypt + revoke tokens + new JWT) |
| 14 | `service/UserExportService.java` | — | exportJson + exportCsv |
| 15 | `service/UserDeletionService.java` | — | softDelete avec garde dernier admin |

### Fichiers à modifier

| Ordre | Fichier | Modification |
|---|---|---|
| 1 | `model/User.java` | Ajout `@Column(name = "avatar_path") String avatarPath` |
| 2 | `repository/UserRepository.java` | Ajout `findByEmailAndDisabledAtIsNull` + `countActiveAdmins` |
| 3 | `service/AuthService.java` | `login` utilise `findByEmailAndDisabledAtIsNull` |
| 4 | `config/JwtFilter.java` | Filter utilise `findByEmailAndDisabledAtIsNull` |
| 5 | `dto/request/FirstLoginResetRequest.java` | `@Size(min=12)` au lieu de `min=8` |
| 6 | `controller/UserController.java` | 7 nouveaux endpoints |
| 7 | `application.yaml` | `app.storage.avatars.path: ${AVATAR_STORAGE_PATH:./data/avatars}` |
| 8 | `pom.xml` | Ajout `thumbnailator:0.4.20` |

### Étapes

1. **Migrations DB d'abord** (créer V32→V35), exécuter `mvn spring-boot:run -Dspring-boot.run.profiles=dev` et vérifier que l'app démarre + Flyway applique les 4 migrations sans erreur.
2. Étendre `User.java`, recompiler.
3. Créer `StorageProperties` + `ImageMimeValidator` (utilitaires sans dépendance).
4. Créer les 4 services (`AvatarStorageService`, `UserPasswordService`, `UserExportService`, `UserDeletionService`).
5. Étendre `UserController` avec les 7 endpoints.
6. Ajuster `AuthService.login` + `JwtFilter` pour filtrer `disabled_at`.
7. Aligner `FirstLoginResetRequest` à 12 chars.

**Vérification** : `cd api && mvn clean install` — tous les tests existants passent, nouvelle suite de tests d'intégration en place.

---

## Phase 3 — Implémentation User Stories

### US-001 — Page Mon compte accessible + déconnexion fonctionnelle

**Backend** : Aucun nouveau endpoint pour US-001 directement (utilise `GET /users/me` + `POST /auth/logout` existants).

**Angular** :
1. Créer `app/src/app/features/settings/account/mon-compte.component.{ts,html,scss}` (standalone, OnPush, signals-first).
2. Créer `app/src/app/features/settings/account/mon-compte.routes.ts`.
3. Modifier `app/src/app/features/settings/settings.routes.ts` : ajouter `{ path: 'account', loadComponent: ... }`.
4. Modifier `app/src/app/features/settings/settings.html` : ajouter ligne "Mon compte" → chevron vers `/settings/account`. **Retirer le bouton Déconnexion** (déplacé dans Mon compte).
5. Dans `MonCompte` : ajouter section "Zone de danger" avec bouton Déconnexion qui appelle `authService.logout()` + `router.navigate(['/login'])`.

**Flutter** :
1. Vérifier que `ProfileSettingsScreen` est déjà accessible via `/settings/profile`.
2. Ajouter row "Déconnexion" dans la section "Zone de danger" du screen.

**Test** :
- Angular : `cd app && ng test` — test E2E ciblé login → settings → account → logout → redirect login.
- Flutter : `cd flutter && flutter test test/src/features/user_profile/` — test widget de la nouvelle section.
- Manuel : ajouter scénario dans `docs/manual-test-plan.md`.

---

### US-002 — Modifier nom + avatar

**Backend** :
1. `PUT /users/me` (existant) accepte le DTO renommé `UpdateProfileRequest` (name only).
2. `POST /users/me/avatar` : multipart upload, validation MIME, redim Thumbnailator, stockage disque.
3. `GET /users/me/avatar` : sert le binaire avec ETag.
4. `DELETE /users/me/avatar` : supprime fichier + nullifie `avatar_path`.

**Angular** :
1. Créer composant lib `app/src/app/lib/avatar-upload/avatar-upload.component.{ts,html,scss}` (signals-first).
2. Intégrer dans `MonCompte` section Identité.
3. Ajouter méthode `userService.updateName(name)` qui appelle `PUT /users/me`.
4. Ajouter `avatar.service.ts` pour upload/delete.

**Flutter** :
1. Créer `flutter/lib/src/features/user_profile/presentation/widgets/avatar_picker.dart`.
2. Flow : `image_picker` → `flutter_image_compress` → Dio upload.
3. Étendre `UserProfileRepository` (interface + impl Remote).

**Test** :
- Backend : tests d'intégration `should_upload_avatar_when_valid_jpg`, `should_reject_when_invalid_mime`, `should_reject_when_file_too_large`, `should_serve_avatar_with_etag`.
- Frontend : tests unitaires des composants avatar (preview, validation, erreurs).

---

### US-003 — Changer son mot de passe

**Backend** :
1. `POST /users/me/password` : validation Bean (min 12), check BCrypt actuel, vérif différent, hash nouveau, revoke tokens, nouveau JWT.

**Angular** :
1. Créer `change-password-dialog.component.ts`.
2. Form 3 champs (current, new, confirm) + validation client min 12 + match.
3. Appel `userService.changePassword(req)` + remplacer le JWT/refresh dans le state Auth.

**Flutter** :
1. Créer `change_password_sheet.dart` (bottom sheet).
2. Idem flow.

**Test** :
- Backend : `should_change_password_when_valid`, `should_reject_when_current_incorrect`, `should_reject_when_new_too_short`, `should_reject_when_new_equals_current`, `should_revoke_refresh_tokens_when_password_changed`, `should_return_new_jwt_when_password_changed`.
- Frontend : tests des dialogs, vérif que le state Auth est rafraîchi après succès.

---

### US-004 — Exporter ses données (JSON + CSV)

**Backend** :
1. `GET /users/me/export?format=json` : sérialisation Jackson de `UserExportResponse`, schemaVersion "1.0.0".
2. `GET /users/me/export?format=csv` : streaming `CSVPrinter` UTF-8 BOM, traduction Type enum.

**Angular** :
1. `user-export.service.ts` : `exportJson()`, `exportCsv()` qui déclenchent un download via blob URL.
2. Boutons dans section Données.

**Flutter** :
1. Méthodes `exportJson()`, `exportCsv()` dans `UserProfileRepository`.
2. Sauvegarde locale via `path_provider` ou `share_plus` selon plateforme.

**Test** :
- Backend : `should_export_all_user_entities_when_format_json`, `should_export_transactions_only_when_format_csv`, `should_translate_transaction_type_in_csv`, `should_include_utf8_bom_in_csv`, `should_not_expose_password_hash_in_export` (R-007).
- Performance : test de charge 10 000 transactions < 5 s (NFR-004, R-002).

---

### US-005 — Supprimer son compte (soft-delete)

**Backend** :
1. `DELETE /users/me` : soft-delete avec garde dernier admin actif.

**Angular** :
1. Créer `delete-account-confirm-dialog.component.ts` avec MDP + checkbox.
2. Bouton "Supprimer mon compte" en rouge dans Zone de danger.
3. Sur succès : déconnexion immédiate + redirect login.

**Flutter** :
1. `delete_account_sheet.dart` (parité).

**Test** :
- Backend : `should_soft_delete_user_when_password_correct`, `should_reject_when_password_incorrect`, `should_reject_when_last_admin`, `should_succeed_when_admin_not_alone`, `should_block_login_after_soft_delete`, `should_revoke_refresh_tokens_on_soft_delete`.
- Frontend : tests dialogs (validation, soumission, redirection).

---

## Phase 4 — Polish

1. **Lancer tous les tests** :
   ```bash
   cd api && mvn test                                     # Tests backend
   cd app && ng test                                      # Tests Angular
   cd flutter && flutter test                             # Tests Flutter
   ```
2. **Vérifier la couverture** :
   - Backend : tous les services ont des tests unitaires + endpoints des tests d'intégration nominal/erreurs.
   - Frontend : composants critiques ont des tests unitaires + au moins 1 test E2E par US.
3. **Linter** :
   ```bash
   cd app && ng lint && npm run format
   cd flutter && flutter analyze
   ```
4. **Review du code** :
   ```bash
   # Lancer la review devflow
   /devflow.review-impl KKS-235
   ```
5. **Pre-commit review** :
   ```bash
   # Avant chaque commit (workflow obligatoire)
   # Agent pre-commit-review + frontend-design-review automatiquement
   ```
6. **Documentation** :
   - Mettre à jour `docs/api-examples.md` avec les 7 endpoints.
   - Mettre à jour `docs/api-errors.md` avec les nouveaux codes.
   - Mettre à jour `docs/deployment.md` avec `AVATAR_STORAGE_PATH`.
   - Mettre à jour `docs/manual-test-plan.md` avec les scénarios Mon compte.
7. **Test manuel sur les 3 frontends** :
   - PWA Angular : flow complet sur `localhost:4200`.
   - Flutter : flow complet sur simulateur iOS + Android.
   - Vérifier le mode offline Flutter (état dégradé).

---

## Commandes utiles

| Action | Commande |
|--------|----------|
| Lancer le backend en dev | `cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev` |
| Lancer Angular en dev | `cd app && ng serve` |
| Lancer Flutter | `cd flutter && flutter run` |
| Tests backend | `cd api && mvn test` |
| Tests Angular | `cd app && ng test` |
| Tests Flutter | `cd flutter && flutter test` |
| Test backend unique | `cd api && mvn test -Dtest=NomDuTest` |
| Build Flutter codegen | `cd flutter && dart run build_runner build --delete-conflicting-outputs` |
| Lint Angular | `cd app && ng lint` |
| Format Angular | `cd app && npm run format` |
| Analyse Flutter | `cd flutter && flutter analyze` |
| Voir migrations Flyway | `ls api/src/main/resources/db/migration/` |

---

## Checklist finale (Definition of Done étendue)

- [ ] 4 migrations DB appliquées (V32 à V35) — pas 5 car V29 couvre déjà `disabled_at`
- [ ] 7 endpoints backend implémentés + tests d'intégration (nominal + erreurs)
- [ ] Politique MDP harmonisée à 12 chars dans `FirstLoginResetRequest` ET `ChangePasswordRequest`
- [ ] Page `/settings/account` Angular fonctionnelle (4 sections)
- [ ] `ProfileSettingsScreen` Flutter étendu (parité 100%)
- [ ] Bouton déconnexion Angular fonctionnel (bug fixé) — handler branché
- [ ] Soft-delete : login bloqué si `disabled_at IS NOT NULL` (test d'intégration)
- [ ] Garde "dernier admin actif" en place (FR-021)
- [ ] Avatar : upload/get/delete + ETag SHA-256 + cache headers
- [ ] Validation MIME via magic numbers (refus fichier maquillé)
- [ ] Export JSON contient toutes les entités (y compris invitations) sans password hash
- [ ] Export CSV UTF-8 BOM + traduction Type français
- [ ] Documentation mise à jour (`api-examples`, `api-errors`, `deployment`, `manual-test-plan`)
- [ ] DESIGN.md inchangé (pas de nouvelle règle de design)
- [ ] Pas de warning lint Angular ni Flutter
- [ ] Tous les tests passent (backend + Angular + Flutter)
- [ ] Review-impl PASS
- [ ] Pre-commit review (agent) sans CRITIQUE
