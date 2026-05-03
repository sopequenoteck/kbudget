# Contrats techniques — KKS-235 : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

> Date : 2026-04-30
> Issue : KKS-235
> Plan : [plan.md](./plan.md)
> Data Model : [data-model.md](./data-model.md)
> Research : [research.md](./research.md)

---

## Interfaces & Types

### Backend — DTOs Spring Boot (Java records / Lombok)

#### `UpdateProfileRequest` (renommage de `UpdateUserRequest`)

> Réf : FR-003

```java
// Self-service profile fields ONLY. Email is admin-managed (cf. KKS-235 §FR-007).
// Do not add fields that require admin authorization.
public record UpdateProfileRequest(
    @NotBlank
    @Size(min = 1, max = 100)
    String name
) {}
```

**Invariants** :
- Champ `email` STRICTEMENT EXCLU (sécurité — privilege escalation prévenue).
- Pas d'extension future sans validation admin (commentaire de garde RES-007).

---

#### `ChangePasswordRequest`

> Réf : FR-008, FR-009, FR-010

```java
public record ChangePasswordRequest(
    @NotBlank
    String currentPassword,

    @NotBlank
    @Size(min = 12, max = 100)
    String newPassword
) {}
```

**Invariants** :
- `newPassword` ≥ 12 caractères (politique harmonisée avec `FirstLoginResetRequest`).
- `newPassword != currentPassword` (vérifié côté service via `BCryptPasswordEncoder.matches`).

---

#### `DeleteAccountRequest`

> Réf : FR-018, FR-021

```java
public record DeleteAccountRequest(
    @NotBlank
    String currentPassword,

    @AssertTrue(message = "Confirmation explicite requise")
    boolean confirmed
) {}
```

**Invariants** :
- `confirmed` doit être `true` pour passer la validation.
- `currentPassword` vérifié via BCrypt.

---

#### `AvatarMetadataResponse`

> Réf : FR-004

```java
public record AvatarMetadataResponse(
    String url,           // URL relative : "/api/users/me/avatar"
    String etag,          // SHA-256 (8 premiers chars)
    Instant uploadedAt
) {}
```

---

#### `UserExportResponse` (top-level + sous-DTOs)

> Réf : FR-014, FR-016, FR-017a

```java
public record UserExportResponse(
    String schemaVersion,         // "1.0.0" (SemVer)
    Instant exportedAt,           // ISO-8601
    UserDto user,
    UserPreferenceDto preferences,
    List<AccountDto> accounts,
    List<CategoryDto> categories,
    List<TransactionDto> transactions,
    List<BudgetDto> budgets,
    List<BudgetSnapshotDto> budgetSnapshots,
    List<SubscriptionDto> subscriptions,
    List<DebtDto> debts,
    List<CategoryRuleDto> categoryRules,
    List<ImportProfileDto> importProfiles,
    List<ImportHistoryDto> importHistory,
    List<InvitationDto> invitations
) {
    // DTO interne SANS le champ password (sécurité)
    public record UserDto(
        String id,
        String email,
        String name,
        boolean isAdmin,
        boolean passwordResetRequired,
        Instant createdAt,
        String avatarPath
    ) {}
}
```

**Invariants** :
- `password` (hash BCrypt) JAMAIS sérialisé (R-007 du plan).
- `schemaVersion` toujours présent au top-level (clé pour parsing tiers).
- Toutes les `List<>` sont vides (pas null) si aucune donnée.

---

#### `AuthResponse` (existant, **étendu** au change-password)

> Réf : FR-024, FR-025

```java
// Existant — enrichi par KKS-233 avec mustResetCredentials
public record AuthResponse(
    String token,
    String refreshToken,
    String email,
    String name,
    boolean mustResetCredentials
) {}
```

**Invariants** :
- L'endpoint `POST /users/me/password` retourne un nouveau `AuthResponse` complet (nouveau JWT + nouveau refresh token).

---

### Backend — Configuration

#### `StorageProperties`

> Réf : NFR-008

```java
@Component
@ConfigurationProperties(prefix = "app.storage")
@Validated
public record StorageProperties(
    @NotNull Avatars avatars
) {
    public record Avatars(
        @NotBlank String path
    ) {}
}
```

**Configuration `application.yaml`** :
```yaml
app:
  storage:
    avatars:
      path: ${AVATAR_STORAGE_PATH:./data/avatars}
```

