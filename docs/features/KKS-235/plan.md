# Plan — KKS-235 : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

> Date : 2026-04-30
> Issue : KKS-235
> Spec : [spec.md](./spec.md)
> Research : [research.md](./research.md)
> Clarify : [clarify-log.md](./clarify-log.md)
> Review-spec : [review-log.md](./review-log.md) (PASS, 5 WARNING, 5 INFO)

---

## Constitution Check

> Vérification des 7 gates définies dans `.specify/memory/constitution.md` (v2.1.2).

| Gate | Statut | Commentaire |
|------|--------|-------------|
| **I. API-First** | ✅ PASS | Tous les endpoints REST avec DTOs séparés (jamais d'entité JPA exposée). Renommage `UpdateUserRequest` → `UpdateProfileRequest` pour explicitement séparer self-service vs admin (cf. RES-007). |
| **II. Sécurité par défaut** | ✅ PASS | JWT obligatoire sur toutes les nouvelles routes `/users/me/*`. Validation MIME via magic numbers (RES-002), BCrypt pour change-password, isolation user via `disabled_at` filter (RES-005). Email immuable côté self-service (privilege escalation prévenue). |
| **III. Simplicité & YAGNI** | ✅ PASS | Pas de Hibernate filter global rejeté (RES-005), pas d'Apache Tika rejeté (RES-002), pas d'`ngx-image-cropper` rejeté (RES-010), pas de queue async export rejeté (sync direct). 2 nouvelles libs justifiées (Thumbnailator backend, flutter_image_compress mobile). |
| **IV. Mobile-First UX** | ✅ PASS | Saisie en 2-3 interactions confirmée (tap avatar → picker → upload). Parité Flutter via extension `ProfileSettingsScreen`. Mode offline page Mon compte = server-only avec état dégradé explicite (exception documentée RES-013, conforme constitution principe IV exception "données fraîches requises"). |
| **V. Testabilité** | ✅ PASS | Tests d'intégration sur les 7 nouveaux endpoints (nominal + erreurs 4xx). Tests unitaires services (`AvatarStorageService`, `UserPasswordService`, `UserExportService`, `UserDeletionService`, `ImageMimeValidator`). Nommage `should_[résultat]_when_[condition]` respecté. |
| **VI. Observabilité** | ✅ PASS | SLF4J `log.info()` sur actions sensibles (changement MDP, suppression compte, upload/suppression avatar) avec `userId` en contexte (FR-022). `log.error()` sur erreurs avec stack trace + userId. Aucun `System.out.println`. |
| **VII. Self-Hosted Ready** | ✅ PASS | Stockage avatars sur disque local via property `app.storage.avatars.path` (RES-003), aucune dépendance SaaS (CDN, S3). PostgreSQL seule infra externe. Variable d'env `AVATAR_STORAGE_PATH` documentée dans `docs/deployment.md`. |

### Dérogations

Aucune dérogation. Le plan respecte intégralement les 7 principes constitutionnels.

### Complexity Tracking

> Complexités ajoutées (acceptables) avec justification explicite.

| # | Complexité | Justification | Alternative envisagée |
|---|-----------|---------------|----------------------|
| CX-001 | Ajout dépendance Maven `thumbnailator` 0.4.20 | Gestion EXIF auto-rotation indispensable pour photos mobile (sinon avatars à l'envers). 30 lignes de BufferedImage natif vs 5 lignes Thumbnailator. | RES-001 : BufferedImage natif (rejeté pour verbosité + EXIF manuel risqué). |
| CX-002 | Ajout dépendance pubspec.yaml `flutter_image_compress` | Photos HD smartphone (3-5 MB) > limite 2 MB serveur. Pré-compression côté client = UX fluide (pas d'erreur 400 systématique). | RES-012 : `imageQuality: 70` natif `image_picker` (rejeté pour qualité non déterministe iOS vs Android). |
| CX-003 | Premier `@SQLRestriction` projet ÉVITÉ — filtrage explicite à la place dans `AuthService.login` + `JwtFilter` | Évite l'introduction d'un mécanisme global Hibernate (effet de bord trop fort). 2 callsites à protéger seulement. | RES-005 : filtrage Hibernate global rejeté pour complications bootstrap/admin. |
| CX-004 | Stockage path filesystem en DB (`users.avatar_path`) plutôt que bytea | Décharge la DB de fichiers binaires (~50 KB par avatar redim). Backups DB plus légers. Contre-partie : path doit suivre les backups physiques du serveur. | RES-003 : bytea PostgreSQL (rejeté pour bloat DB et performance). |

---

## Résumé de l'approche

Implémentation d'une page **Mon compte** côté Angular et Flutter regroupant 4 sections fonctionnelles (Identité / Sécurité / Données / Zone de danger), adossée à 7 nouveaux endpoints backend et 4 migrations Flyway. La feature corrige également le bug du bouton déconnexion Angular sans handler. L'approche maximise la **réutilisation** des patterns existants (`ConfirmDialog` Angular, `image_picker` Flutter, Apache Commons CSV, BCrypt, `RefreshTokenService.revokeAllUserTokens`) et applique le principe **YAGNI** (pas de Hibernate filter global, pas d'Apache Tika, pas de crop client, pas de queue async export).

Sécurité renforcée par : (1) email immuable côté self-service (privilege escalation prévenue), (2) validation MIME via magic numbers, (3) soft-delete avec révocation des refresh tokens, (4) politique MDP harmonisée à 12 caractères dans tous les flows.

---

## Contexte technique

### Stack

| Couche | Technologie | Version |
|---|---|---|
| Backend | Spring Boot | 4.0.2 |
| Backend | Java | 21 |
| Backend | PostgreSQL | 15+ |
| Frontend PWA | Angular | 21.1.0 |
| Frontend mobile | Flutter | >= 3.27 |
| Frontend mobile | Riverpod | flutter_riverpod |

### Dépendances nouvelles

| Dépendance | Couche | Version | Justification |
|---|---|---|---|
| `net.coobird:thumbnailator` | Backend Maven | 0.4.20 | Redim image + EXIF auto-rotation (RES-001) |
| `flutter_image_compress` | Flutter | ^2.x | Pré-compression client avant upload (RES-012) |

### Dépendances existantes impactées

| Dépendance | Usage |
|---|---|
| Apache Commons CSV 1.11.0 | Export CSV (réutilisation, déjà utilisée pour KKS-099 import) |
| Jackson | Export JSON (déjà configuré via Spring Boot) |
| BCryptPasswordEncoder | Change password (déjà utilisé) |
| `RefreshTokenService.revokeAllUserTokens` | Révocation tokens au change-password (déjà existant) |
| `image_picker` Flutter 1.1.2 | Picker système avant compression (déjà utilisé pour `account_form_screen.dart`) |
| `ConfirmDialog` + `ConfirmService` Angular | Confirmation suppression (réutilisation, extension probable) |

---

## Architecture

### Structure des fichiers impactés

```
api/
├── pom.xml                                                    [M]   ajout thumbnailator
├── src/main/resources/
│   ├── application.yaml                                       [M]   config storage avatars + multipart
│   └── db/migration/
│       ├── V32__add_user_avatar_path.sql                      [C]
│       ├── V33__patch_budgets_user_fk_cascade.sql             [C]
│       ├── V34__patch_budget_snapshots_user_fk_cascade.sql    [C]
│       └── V35__patch_refresh_tokens_user_fk_cascade.sql      [C]
└── src/main/java/fr/kksdev/budget/api/
    ├── config/
    │   ├── StorageProperties.java                             [C]   @ConfigurationProperties
    │   ├── JwtFilter.java                                     [M]   filtrer disabled_at
    │   └── SecurityConfig.java                                [M]   permit GET /users/me/avatar (avec auth)
    ├── controller/
    │   └── UserController.java                                [M]   ajout endpoints /me/avatar, /me/password, /me/export, DELETE /me
    ├── service/
    │   ├── AvatarStorageService.java                          [C]   stockage + redim + validation
    │   ├── UserPasswordService.java                           [C]   change-password + révocation tokens
    │   ├── UserExportService.java                             [C]   export JSON + CSV
    │   ├── UserDeletionService.java                           [C]   soft-delete + bloque dernier admin
    │   ├── AuthService.java                                   [M]   filtrer disabled_at
    │   └── UserService.java                                   [M]   éventuel split (sinon ajouter softDelete)
    ├── repository/
    │   └── UserRepository.java                                [M]   ajout findByEmailAndDisabledAtIsNull
    ├── model/
    │   └── User.java                                          [M]   ajout avatarPath
    ├── dto/
    │   ├── request/
    │   │   ├── UpdateUserRequest.java                         [M]   renommer en UpdateProfileRequest
    │   │   ├── ChangePasswordRequest.java                     [C]
    │   │   ├── DeleteAccountRequest.java                      [C]
    │   │   └── FirstLoginResetRequest.java                    [M]   align min 12 chars
    │   └── response/
    │       ├── AvatarMetadataResponse.java                    [C]
    │       └── UserExportResponse.java                        [C]   structure JSON groupée
    └── util/
        └── ImageMimeValidator.java                            [C]

app/                                                                 (Angular)
├── src/app/
│   ├── core/
│   │   ├── services/
│   │   │   ├── user.service.ts                                [M]   ajout updateName, deleteAccount, exportData
│   │   │   ├── user-export.service.ts                         [C]
│   │   │   └── avatar.service.ts                              [C]
│   │   └── models/
│   │       ├── change-password-request.model.ts               [C]
│   │       └── update-profile-request.model.ts                [C]
│   ├── lib/                                                          (Lib-first selon CLAUDE.md)
│   │   └── avatar-upload/
│   │       ├── avatar-upload.component.ts                     [C]
│   │       ├── avatar-upload.component.html                   [C]
│   │       └── avatar-upload.component.scss                   [C]
│   └── features/
│       └── settings/
│           ├── settings.routes.ts                             [M]   ajout route /account
│           ├── settings.ts                                    [M]   FIX bouton déconnexion (handler manquant)
│           ├── settings.html                                  [M]   lien vers /settings/account + retrait logout (déplacé dans Mon compte)
│           └── account/
│               ├── mon-compte.component.ts                    [C]
│               ├── mon-compte.component.html                  [C]
│               ├── mon-compte.component.scss                  [C]
│               ├── mon-compte.routes.ts                       [C]
│               ├── change-password-dialog.component.ts        [C]
│               └── delete-account-confirm-dialog.component.ts [C]

flutter/                                                              (Flutter)
├── pubspec.yaml                                               [M]   flutter_image_compress
└── lib/src/features/user_profile/
    ├── domain/
    │   └── repositories/
    │       └── user_profile_repository.dart                   [M]   étendre interface
    ├── data/
    │   └── user_profile_repository_remote.dart                [M]   nouveaux endpoints (avatar, password, export, delete)
    ├── application/
    │   └── user_profile_notifier.dart                         [M]   actions update name, change password, delete
    └── presentation/
        ├── screens/
        │   └── profile_settings_screen.dart                   [M]   sections Sécurité / Données / Zone de danger
        └── widgets/
            ├── avatar_picker.dart                             [C]
            ├── change_password_sheet.dart                     [C]
            └── delete_account_sheet.dart                      [C]

docs/
├── api-examples.md                                            [M]   7 endpoints documentés
├── api-errors.md                                              [M]   nouveaux codes (INVALID_IMAGE_FORMAT, PASSWORD_INCORRECT, LAST_ADMIN_DELETION_FORBIDDEN, etc.)
├── deployment.md                                              [M]   variable AVATAR_STORAGE_PATH
└── manual-test-plan.md                                        [M]   ajout scénarios Mon compte
```

### Diagramme de flux

```
┌──────────────────────────────────────────────────────────────────────┐
│                            USER (browser/mobile)                     │
└────────────────┬─────────────────────────────────┬───────────────────┘
                 │                                 │
        Settings hub                       Settings hub
        → tap "Mon compte"                 → tap "Mon compte"
                 │                                 │
                 ▼                                 ▼
       ┌──────────────────┐              ┌──────────────────────┐
       │ Angular          │              │ Flutter              │
       │ /settings/account│              │ /settings/profile    │
       │ MonCompte        │              │ ProfileSettingsScreen│
       └─────────┬────────┘              └──────────┬───────────┘
                 │                                  │
                 └──────────────┬───────────────────┘
                                │
                                ▼ (HTTPS + JWT)
       ┌────────────────────────────────────────────────────┐
       │ Backend Spring Boot — UserController                │
       │ /api/users/me/avatar (POST/GET/DELETE)              │
       │ /api/users/me/password (POST)                       │
       │ /api/users/me/export?format=json|csv (GET)          │
       │ /api/users/me (DELETE)                              │
       │ /api/users/me (PUT)                                 │
       └─────────┬─────────┬──────────┬──────────┬──────────┘
                 │         │          │          │
                 ▼         ▼          ▼          ▼
       ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐
       │ Avatar   │ │ Password │ │ Export   │ │ Deletion     │
       │ Storage  │ │ Service  │ │ Service  │ │ Service      │
       │ Service  │ │          │ │          │ │              │
       └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘
            │            │            │              │
            ▼            ▼            ▼              ▼
       ┌────────┐  ┌────────────┐ ┌────────┐  ┌─────────────┐
       │ Disque │  │ BCrypt +   │ │ JPA +  │  │ disabled_at │
       │ local  │  │ refreshTk  │ │ CSV +  │  │ + revoke    │
       │ avatars│  │ revoke     │ │ Jackson│  │ tokens      │
       └────────┘  └────────────┘ └────────┘  └─────────────┘
```

---

## Approche par composant

### Composant 1 : Migrations DB (4 fichiers Flyway)

- **Responsabilité** : Préparer le schéma pour soft-delete (déjà appliqué V29), avatar path, et patches CASCADE.
- **Fichiers** : `V32__add_user_avatar_path.sql`, `V33__patch_budgets_user_fk_cascade.sql`, `V34__patch_budget_snapshots_user_fk_cascade.sql`, `V35__patch_refresh_tokens_user_fk_cascade.sql`
- **Requirements couverts** : MIG-002 (avatar_path), MIG-003 (budgets CASCADE), MIG-004 (budget_snapshots CASCADE), nouveau (refresh_tokens CASCADE — RES-008/009)
- **Approche** :
  - V32 : `ALTER TABLE users ADD COLUMN avatar_path VARCHAR(512) NULL;`
  - V33/V34/V35 : drop FK existante, recreate avec `ON DELETE CASCADE`
  - **Note** : MIG-001 (`users.disabled_at`) supprimée du scope car déjà appliquée via V29 (cf. RES-009).

### Composant 2 : Entity User + DTOs

- **Responsabilité** : Étendre l'entité User et restructurer les DTOs avec garde-fou contre privilege escalation.
- **Fichiers** : `User.java` [M], `UpdateProfileRequest.java` [renommage], `ChangePasswordRequest.java` [C], `DeleteAccountRequest.java` [C], `AvatarMetadataResponse.java` [C], `UserExportResponse.java` [C], `FirstLoginResetRequest.java` [M align 12 chars]
- **Requirements couverts** : FR-003, FR-008, FR-010, FR-011, FR-018, FR-019
- **Approche** :
  - `User.java` : ajout `@Column(name = "avatar_path", length = 512) private String avatarPath;`
  - `UpdateProfileRequest` (renommé) : `@NotBlank @Size(min=1, max=100) String name` + commentaire de garde RES-007
  - `ChangePasswordRequest` : `@NotBlank String currentPassword` + `@NotBlank @Size(min=12, max=100) String newPassword`
  - `DeleteAccountRequest` : `@NotBlank String currentPassword` + `boolean confirmed` (checkbox)
  - `FirstLoginResetRequest` : passer `@Size(min=8)` à `@Size(min=12)` pour align (W couvert par I-004 du review-spec → en réalité W non concerné, c'était un oubli de la spec)

### Composant 3 : `AvatarStorageService` + `ImageMimeValidator`

- **Responsabilité** : Validation MIME, redimensionnement, stockage disque local, suppression.
- **Fichiers** : `AvatarStorageService.java` [C], `ImageMimeValidator.java` [C], `StorageProperties.java` [C]
- **Requirements couverts** : FR-004, FR-005, FR-006, NFR-002, NFR-006, NFR-008
- **Approche** :
  - `StorageProperties` : `@ConfigurationProperties(prefix="app.storage")` avec sous-record `Avatars(String path)` (RES-003).
  - `ImageMimeValidator.isValidImage(MultipartFile)` : lecture des 8 premiers octets, vérif signatures JPEG (`FF D8 FF`) et PNG (`89 50 4E 47 0D 0A 1A 0A`) (RES-002).
  - `AvatarStorageService.store(User user, MultipartFile file)` :
    1. Validation MIME via `ImageMimeValidator`.
    2. Validation taille ≤ 2 MB.
    3. Redim via Thumbnailator : `Thumbnails.of(input).size(256, 256).outputFormat("jpg").outputQuality(0.85).toFile(targetPath)` (RES-001).
    4. Path = `properties.avatars().path() + "/" + user.getId() + ".jpg"`.
    5. Update `user.avatarPath` et persist.
  - `AvatarStorageService.delete(User user)` : suppression disque + nullification `user.avatarPath`.
  - `AvatarStorageService.read(User user) → byte[]` : lecture binaire pour servir.
  - Création automatique du dossier au démarrage (`@PostConstruct`).
  - Tests unitaires : tous les scénarios (valid JPG, valid PNG, GIF rejeté, fichier maquillé rejeté, > 2 MB rejeté, EXIF rotation, redim correct).

### Composant 4 : Endpoints avatar (`UserController` étendu)

- **Responsabilité** : Exposer les endpoints REST avatar avec ETag SHA-256.
- **Fichiers** : `UserController.java` [M]
- **Requirements couverts** : FR-004, FR-005, FR-006, NFR-001
- **Approche** :
  - `POST /api/users/me/avatar` : `@RequestParam("file") MultipartFile file` → délégation à `AvatarStorageService.store` → `200 AvatarMetadataResponse(url)`. Erreur `400 INVALID_IMAGE_FORMAT` ou `413 FILE_TOO_LARGE`.
  - `GET /api/users/me/avatar` :
    1. Lecture binaire via `AvatarStorageService.read`.
    2. Calcul ETag SHA-256 (8 premiers chars).
    3. Si `If-None-Match` matche → `304 Not Modified`.
    4. Sinon `200` avec `Content-Type: image/jpeg`, `Cache-Control: private, must-revalidate, max-age=0`, `ETag: "<hash>"` (RES-004).
  - `DELETE /api/users/me/avatar` : délégation à `AvatarStorageService.delete` → `204 No Content`.
  - Sécurité : tous protégés par JWT (filter standard).

### Composant 5 : `UserPasswordService` + endpoint change-password

- **Responsabilité** : Vérifier MDP actuel, hasher nouveau, révoquer refresh tokens, émettre nouveau JWT.
- **Fichiers** : `UserPasswordService.java` [C], `UserController.java` [M]
- **Requirements couverts** : FR-008, FR-009, FR-010, FR-011, FR-023, FR-024, FR-025
- **Approche** :
  - `UserPasswordService.changePassword(User user, ChangePasswordRequest req) → AuthResponse` :
    1. Vérifier `req.currentPassword` via `BCryptPasswordEncoder.matches`. Échec → `ApiException 401 PASSWORD_INCORRECT`.
    2. Vérifier `req.newPassword != req.currentPassword` via `BCryptPasswordEncoder.matches`. Égalité → `400 PASSWORD_UNCHANGED`.
    3. Hasher `req.newPassword` via `BCryptPasswordEncoder.encode` et persist.
    4. `refreshTokenService.revokeAllUserTokens(user)` (RES-008).
    5. Générer nouveau JWT + nouveau refresh token via `JwtUtil` + `RefreshTokenService`.
    6. Retourner `AuthResponse`.
  - `POST /api/users/me/password` dans `UserController`.
  - Log SLF4J INFO : `"User {} changed password"`.
  - Tests d'intégration : nominal, MDP actuel incorrect, MDP identique, MDP < 12 chars (rejet Bean Validation 400).

### Composant 6 : `UserExportService` + endpoint export

- **Responsabilité** : Sérialiser tout le périmètre user en JSON (groupé) ou CSV transactions.
- **Fichiers** : `UserExportService.java` [C], `UserExportResponse.java` [C], `UserController.java` [M]
- **Requirements couverts** : FR-014, FR-015, FR-016, FR-017, FR-017a, NFR-004, A-003
- **Approche** :
  - `UserExportResponse` : record top-level avec `schemaVersion`, `exportedAt`, et tous les champs entités (cf. RES-006 / FR-017a).
  - `UserExportService.exportJson(User user) → UserExportResponse` :
    - Charger toutes les entités liées via repositories existants.
    - Sérialiser via Jackson (configuration standard projet).
    - Inclusion `invitations` : **OUI** (résolution I-004 du review-spec). Le user peut avoir invité quelqu'un et veut une trace.
  - `UserExportService.exportCsv(User user, OutputStream out)` :
    - `OutputStreamWriter` UTF-8 + écriture BOM `﻿` (RES-006).
    - `CSVPrinter` avec format RFC 4180.
    - Itération sur `transactionRepository.findAllByUser(user)` + écriture ligne par ligne.
    - Traduction `TransactionType` enum en français ("Revenu" / "Dépense" / "Transfert").
  - `GET /api/users/me/export?format=json|csv` :
    - Format JSON → `200 application/json` + body sérialisé.
    - Format CSV → `200 text/csv; charset=utf-8` + `Content-Disposition: attachment; filename="kbudget-transactions-{userId}-{date}.csv"` + streaming via `StreamingResponseBody`.
  - Tests d'intégration : exhaustivité JSON (compare avec dump direct DB), CSV bien formé Excel (BOM, séparateurs, échappement), perf 10000 transactions < 5 s (NFR-004).

### Composant 7 : `UserDeletionService` + endpoint DELETE /me

- **Responsabilité** : Soft-delete avec garde-fou dernier admin actif et révocation tokens.
- **Fichiers** : `UserDeletionService.java` [C], `UserController.java` [M], `UserRepository.java` [M], `AuthService.java` [M], `JwtFilter.java` [M]
- **Requirements couverts** : FR-018, FR-019, FR-020, FR-021, FR-022
- **Approche** :
  - `UserRepository` : ajout `Optional<User> findByEmailAndDisabledAtIsNull(String email)` + `long countActiveAdmins()` (`SELECT COUNT(*) FROM users WHERE is_admin = true AND disabled_at IS NULL`).
  - `UserDeletionService.softDelete(User user, DeleteAccountRequest req)` :
    1. Vérifier `req.confirmed == true`. Sinon `400 CONFIRMATION_REQUIRED`.
    2. Vérifier `req.currentPassword` via `BCryptPasswordEncoder.matches`. Échec → `401 PASSWORD_INCORRECT`.
    3. Si `user.isAdmin`, vérifier `userRepository.countActiveAdmins() > 1`. Si égal à 1 → `403 LAST_ADMIN_DELETION_FORBIDDEN` (FR-021).
    4. Set `user.disabledAt = LocalDateTime.now()` et persist.
    5. `refreshTokenService.revokeAllUserTokens(user)`.
    6. Log SLF4J INFO : `"User {} soft-deleted (disabled_at={})"`.
  - `DELETE /api/users/me` dans `UserController` → `204 No Content`.
  - `AuthService.login` : utiliser `findByEmailAndDisabledAtIsNull` (RES-005).
  - `JwtFilter.doFilterInternal` : utiliser `findByEmailAndDisabledAtIsNull` (RES-005).
  - Tests d'intégration : soft-delete nominal + login bloqué après, MDP incorrect, dernier admin bloqué, admin non-seul OK.

### Composant 8 : Refonte composant Settings Angular

- **Responsabilité** : Créer `MonCompte` page lazy-loaded + fix bug bouton déconnexion existant + composants supports.
- **Fichiers** : `mon-compte.component.{ts,html,scss}` [C], `mon-compte.routes.ts` [C], `settings.routes.ts` [M], `settings.ts` [M], `settings.html` [M], `change-password-dialog.component.ts` [C], `delete-account-confirm-dialog.component.ts` [C], `lib/avatar-upload/*` [C]
- **Requirements couverts** : FR-001, FR-002, FR-003, FR-004, FR-006, FR-008, FR-012, FR-013, FR-014, FR-015, FR-018, NFR-005, NFR-009
- **Approche** :
  - **Bug fix logout** (W-005 / spec FR-012/013) : dans `settings.ts`, supprimer le bouton logout du template `settings.html` (déplacé dans Mon compte). Garder un seul handler `logout()` dans `MonCompte` qui appelle `authService.logout()` (déjà implémenté côté service) + redirect `/login`.
  - **Route lazy-loaded** : dans `settings.routes.ts`, ajouter `{ path: 'account', loadComponent: () => import('./account/mon-compte.component').then(m => m.MonCompteComponent) }`.
  - **`MonCompte` component** : standalone, OnPush, signals-first.
    - Inputs : aucun.
    - State : `currentUser = computed(() => authService.currentUser())`, `isUploading: WritableSignal<boolean>`, `error: WritableSignal<string | null>`.
    - 4 sections HTML : Identité (avec `<app-avatar-upload>`, nom inline editable, email read-only avec mention "Géré par l'admin"), Sécurité (bouton "Changer le mot de passe" → ouvre dialog), Données (boutons "Exporter JSON" / "Exporter CSV"), Zone de danger (bouton "Déconnexion" en gris + bouton "Supprimer mon compte" en rouge → ouvre dialog).
  - **`AvatarUploadComponent`** (lib) : composant custom standalone, signals-first (RES-010). Gestion preview + upload + delete + erreurs.
  - **`ChangePasswordDialogComponent`** : formulaire 3 champs (current, new, confirm), validation côté client (length 12, match), appel `userService.changePassword(req)`.
  - **`DeleteAccountConfirmDialogComponent`** : formulaire avec MDP + checkbox + bouton submit désactivé tant que conditions non remplies (RES-011).
  - Réutilisation : `.settings-row`, `.settings-section`, tokens DESIGN.md, segmented controls.

### Composant 9 : Extension page profil Flutter

- **Responsabilité** : Étendre `ProfileSettingsScreen` avec sections Sécurité / Données / Zone de danger pour parité Angular 100%.
- **Fichiers** : `profile_settings_screen.dart` [M], `avatar_picker.dart` [C], `change_password_sheet.dart` [C], `delete_account_sheet.dart` [C], `user_profile_repository.dart` [M], `user_profile_repository_remote.dart` [M], `user_profile_notifier.dart` [M], `pubspec.yaml` [M]
- **Requirements couverts** : FR-001, FR-002, FR-003, FR-004, FR-006, FR-008, FR-014, FR-015, FR-018, NFR-005
- **Approche** :
  - **`avatar_picker.dart`** : widget StatefulConsumer. Flow : `image_picker` → `flutter_image_compress` (target ~1.5 MB) → upload via Dio (RES-012).
  - **`change_password_sheet.dart`** : bottom sheet avec form + 3 fields (current, new, confirm) + validation client (≥12 chars).
  - **`delete_account_sheet.dart`** : bottom sheet avec MDP + checkbox + bouton désactivé conditionnellement (RES-011, parité Angular).
  - **`UserProfileRepository`** étendu : `Future<void> uploadAvatar(File)`, `deleteAvatar()`, `changePassword(req)`, `deleteAccount(req)`, `exportData(format)`.
  - **Mode server-only** : `userProfileProvider = FutureProvider`, pas de cache Drift (RES-013). État offline : widget `_OfflineState` quand `connectivityProvider` indique offline.
  - **Logout** : déjà géré côté Flutter via `UserMenuButton` popup. La page Mon compte ajoute un row "Déconnexion" qui appelle le même service.

### Composant 10 : Documentation

- **Responsabilité** : Mettre à jour la doc projet pour les nouveaux endpoints et conventions.
- **Fichiers** : `docs/api-examples.md` [M], `docs/api-errors.md` [M], `docs/deployment.md` [M], `docs/manual-test-plan.md` [M]
- **Requirements couverts** : DoD spec
- **Approche** : Documentation des 7 endpoints (request/response/erreurs), nouveaux codes d'erreur (`INVALID_IMAGE_FORMAT`, `PASSWORD_INCORRECT`, `PASSWORD_UNCHANGED`, `LAST_ADMIN_DELETION_FORBIDDEN`, `CONFIRMATION_REQUIRED`, `FILE_TOO_LARGE`), variable d'env `AVATAR_STORAGE_PATH` + recommandations backup, scénarios de test manuels.

---

## Risques et mitigations

| # | Risque | Impact | Probabilité | Mitigation |
|---|--------|--------|-------------|------------|
| R-001 | Migrations CASCADE sur `budgets` / `budget_snapshots` (V33/V34) cassent des tests existants qui supposaient `RESTRICT` | Moyen | Moyen | Audit pré-implémentation : grep des tests d'intégration sur `BudgetService`/`BudgetSnapshotService` avant de pousser les migrations. Si test concerné, adapter avant le merge. (Couvre W-001 du review-spec.) |
| R-002 | Performance export JSON sur 10 000 transactions > 5 s (NFR-004) sur self-hosted modeste | Moyen | Moyen | Test de charge dédié sur jeu de données 10K avant merge. Si dépassement → optimisation via `JsonGenerator` streaming (vs ObjectMapper in-memory). Couvre W-003. |
| R-003 | EXIF rotation incorrecte sur certaines photos mobile spécifiques (orientations rares) | Moyen | Bas | Tests unitaires `AvatarStorageService` avec un set d'images couvrant les 8 orientations EXIF. Thumbnailator gère normalement tout ça nativement, mais validation explicite. |
| R-004 | Path filesystem mal configuré en prod (permissions, disque plein) → erreurs 500 lors d'upload | Haut | Bas | Création automatique du dossier au démarrage (`@PostConstruct`) avec vérification permissions. `log.error` explicite si non writable. Documentation `docs/deployment.md` : `chown -R k-budget:k-budget /var/k-budget/avatars` + monitoring espace disque. |
| R-005 | JWT actuel sur autres devices reste valide 15 min après change-password (fenêtre attaque) | Moyen | Bas | Documenté explicitement dans la spec (FR-025). Mitigation supplémentaire : si threat model évolue (multi-device hostile), introduire blocklist JWT. Hors scope KKS-235. |
| R-006 | Suppression d'avatar en cours d'upload (race condition) | Bas | Bas | Synchronisation au niveau service via `synchronized` sur méthode store/delete par user_id, ou utilisation de `Files.move` atomique pour le replacement. |
| R-007 | Export JSON exposant accidentellement le `password` hash si la sérialisation Jackson n'exclut pas le champ | Haut | Bas | Vérification : champ `User.password` annoté `@JsonIgnore` ou DTO de sérialisation dédié pour l'export (`UserExportResponse.UserDto` qui n'expose QUE les champs publics). Test d'intégration : grep "password" dans l'export ne doit rien retourner sauf en metadata. |
| R-008 | Bug fix logout introduit régression UX | Bas | Bas | Test manuel + e2e ciblé sur le flow login → settings → logout → redirect. |

---

## Hors scope

- **Modification email par le user** : impossible côté self-service (privilege escalation). Géré par admin uniquement (hors scope KKS-235, peut faire l'objet d'une feature complémentaire si besoin).
- **Sessions actives / révocation par device** : reportée en P2 lors du sparring. Pas de blocklist JWT.
- **Crop d'avatar côté client** : refusé en RES-010 (le serveur fait le redim 256x256, pas besoin d'UI de crop).
- **Export async / queue** : refusé pour 16 users self-hosted. Sync direct download via streaming response.
- **Format avatar autre que JPG/PNG** : refusé en RES-002 (pas de WebP, GIF, etc. en v1).
- **Notification email après suppression de compte** : pas de SMTP configuré dans le projet. Logs SLF4J seulement.
- **Restauration de compte par le user** : un user soft-deleted ne peut pas se restaurer lui-même. Géré par admin (script SQL ou futur endpoint admin).
- **Audit log persisté en DB** : utilisation de SLF4J INFO uniquement (constitution principe VI). Pas de table dédiée.

---

## Items review-spec absorbés en plan

| Item review-spec | Statut | Traitement |
|---|---|---|
| **W-001** (FK CASCADE budgets/budget_snapshots) | ✅ Traité | Risque R-001 documenté + mitigation explicite |
| **W-002** (SC manquant nouveau JWT post-change-password) | ⚠️ Reporté | À ajouter dans `tasks.md` comme test d'acceptance dédié sur `UserPasswordService` (vérification AuthResponse contient nouveau JWT + ancien refresh token est revoked) |
| **W-003** (SC manquant perf export JSON) | ✅ Traité | Risque R-002 documenté + mitigation (test de charge) |
| **W-004** (scénario admin non-seul peut se supprimer) | ✅ Traité | Test d'intégration explicite dans Composant 7 (FR-021 + scénario "admin non-seul OK") |
| **W-005** (SC-004 perf avatar séparé) | ⚠️ Reporté | À séparer en deux SC distincts dans `tasks.md` (upload+redim vs service avec ETag) |
| **I-001** (DTO PUT /users/me strict) | ✅ Traité | RES-007 → renommage `UpdateProfileRequest` (Composant 2) |
| **I-002** (cache HTTP avatar) | ✅ Traité | RES-004 → ETag SHA-256 + `must-revalidate` (Composant 4) |
| **I-003** (property name stockage avatar) | ✅ Traité | RES-003 → `app.storage.avatars.path` (Composant 3) |
| **I-004** (inclure invitations dans export) | ✅ Traité | Décision plan : OUI inclure (Composant 6 → `UserExportResponse` étend la liste FR-016) |
| **I-005** (mode offline page Mon compte Flutter) | ✅ Traité | RES-013 → server-only + état offline explicite (Composant 9) |

---

## Artefacts complémentaires

| Artefact | Fichier | Généré | Justification |
|----------|---------|--------|---------------|
| Research | [research.md](./research.md) | Oui (étape précédente) | 13 décisions techniques (libs, patterns, archi) |
| Data Model | [data-model.md](./data-model.md) | **Oui** | User étendu + structure `UserExportResponse` à formaliser |
| Quickstart | [quickstart.md](./quickstart.md) | **Oui** | Guide d'implémentation pas-à-pas pour les agents `spring-boot-dev`, `angular-dev`, `flutter-dev` |
| Contracts | [contracts.md](./contracts.md) | À générer en `/devflow.contracts` | Contrats API REST détaillés des 7 endpoints (request/response/codes d'erreur) |
| Tasks | [tasks.md](./tasks.md) | À générer en `/devflow.tasks` | Décomposition opérationnelle |

---

## Synthèse

- **Constitution Check** : ✅ PASS sur les 7 gates, 0 dérogation, 4 complexités acceptées et justifiées (CX-001 à CX-004).
- **Composants** : 10 (4 backend services + 1 endpoints layer + 4 frontend + 1 doc).
- **Fichiers à créer** : ~30 (backend : 11, Angular : 11, Flutter : 4, docs : 4)
- **Fichiers à modifier** : ~15 (backend : 6, Angular : 4, Flutter : 4, build : 1)
- **Migrations DB** : 4 (V32 à V35)
- **Endpoints REST** : 7 nouveaux + 1 modifié (`PUT /users/me`)
- **Risques identifiés** : 8 (1 Haut, 4 Moyens, 3 Bas) avec mitigations explicites
- **FR couverts** : 25/25 (FR-001 à FR-025)
- **Nouvelles dépendances** : 2 (Thumbnailator backend, flutter_image_compress mobile)
- **Items review-spec** : 8/10 absorbés en plan, 2 reportés en `tasks.md`

**Décision** : passage à `/devflow.contracts` autorisé.