---

### Frontend Angular — Types TypeScript

#### `UpdateProfileRequest`

```typescript
export interface UpdateProfileRequest {
  name: string;
}
```

#### `ChangePasswordRequest`

```typescript
export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
}
```

#### `DeleteAccountRequest`

```typescript
export interface DeleteAccountRequest {
  currentPassword: string;
  confirmed: boolean;
}
```

#### `AvatarMetadata`

```typescript
export interface AvatarMetadata {
  url: string;
  etag: string;
  uploadedAt: string; // ISO-8601
}
```

#### `UserExport`

```typescript
export interface UserExport {
  schemaVersion: string;
  exportedAt: string;
  user: UserExportProfile;
  preferences: UserPreference;
  accounts: Account[];
  categories: Category[];
  transactions: Transaction[];
  budgets: Budget[];
  budgetSnapshots: BudgetSnapshot[];
  subscriptions: Subscription[];
  debts: Debt[];
  categoryRules: CategoryRule[];
  importProfiles: ImportProfile[];
  importHistory: ImportHistory[];
  invitations: Invitation[];
}

export interface UserExportProfile {
  id: string;
  email: string;
  name: string;
  isAdmin: boolean;
  passwordResetRequired: boolean;
  createdAt: string;
  avatarPath: string | null;
}
```

---

### Frontend Flutter — Models Dart (Freezed)

#### `ChangePasswordRequest`

```dart
@freezed
class ChangePasswordRequest with _$ChangePasswordRequest {
  const factory ChangePasswordRequest({
    required String currentPassword,
    required String newPassword,
  }) = _ChangePasswordRequest;

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
}
```

#### `DeleteAccountRequest`

```dart
@freezed
class DeleteAccountRequest with _$DeleteAccountRequest {
  const factory DeleteAccountRequest({
    required String currentPassword,
    required bool confirmed,
  }) = _DeleteAccountRequest;

  factory DeleteAccountRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountRequestFromJson(json);
}
```

#### `AvatarMetadata`

```dart
@freezed
class AvatarMetadata with _$AvatarMetadata {
  const factory AvatarMetadata({
    required String url,
    required String etag,
    required DateTime uploadedAt,
  }) = _AvatarMetadata;

  factory AvatarMetadata.fromJson(Map<String, dynamic> json) =>
      _$AvatarMetadataFromJson(json);
}
```

---

## API Endpoints

### `PUT /api/users/me`

> Réf : FR-003

| Aspect | Détail |
|--------|--------|
| Méthode | `PUT` |
| Path | `/api/users/me` |
| Auth | Requis (JWT) |
| Content-Type | `application/json` |

**Request** :
```json
{
  "name": "Kelly Sossoe"
}
```

**Response 200** :
```json
{
  "id": "uuid",
  "email": "kelly@example.com",
  "name": "Kelly Sossoe",
  "isAdmin": false,
  "passwordResetRequired": false
}
```

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 400 | Validation Bean échoue (nom vide, > 100 chars) | `{ "error": "VALIDATION_FAILED", "details": {...} }` |
| 401 | JWT absent ou invalide | `{ "error": "UNAUTHORIZED" }` |

---

### `POST /api/users/me/avatar`

> Réf : FR-004

| Aspect | Détail |
|--------|--------|
| Méthode | `POST` |
| Path | `/api/users/me/avatar` |
| Auth | Requis (JWT) |
| Content-Type | `multipart/form-data` |

**Request** : champ `file` de type `MultipartFile` (image JPG ou PNG, taille ≤ 2 MB)

**Response 200** :
```json
{
  "url": "/api/users/me/avatar",
  "etag": "a3f5b2c1",
  "uploadedAt": "2026-04-30T09:35:00Z"
}
```

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 400 | Format MIME invalide (magic numbers) | `{ "error": "INVALID_IMAGE_FORMAT", "message": "Seuls les formats JPG et PNG sont acceptés." }` |
| 401 | JWT absent ou invalide | `{ "error": "UNAUTHORIZED" }` |
| 413 | Taille > 2 MB | `{ "error": "FILE_TOO_LARGE", "message": "La taille maximale est 2 MB." }` |
| 500 | Erreur disque (permissions, espace) | `{ "error": "STORAGE_ERROR" }` |

---

### `GET /api/users/me/avatar`

> Réf : FR-005, NFR-006

| Aspect | Détail |
|--------|--------|
| Méthode | `GET` |
| Path | `/api/users/me/avatar` |
| Auth | Requis (JWT) |

**Headers conditionnels** :
- `If-None-Match: "<etag>"` (optionnel, pour revalidation)

**Response 200** :
- `Content-Type: image/jpeg`
- `Cache-Control: private, must-revalidate, max-age=0`
- `ETag: "<sha256_8chars>"`
- Body : binaire JPEG 256x256

**Response 304** : si `If-None-Match` matche l'ETag courant. Pas de body.

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 401 | JWT absent ou invalide | `{ "error": "UNAUTHORIZED" }` |
| 404 | Avatar absent (user n'a pas uploadé OU fichier disparu du disque) | `{ "error": "AVATAR_NOT_FOUND" }` |

---

### `DELETE /api/users/me/avatar`

> Réf : FR-006

| Aspect | Détail |
|--------|--------|
| Méthode | `DELETE` |
| Path | `/api/users/me/avatar` |
| Auth | Requis (JWT) |

**Request** : pas de body.

**Response 204** : pas de body.

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 401 | JWT absent ou invalide | `{ "error": "UNAUTHORIZED" }` |
| 404 | Avatar absent (rien à supprimer) | `{ "error": "AVATAR_NOT_FOUND" }` |

---

### `POST /api/users/me/password`

> Réf : FR-008, FR-009, FR-010, FR-011, FR-023, FR-024, FR-025

| Aspect | Détail |
|--------|--------|
| Méthode | `POST` |
| Path | `/api/users/me/password` |
| Auth | Requis (JWT) |
| Content-Type | `application/json` |

**Request** :
```json
{
  "currentPassword": "ancien_mot_de_passe",
  "newPassword": "nouveau_mot_de_passe_min_12c"
}
```

**Response 200** :
```json
{
  "token": "<nouveau_jwt>",
  "refreshToken": "<nouveau_refresh_token>",
  "email": "kelly@example.com",
  "name": "Kelly Sossoe",
  "mustResetCredentials": false
}
```

**Side effects** :
- Tous les refresh tokens existants du user sont **révoqués** (FR-023).
- Un nouveau couple JWT + refresh token est émis pour le device courant (FR-024).
- Les autres devices peuvent encore utiliser leur JWT actuel jusqu'à expiration naturelle (≤ 15 min) mais ne peuvent plus se renouveler (FR-025).
- Log SLF4J INFO : `"User {} changed password"`.

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 400 | Validation Bean (newPassword < 12 chars, ou identique à current via BCrypt match) | `{ "error": "PASSWORD_UNCHANGED" }` ou `{ "error": "VALIDATION_FAILED", "details": {...} }` |
| 401 | JWT absent ou `currentPassword` incorrect | `{ "error": "UNAUTHORIZED" }` ou `{ "error": "PASSWORD_INCORRECT" }` |

---

### `GET /api/users/me/export?format={json|csv}`

> Réf : FR-014, FR-015, FR-016, FR-017, FR-017a, NFR-004

| Aspect | Détail |
|--------|--------|
| Méthode | `GET` |
| Path | `/api/users/me/export?format=json` ou `?format=csv` |
| Auth | Requis (JWT) |

**Response 200 (format=json)** :
- `Content-Type: application/json`
- `Content-Disposition: attachment; filename="kbudget-export-{userId}-{yyyyMMdd}.json"`
- Body : `UserExportResponse` sérialisé (cf. interface)

**Response 200 (format=csv)** :
- `Content-Type: text/csv; charset=utf-8`
- `Content-Disposition: attachment; filename="kbudget-transactions-{userId}-{yyyyMMdd}.csv"`
- Body : CSV streamé via `StreamingResponseBody`. UTF-8 avec BOM. Entêtes : `Date,Libellé,Montant,Devise,Compte,Catégorie,Type`. Type traduit : `Revenu` (RECETTE) / `Dépense` (DEPENSE) / `Ajustement` (AJUSTEMENT).

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 400 | `format` absent ou ≠ `json`/`csv` | `{ "error": "INVALID_EXPORT_FORMAT" }` |
| 401 | JWT absent ou invalide | `{ "error": "UNAUTHORIZED" }` |

---

### `DELETE /api/users/me`

> Réf : FR-018, FR-019, FR-020, FR-021

| Aspect | Détail |
|--------|--------|
| Méthode | `DELETE` |
| Path | `/api/users/me` |
| Auth | Requis (JWT) |
| Content-Type | `application/json` |

**Request** :
```json
{
  "currentPassword": "mot_de_passe_actuel",
  "confirmed": true
}
```

**Response 204** : pas de body. Le user est immédiatement déconnecté côté client.

**Side effects** :
- `users.disabled_at = now()` (soft-delete).
- Tous les refresh tokens du user révoqués.
- Log SLF4J INFO : `"User {} soft-deleted (disabled_at={})"`.
- Le JWT actuel reste valide jusqu'à expiration naturelle, mais le `JwtFilter` rejette désormais le user (filtre `disabled_at IS NULL`).

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 400 | `confirmed` non `true`, ou validation Bean | `{ "error": "CONFIRMATION_REQUIRED" }` ou `{ "error": "VALIDATION_FAILED", "details": {...} }` |
| 401 | JWT absent ou `currentPassword` incorrect | `{ "error": "UNAUTHORIZED" }` ou `{ "error": "PASSWORD_INCORRECT" }` |
| 403 | User est le dernier admin actif | `{ "error": "LAST_ADMIN_DELETION_FORBIDDEN", "message": "Au moins un administrateur actif doit exister." }` |

---

## Contrats composants

### Angular — `MonCompteComponent`

> Réf : FR-001, FR-002 + couvre toutes les US sauf US-003 et US-005 qui ouvrent des dialogs

| Aspect | Détail |
|--------|--------|
| Responsabilité | Page Mon compte avec 4 sections (Identité / Sécurité / Données / Zone de danger) |
| Fichier | `app/src/app/features/settings/account/mon-compte.component.ts` |
| Type | Standalone, OnPush, signals-first |

**Inputs** : Aucun (route /settings/account, lit le user via `AuthService`).

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| (aucun) | — | Composant racine de page, pas d'output |

**State interne (signals)** :
```typescript
private readonly authService = inject(AuthService);
private readonly userService = inject(UserService);
private readonly avatarService = inject(AvatarService);
private readonly userExportService = inject(UserExportService);
private readonly router = inject(Router);
private readonly dialog = inject(MatDialog); // ou ConfirmService

readonly currentUser = computed(() => this.authService.currentUser());
readonly avatarUrl = computed(() => this.avatarService.avatarUrl());
readonly isUploadingAvatar = signal(false);
readonly errorMessage = signal<string | null>(null);
```

---

### Angular — `AvatarUploadComponent` (lib)

> Réf : FR-004, FR-005, FR-006

| Aspect | Détail |
|--------|--------|
| Responsabilité | Composant réutilisable d'upload avatar avec preview et états (loading, error) |
| Fichier | `app/src/app/lib/avatar-upload/avatar-upload.component.ts` |
| Type | Standalone, OnPush, signals-first |

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| currentAvatarUrl | `InputSignal<string \| null>` | Oui | URL courante de l'avatar (null = initiales) |
| userInitials | `InputSignal<string>` | Oui | Initiales fallback (ex: "KS") |
| isUploading | `InputSignal<boolean>` | Non | État externe de chargement |

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| upload | `OutputEmitterRef<File>` | Émis quand l'utilisateur sélectionne un fichier valide (déjà filtré côté client : JPG/PNG, ≤ 2 MB) |
| delete | `OutputEmitterRef<void>` | Émis quand l'utilisateur clique sur "Supprimer la photo" |
| validationError | `OutputEmitterRef<string>` | Émis si validation client échoue (taille, format) avec message |

---

### Angular — `ChangePasswordDialogComponent`

> Réf : FR-008

| Aspect | Détail |
|--------|--------|
| Responsabilité | Dialog modal de changement de mot de passe |
| Fichier | `app/src/app/features/settings/account/change-password-dialog.component.ts` |
| Type | Standalone, OnPush |

**Inputs** : aucun direct (data via `MatDialogRef` ou pattern equivalent).

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| (close result) | `AuthResponse \| null` | Retour du dialog : nouveau auth response si succès, null si annulé |

---

### Angular — `DeleteAccountConfirmDialogComponent`

> Réf : FR-018

| Aspect | Détail |
|--------|--------|
| Responsabilité | Dialog modal de confirmation suppression compte (MDP + checkbox) |
| Fichier | `app/src/app/features/settings/account/delete-account-confirm-dialog.component.ts` |
| Type | Standalone, OnPush |

**Inputs** : aucun direct.

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| (close result) | `boolean` | `true` si suppression validée et exécutée avec succès, `false` sinon |

**Validation client** :
- Bouton "Supprimer mon compte" désactivé tant que MDP non saisi OU checkbox non cochée.

---

### Flutter — `AvatarPicker`

> Réf : FR-004, FR-005, FR-006

| Aspect | Détail |
|--------|--------|
| Responsabilité | Widget de sélection + compression + upload avatar |
| Fichier | `flutter/lib/src/features/user_profile/presentation/widgets/avatar_picker.dart` |
| Type | `ConsumerStatefulWidget` |

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| currentAvatarUrl | `String?` | Oui | URL courante de l'avatar |
| userInitials | `String` | Oui | Initiales fallback |
| onUploadSuccess | `VoidCallback?` | Non | Callback après upload réussi |

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| (callback `onUploadSuccess`) | `void` | Déclenché après réponse 200 de `POST /users/me/avatar` |

---

### Flutter — `ChangePasswordSheet`

> Réf : FR-008

| Aspect | Détail |
|--------|--------|
| Responsabilité | Bottom sheet de changement de mot de passe |
| Fichier | `flutter/lib/src/features/user_profile/presentation/widgets/change_password_sheet.dart` |
| Type | `ConsumerStatefulWidget` |

**Inputs** : aucun direct.

**Outputs / Events** : retour du `Navigator.pop(context, result)` :

| Type retour | Description |
|---|---|
| `AuthResponse?` | Auth response avec nouveau JWT/refresh si succès, `null` si annulé |

---

### Flutter — `DeleteAccountSheet`

> Réf : FR-018

| Aspect | Détail |
|--------|--------|
| Responsabilité | Bottom sheet de confirmation suppression compte |
| Fichier | `flutter/lib/src/features/user_profile/presentation/widgets/delete_account_sheet.dart` |
| Type | `ConsumerStatefulWidget` |

**Inputs** : aucun direct.

**Outputs / Events** : retour du `Navigator.pop(context, result)` :

| Type retour | Description |
|---|---|
| `bool` | `true` si suppression confirmée et exécutée avec succès, `false` sinon |

---

## Contrats services

### Backend — `AvatarStorageService`

> Réf : FR-004, FR-005, FR-006, NFR-002, NFR-006, NFR-008

| Aspect | Détail |
|--------|--------|
| Responsabilité | Validation, redimensionnement, stockage, lecture et suppression des avatars sur disque |
| Fichier | `api/src/main/java/fr/kksdev/budget/api/service/AvatarStorageService.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `store(User user, MultipartFile file)` | user (auth), file (multipart) | `String avatarPath` | `InvalidImageFormatException`, `FileTooLargeException`, `StorageException` | Valide MIME via magic numbers, redim 256x256 JPEG 85%, stocke `{path}/{user_id}.jpg`, met à jour `user.avatarPath` |
| `read(User user)` | user (auth) | `byte[]` | `AvatarNotFoundException` | Lit le fichier disque |
| `computeEtag(byte[] avatarBytes)` | bytes | `String` (8 chars hex) | — | SHA-256 du contenu, 8 premiers chars |
| `delete(User user)` | user (auth) | `void` | `AvatarNotFoundException` | Supprime fichier disque + nullifie `user.avatarPath` |

**Side effects** :
- Création automatique du dossier de stockage au démarrage (`@PostConstruct`).
- Toutes les méthodes loggent en INFO avec `userId` (FR-022).

---

### Backend — `UserPasswordService`

> Réf : FR-008, FR-009, FR-010, FR-023, FR-024, FR-025

| Aspect | Détail |
|--------|--------|
| Responsabilité | Changement de mot de passe avec révocation tokens et émission nouveau JWT |
| Fichier | `api/src/main/java/fr/kksdev/budget/api/service/UserPasswordService.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `changePassword(User user, ChangePasswordRequest req)` | user, req | `AuthResponse` | `PasswordIncorrectException`, `PasswordUnchangedException` | Vérifie current via BCrypt, hash new, persist, revoke refresh tokens, génère new JWT/refresh |

**Side effects** :
- Appelle `RefreshTokenService.revokeAllUserTokens(user)`.
- Génère nouveau JWT via `JwtUtil.generateToken`.
- Génère nouveau refresh token via `RefreshTokenService.generateRefreshToken`.
- Log INFO avec `userId`.

---

### Backend — `UserExportService`

> Réf : FR-014, FR-015, FR-016, FR-017, FR-017a, NFR-004

| Aspect | Détail |
|--------|--------|
| Responsabilité | Génération exports JSON et CSV des données du user |
| Fichier | `api/src/main/java/fr/kksdev/budget/api/service/UserExportService.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `exportJson(User user)` | user | `UserExportResponse` | — | Charge toutes les entités, mappe vers DTOs sécurisés (sans password) |
| `exportCsv(User user, OutputStream out)` | user, output stream | `void` | `IOException` | Écrit BOM UTF-8 + CSV via `CSVPrinter`, traduit Type en français, streame ligne par ligne |

**Side effects** :
- Charge depuis tous les repositories liés au user.
- Pour CSV : streaming progressif (pas de chargement complet en mémoire).
- Log INFO avec `userId` et `format`.

---

### Backend — `UserDeletionService`

> Réf : FR-018, FR-019, FR-020, FR-021, FR-022

| Aspect | Détail |
|--------|--------|
| Responsabilité | Soft-delete avec garde dernier admin et révocation tokens |
| Fichier | `api/src/main/java/fr/kksdev/budget/api/service/UserDeletionService.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `softDelete(User user, DeleteAccountRequest req)` | user, req | `void` | `PasswordIncorrectException`, `LastAdminDeletionForbiddenException`, `ConfirmationRequiredException` | Vérifie MDP, vérifie pas dernier admin si `user.isAdmin`, set `disabledAt = now()`, revoke refresh tokens |

**Side effects** :
- Appelle `RefreshTokenService.revokeAllUserTokens(user)`.
- Log INFO `"User {} soft-deleted (disabled_at={})"`.

---

### Backend — `ImageMimeValidator` (utility class)

> Réf : NFR-002

| Aspect | Détail |
|--------|--------|
| Responsabilité | Validation MIME via magic numbers |
| Fichier | `api/src/main/java/fr/kksdev/budget/api/util/ImageMimeValidator.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `static boolean isValidImage(MultipartFile file)` | file | `boolean` | — | Lit les premiers octets, vérifie signatures JPEG (`FF D8 FF`) ou PNG (`89 50 4E 47 0D 0A 1A 0A`) |
| `static String detectMimeType(MultipartFile file)` | file | `String` (MIME) ou `null` si non reconnu | — | Détecte "image/jpeg" ou "image/png" via magic numbers |

---

### Frontend Angular — `UserService` (étendu)

> Réf : FR-003, FR-008, FR-018

| Aspect | Détail |
|--------|--------|
| Responsabilité | Operations CRUD profil user (étendu avec change-password, delete-account) |
| Fichier | `app/src/app/core/services/user.service.ts` |

**Méthodes publiques (nouvelles)** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `updateProfile(req: UpdateProfileRequest)` | req | `Observable<UserInfo>` | HttpError | `PUT /users/me` |
| `changePassword(req: ChangePasswordRequest)` | req | `Observable<AuthResponse>` | HttpError 400/401 | `POST /users/me/password`. Sur succès, met à jour le state Auth (nouveau JWT/refresh) |
| `deleteAccount(req: DeleteAccountRequest)` | req | `Observable<void>` | HttpError 400/401/403 | `DELETE /users/me`. Sur succès, déclenche `authService.logout()` et redirect |

---

### Frontend Angular — `AvatarService` (nouveau)

> Réf : FR-004, FR-005, FR-006

| Aspect | Détail |
|--------|--------|
| Responsabilité | Gestion upload/get/delete avatar |
| Fichier | `app/src/app/core/services/avatar.service.ts` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `upload(file: File)` | file | `Observable<AvatarMetadata>` | HttpError 400/413/500 | `POST /users/me/avatar` (multipart) |
| `delete()` | — | `Observable<void>` | HttpError 401/404 | `DELETE /users/me/avatar` |
| `getUrl()` | — | `Signal<string \| null>` | — | URL relative `/api/users/me/avatar` (avec timestamp pour invalidation cache) ou null si pas d'avatar |

**State (signals)** :
```typescript
readonly avatarUrl = signal<string | null>(null);
readonly etag = signal<string | null>(null);
```

---

### Frontend Angular — `UserExportService` (nouveau)

> Réf : FR-014, FR-015

| Aspect | Détail |
|--------|--------|
| Responsabilité | Déclencher exports JSON et CSV avec download |
| Fichier | `app/src/app/core/services/user-export.service.ts` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `exportJson()` | — | `Observable<void>` | HttpError | `GET /users/me/export?format=json` + déclenche download via blob URL |
| `exportCsv()` | — | `Observable<void>` | HttpError | `GET /users/me/export?format=csv` + déclenche download |

---

### Flutter — `UserProfileRepository` (interface étendue)

> Réf : FR-003, FR-004, FR-006, FR-008, FR-014, FR-015, FR-018

| Aspect | Détail |
|--------|--------|
| Responsabilité | Interface abstraite repository profil user |
| Fichier | `flutter/lib/src/features/user_profile/domain/repositories/user_profile_repository.dart` |

**Méthodes publiques (nouvelles)** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `Future<void> uploadAvatar(File file)` | file | `void` | `ApiException` | `POST /users/me/avatar` |
| `Future<void> deleteAvatar()` | — | `void` | `ApiException` | `DELETE /users/me/avatar` |
| `Future<AuthResponse> changePassword(ChangePasswordRequest req)` | req | `AuthResponse` | `ApiException` 400/401 | `POST /users/me/password` |
| `Future<File> exportJson()` | — | `File` | `ApiException` | `GET /users/me/export?format=json`, sauvegarde locale |
| `Future<File> exportCsv()` | — | `File` | `ApiException` | `GET /users/me/export?format=csv`, sauvegarde locale |
| `Future<void> deleteAccount(DeleteAccountRequest req)` | req | `void` | `ApiException` 400/401/403 | `DELETE /users/me` |

**Note** : `UserProfileRepositoryRemote` est l'unique implémentation (pas de `Local`) — décision RES-013 (mode server-only).

---

## Codes d'erreur centralisés (récap)

| Code | HTTP | Source | FR concerné |
|---|---|---|---|
| `INVALID_IMAGE_FORMAT` | 400 | `AvatarStorageService` | FR-004, NFR-002 |
| `FILE_TOO_LARGE` | 413 | Multipart filter | FR-004, NFR-002 |
| `STORAGE_ERROR` | 500 | `AvatarStorageService` | FR-004 |
| `AVATAR_NOT_FOUND` | 404 | `AvatarStorageService` | FR-005, FR-006 |
| `PASSWORD_INCORRECT` | 401 | `UserPasswordService`, `UserDeletionService` | FR-009, FR-018 |
| `PASSWORD_UNCHANGED` | 400 | `UserPasswordService` | FR-010 |
| `CONFIRMATION_REQUIRED` | 400 | `UserDeletionService` | FR-018 |
| `LAST_ADMIN_DELETION_FORBIDDEN` | 403 | `UserDeletionService` | FR-021 |
| `INVALID_EXPORT_FORMAT` | 400 | `UserController` | FR-014/015 |
| `VALIDATION_FAILED` | 400 | Bean Validation global | tous flux avec DTO |
| `UNAUTHORIZED` | 401 | `JwtFilter` global | NFR-001 |

---

## Résumé

| Type | Nombre | Détail |
|------|--------|--------|
| Interfaces & Types | **13** | 5 DTOs Java backend (UpdateProfileRequest, ChangePasswordRequest, DeleteAccountRequest, AvatarMetadataResponse, UserExportResponse), 5 types TS Angular, 3 models Flutter |
| API Endpoints | **8** | 1 modifié (PUT /users/me), 7 nouveaux |
| Contrats composants | **7** | 4 Angular (MonCompteComponent, AvatarUploadComponent, ChangePasswordDialogComponent, DeleteAccountConfirmDialogComponent) + 3 Flutter (AvatarPicker, ChangePasswordSheet, DeleteAccountSheet) |
| Contrats services | **8** | 4 backend (AvatarStorageService, UserPasswordService, UserExportService, UserDeletionService) + 1 utility (ImageMimeValidator) + 3 frontend Angular (UserService, AvatarService, UserExportService) + Flutter (UserProfileRepository) |
| Codes d'erreur | **11** | Centralisés dans la table récap |
| FR couverts | **25/25** ✅ | FR-001 à FR-025 |
