# Contrats techniques — KKS-232 : Onboarding contrôlé

> Date : 2026-04-19
> Issue : KKS-232
> Plan : [plan.md](./plan.md)

---

## Interfaces & Types

### `Invitation` (entité JPA)

> Réf: FR-001, FR-013, FR-014

```java
@Entity
@Table(name = "invitation")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Invitation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private UUID token;

    @Column(nullable = false, length = 255)
    private String email;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invited_by_user_id", nullable = false)
    private User invitedBy;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;

    @Column(name = "revoked_at")
    private Instant revokedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
```

**Invariants** :
- `token` est unique et généré via `UUID.randomUUID()`.
- `usedAt` et `revokedAt` sont mutuellement exclusifs.
- `expiresAt = createdAt + 7 jours` (posé à la création).

### `InvitationStatus` (enum)

> Réf: FR-004

```java
public enum InvitationStatus {
    ACTIVE,    // revokedAt == null && usedAt == null && expiresAt > now
    EXPIRED,   // revokedAt == null && usedAt == null && expiresAt <= now
    USED,      // usedAt != null && revokedAt == null
    REVOKED    // revokedAt != null
}
```

### `User` (entité JPA — champ ajouté)

> Réf: FR-002, FR-016

```java
@Entity
@Table(name = "users")
public class User {
    // ... champs existants

    @Column(name = "disabled_at")
    private LocalDateTime disabledAt; // null = actif
}
```

### DTOs Request / Response backend

> Réf: FR-003, FR-009, FR-010, FR-011, FR-018

```java
// Public
public record CreateInvitationRequest(
    @Email @NotBlank String email
) {}

public record AcceptInviteRequest(
    @NotNull UUID token,
    @NotBlank @Size(min = 8, max = 100) String password,
    @NotBlank @Size(max = 100) String displayName,
    @NotNull Currency currency,
    @NotBlank String timezone
) {}

public record InvitationCreatedResponse(
    UUID token,
    Instant expiresAt
) {}

public record InviteLookupResponse(
    String email
) {}

public record InvitationResponse(
    Long id,
    String email,
    String invitedByEmail,
    InvitationStatus status,
    Instant createdAt,
    Instant expiresAt,
    Instant usedAt,
    Instant revokedAt
) {}

public record AdminUserResponse(
    UUID id,
    String email,
    String displayName,
    LocalDateTime createdAt,
    LocalDateTime disabledAt,
    boolean isAdmin
) {}

// Modifié (remplace RegisterRequest)
public record UserResponse(
    String name,
    String email,
    boolean isAdmin   // AJOUT
) {}
```

### Modèles frontend Angular

> Réf: FR-020, FR-022, FR-024

```typescript
// shared/models/invitation.model.ts
export type InvitationStatus = 'ACTIVE' | 'EXPIRED' | 'USED' | 'REVOKED';

export interface Invitation {
  id: number;
  email: string;
  invitedByEmail: string;
  status: InvitationStatus;
  createdAt: string;       // ISO
  expiresAt: string;       // ISO
  usedAt: string | null;
  revokedAt: string | null;
}

export interface InvitationCreated {
  token: string;           // UUID
  expiresAt: string;       // ISO
}

export interface CreateInvitationRequest {
  email: string;
}

export interface AcceptInviteRequest {
  token: string;
  password: string;
  displayName: string;
  currency: string;        // ISO 4217
  timezone: string;        // IANA
}

export interface InviteLookup {
  email: string;
}

// shared/models/user.model.ts (modifié)
export interface CurrentUser {
  name: string;
  email: string;
  isAdmin: boolean;        // AJOUT
}

export interface AdminUser {
  id: string;              // UUID
  email: string;
  displayName: string;
  createdAt: string;
  disabledAt: string | null;
  isAdmin: boolean;
}
```

### Modèles Flutter (Freezed)

> Réf: FR-021, FR-023, FR-024

```dart
// features/admin/data/invitation_model.dart
@freezed
class Invitation with _$Invitation {
  const factory Invitation({
    required int id,
    required String email,
    required String invitedByEmail,
    required InvitationStatus status,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
    DateTime? revokedAt,
  }) = _Invitation;

  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);
}

enum InvitationStatus { active, expired, used, revoked }

// features/admin/data/admin_user_model.dart
@freezed
class AdminUser with _$AdminUser {
  const factory AdminUser({
    required String id,
    required String email,
    required String displayName,
    required DateTime createdAt,
    DateTime? disabledAt,
    required bool isAdmin,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);
}

// features/user/data/user_model.dart (modifié — regen)
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String name,
    required String email,
    @Default(false) bool isAdmin,   // AJOUT
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

## API Endpoints

### `POST /api/admin/invitations`

> Réf: FR-003, US-001, SC-002

| Aspect | Détail |
|--------|--------|
| Méthode | POST |
| Path | `/api/admin/invitations` |
| Auth | JWT admin (via `AdminAuthorizationFilter`) |

**Request** :
```json
{
  "email": "string — email valide du futur invité"
}
```

**Response 201** :
```json
{
  "token": "uuid — UUID v4 à intégrer dans le lien",
  "expiresAt": "string — ISO 8601, createdAt + 7 jours"
}
```

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 400 | Email invalide (validation Bean Validation) | `{ "error": "MethodArgumentNotValid", "details": {...} }` |
| 401 | Non authentifié | _pas de body (HttpStatusEntryPoint)_ |
| 403 | Authentifié mais non-admin | `{ "error": "Forbidden" }` (sendError 403) |

---

### `GET /api/admin/invitations`

> Réf: FR-004, US-008

| Aspect | Détail |
|--------|--------|
| Méthode | GET |
| Path | `/api/admin/invitations` |
| Auth | JWT admin |

**Request** : aucun query param (CL-002 — pas de pagination ni filtres serveur).

**Response 200** :
```json
[
  {
    "id": 42,
    "email": "new@example.com",
    "invitedByEmail": "admin@example.com",
    "status": "ACTIVE",
    "createdAt": "2026-04-19T12:00:00Z",
    "expiresAt": "2026-04-26T12:00:00Z",
    "usedAt": null,
    "revokedAt": null
  }
]
```

**Tri** : `createdAt DESC`.

**Erreurs** : 401 / 403 (cf. ci-dessus).

---

### `DELETE /api/admin/invitations/{id}`

> Réf: FR-005, US-003, SC-005

| Aspect | Détail |
|--------|--------|
| Méthode | DELETE |
| Path | `/api/admin/invitations/{id}` |
| Auth | JWT admin |

**Response 204** : No Content. Positionne `revokedAt = now`.

**Erreurs** :
| Code | Description | Body |
|------|-------------|------|
| 404 | Invitation inexistante | `{ "error": "EntityNotFoundException", "message": "..." }` |
| 401 / 403 | cf. ci-dessus | |

---

### `GET /api/admin/users`

> Réf: FR-006, US-009

| Aspect | Détail |
|--------|--------|
| Méthode | GET |
| Path | `/api/admin/users` |
| Auth | JWT admin |

**Response 200** :
```json
[
  {
    "id": "9fc3...-uuid",
    "email": "user@example.com",
    "displayName": "Alice",
    "createdAt": "2026-02-01T10:30:00",
    "disabledAt": null,
    "isAdmin": false
  }
]
```

**Tri** : `createdAt ASC` (ordre d'arrivée).

---

### `PATCH /api/admin/users/{id}/disable`

> Réf: FR-007, FR-017, US-004, US-007, SC-007, SC-008

| Aspect | Détail |
|--------|--------|
| Méthode | PATCH |
| Path | `/api/admin/users/{id}/disable` |
| Auth | JWT admin |

**Response 204** : No Content. Positionne `disabled_at = now`.

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 404 | User inexistant | `{ "error": "EntityNotFoundException", "message": "..." }` |
| 409 | Dernier admin actif — ne peut pas se désactiver | `{ "error": "LAST_ADMIN_CANNOT_BE_DISABLED", "message": "Impossible de désactiver le dernier admin actif." }` |
| 401 / 403 | cf. ci-dessus | |

---

### `PATCH /api/admin/users/{id}/enable`

> Réf: FR-008, US-005, SC-013

| Aspect | Détail |
|--------|--------|
| Méthode | PATCH |
| Path | `/api/admin/users/{id}/enable` |
| Auth | JWT admin |

**Response 204** : No Content. Positionne `disabled_at = NULL`.

**Erreurs** : 404 si user inexistant. 401 / 403.

---

### `GET /api/auth/invitations/{token}`

> Réf: FR-009, US-002, US-003, SC-005

| Aspect | Détail |
|--------|--------|
| Méthode | GET |
| Path | `/api/auth/invitations/{token}` |
| Auth | **Public** (permitAll) |

**Response 200** :
```json
{
  "email": "new@example.com"
}
```

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 404 | Token inexistant / expiré / utilisé / révoqué (indifférencié pour ne pas fuiter l'état) | `{ "error": "EntityNotFoundException", "message": "Invitation invalide." }` |

---

### `POST /api/auth/accept-invite`

> Réf: FR-010, FR-014, FR-015, US-002, SC-004, SC-006, SC-012

| Aspect | Détail |
|--------|--------|
| Méthode | POST |
| Path | `/api/auth/accept-invite` |
| Auth | **Public** (permitAll) |

**Request** :
```json
{
  "token": "uuid — token d'invitation",
  "password": "string — min 8 caractères",
  "displayName": "string — max 100 caractères",
  "currency": "string — enum Currency (ISO 4217)",
  "timezone": "string — IANA (ex: Europe/Paris)"
}
```

> **Important** : le champ `email` n'existe pas dans le body. L'email vient de l'invitation (FR-015). Toute valeur `email` dans le body est ignorée.

**Response 201** :
```json
{
  "token": "string — JWT access token",
  "refreshToken": "string — refresh token",
  "email": "string — email hérité de l'invitation",
  "name": "string — displayName fourni"
}
```

**Erreurs** :

| Code | Description | Body |
|------|-------------|------|
| 400 | Validation échouée (password trop court, currency inconnue, etc.) | `{ "error": "MethodArgumentNotValid", "details": {...} }` |
| 404 | Invitation inexistante / expirée / utilisée / révoquée | `{ "error": "EntityNotFoundException", "message": "Invitation invalide." }` |

---

### `GET /api/users/me` (contrat modifié)

> Réf: FR-018, US-010, SC-011

| Aspect | Détail |
|--------|--------|
| Méthode | GET |
| Path | `/api/users/me` |
| Auth | JWT |

**Response 200** :
```json
{
  "name": "string",
  "email": "string",
  "isAdmin": true
}
```

**Changement** : ajout du champ `isAdmin` (boolean). Non-breaking pour les consommateurs qui ignorent le champ.

---

### `POST /api/auth/register` — **supprimé**

> Réf: FR-011, SC-001

Retourne 404 (route inexistante). Tout client appelant cette route doit migrer vers `POST /api/auth/accept-invite`.

## Contrats composants

### Angular — `AcceptInvite` (page publique)

> Réf: FR-022, US-002, US-013

| Aspect | Détail |
|--------|--------|
| Responsabilité | Formulaire d'acceptation d'invitation (lookup email + saisie user) |
| Fichier | `app/src/app/features/auth/pages/accept-invite/accept-invite.ts` |
| Type | Standalone, `ChangeDetectionStrategy.OnPush`, signals |

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `token` | `string` | Oui | Lu depuis `ActivatedRoute.params` ou `input.required<string>()` |

**State interne** (signals) :

| Signal | Type | Description |
|--------|------|-------------|
| `loading` | `signal<boolean>` | true pendant lookup ou submit |
| `email` | `signal<string \| null>` | Email récupéré au mount (lookup), null tant que non chargé |
| `error` | `signal<string \| null>` | Message d'erreur si token invalide |

**Flow** :
- `ngOnInit` / effect : `invitationService.lookup(token())` → si 404, `error` = "Lien invalide" ; sinon `email.set(resp.email)`.
- Submit : `authService.acceptInvite({ token, password, displayName, currency, timezone })` → stockage JWT → `router.navigate(['/dashboard'])`.

**Outputs / Events** : aucun (page terminale).

---

### Angular — `Users` (page `Settings > Utilisateurs`)

> Réf: FR-020, FR-024, US-011

| Aspect | Détail |
|--------|--------|
| Responsabilité | UI admin — liste invitations + liste users + actions |
| Fichier | `app/src/app/features/settings/pages/users/users.ts` |
| Type | Standalone, OnPush, signals |

**Inputs** : aucun (route feuille).

**State interne** (signals) :

| Signal | Type | Description |
|--------|------|-------------|
| `invitations` | `signal<Invitation[]>` | via `adminService.listInvitations()` |
| `users` | `signal<AdminUser[]>` | via `adminService.listUsers()` |
| `activeTab` | `signal<'invitations' \| 'users'>` | onglet courant |

**Actions** :

| Action | Signature | Description |
|--------|-----------|-------------|
| `onInvite(email)` | `(email: string) => void` | `adminService.createInvitation({email})` → reload + copie du lien |
| `onCopyLink(token)` | `(token: string) => void` | `navigator.clipboard.writeText(\`${location.origin}/auth/accept-invite/${token}\`)` |
| `onRevoke(id)` | `(id: number) => void` | `adminService.revokeInvitation(id)` → reload |
| `onDisable(id)` | `(id: string) => void` | `adminService.disableUser(id)` → reload |
| `onEnable(id)` | `(id: string) => void` | `adminService.enableUser(id)` → reload |

**Outputs / Events** : aucun.

---

### Flutter — `AcceptInviteScreen`

> Réf: FR-023, US-002, US-013

| Aspect | Détail |
|--------|--------|
| Responsabilité | Formulaire d'acceptation (mobile) |
| Fichier | `flutter/lib/src/features/auth/presentation/accept_invite_screen.dart` |
| Type | `ConsumerStatefulWidget` |

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `token` | `String` | Oui | Via `state.pathParameters['token']` dans `GoRoute` |

**Providers consommés** :
- `invitationLookupProvider(token)` — `FutureProvider.family`
- `authControllerProvider` — pour `acceptInvite`

**Flow** : lookup → affichage formulaire avec email lecture seule → submit → auto-login → `context.go('/dashboard')`.

---

### Flutter — `UsersScreen` (Settings > Utilisateurs)

> Réf: FR-021, FR-024, US-012

| Aspect | Détail |
|--------|--------|
| Responsabilité | Parité fonctionnelle avec Angular `Users` |
| Fichier | `flutter/lib/src/features/admin/presentation/users_screen.dart` |
| Type | `ConsumerStatefulWidget` |

**Providers consommés** :
- `invitationsNotifierProvider` — `NotifierProvider<InvitationsNotifier, ListState<Invitation>>`
- `adminUsersNotifierProvider` — `NotifierProvider<AdminUsersNotifier, ListState<AdminUser>>`
- `currentUserProvider` — pour cacher la tuile si non-admin

**Actions** : mêmes que Angular, appels vers `AdminRepository` via notifiers.

## Contrats services

### Backend — `AdminEmailResolver`

> Réf: FR-012, NFR-008, US-006

| Aspect | Détail |
|--------|--------|
| Responsabilité | Source unique de vérité "cet email est-il admin ?" |
| Fichier | `api/src/main/java/fr/kksdev/budget/api/config/AdminEmailResolver.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `isAdminEmail(email)` | `String email` | `boolean` | — | Compare l'email (trim lowercase) à la liste normalisée. |
| `listAdminEmails()` | — | `Set<String>` | — | Retourne le set normalisé immutable. |

---

### Backend — `InvitationService`

> Réf: FR-003, FR-004, FR-005, FR-009, FR-013, FR-014

| Aspect | Détail |
|--------|--------|
| Responsabilité | CRUD invitations + validation token |
| Fichier | `api/.../service/InvitationService.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `create(invitedBy, email)` | `User, String` | `Invitation` | — | Génère UUID v4, expiresAt = now+7j, persiste, log INFO. |
| `list()` | — | `List<InvitationResponse>` | — | Tri createdAt DESC, statut dérivé. |
| `revoke(id)` | `Long` | `void` | `EntityNotFoundException` | Positionne `revokedAt=now`, log INFO. |
| `validatePublic(token)` | `UUID` | `Optional<Invitation>` | — | Retourne l'invitation uniquement si `ACTIVE`. |
| `markUsed(invitation)` | `Invitation` | `void` | — | Positionne `usedAt=now` (appelé par `AcceptInviteService` sous transaction). |
| `deriveStatus(invitation)` | `Invitation` | `InvitationStatus` | — | Calcul pur (REVOKED > USED > EXPIRED > ACTIVE). |

---

### Backend — `AcceptInviteService`

> Réf: FR-010, FR-014, FR-015, US-002

| Aspect | Détail |
|--------|--------|
| Responsabilité | Onboarding complet à partir d'un token valide |
| Fichier | `api/.../service/AcceptInviteService.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `acceptInvite(request)` | `AcceptInviteRequest` | `AuthResponse` | `EntityNotFoundException` (token invalide), `IllegalArgumentException` (email déjà user) | `@Transactional` : validate → save User → seedCategories → createAccount → createPreference → markUsed → JWT + refresh. |

---

### Backend — `AdminUserService`

> Réf: FR-006, FR-007, FR-008, FR-017

| Aspect | Détail |
|--------|--------|
| Responsabilité | List + disable/enable users avec garde-fou |
| Fichier | `api/.../service/AdminUserService.java` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `list()` | — | `List<AdminUserResponse>` | — | Tri createdAt ASC, peuple `isAdmin`. |
| `disable(userId)` | `UUID` | `void` | `EntityNotFoundException`, `ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED")` | Garde-fou + set `disabled_at=now`. |
| `enable(userId)` | `UUID` | `void` | `EntityNotFoundException` | Set `disabled_at=null`. |
| `countActiveAdmins()` | — | `long` | — | Helper interne (peut être privé selon impl). |

---

### Backend — `AdminAuthorizationFilter`

> Réf: FR-019, US-006, SC-002

| Aspect | Détail |
|--------|--------|
| Responsabilité | 403 sur `/admin/**` pour users authentifiés non-admin |
| Fichier | `api/.../config/AdminAuthorizationFilter.java` |

**Contrat** (public via `doFilterInternal`) :

| Aspect | Détail |
|--------|--------|
| Matcher | `request.getRequestURI().startsWith("/admin/")` (ou helper approprié après stripping context path `/api`) |
| Si pas matché | `filterChain.doFilter(request, response)` |
| Si matché + non authentifié | `filterChain.doFilter` → `HttpStatusEntryPoint` renverra 401 |
| Si matché + authentifié non-admin | `response.sendError(HttpStatus.FORBIDDEN.value())` + log WARN |
| Si matché + admin | `filterChain.doFilter` → accès accordé |

---

### Frontend Angular — `AdminService`

> Réf: FR-003 à FR-008

| Aspect | Détail |
|--------|--------|
| Responsabilité | HTTP client typé pour `/admin/*` |
| Fichier | `app/src/app/core/services/admin.service.ts` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `createInvitation(req)` | `CreateInvitationRequest` | `Observable<InvitationCreated>` | 400, 403 | POST /admin/invitations |
| `listInvitations()` | — | `Observable<Invitation[]>` | 403 | GET /admin/invitations |
| `revokeInvitation(id)` | `number` | `Observable<void>` | 404, 403 | DELETE /admin/invitations/{id} |
| `listUsers()` | — | `Observable<AdminUser[]>` | 403 | GET /admin/users |
| `disableUser(id)` | `string (UUID)` | `Observable<void>` | 404, 409, 403 | PATCH /admin/users/{id}/disable — 409 mappé côté UI avec toast spécifique |
| `enableUser(id)` | `string (UUID)` | `Observable<void>` | 404, 403 | PATCH /admin/users/{id}/enable |

---

### Frontend Angular — `InvitationService` (public)

> Réf: FR-009, FR-010

| Aspect | Détail |
|--------|--------|
| Responsabilité | HTTP client public pour lookup + accept |
| Fichier | `app/src/app/core/services/invitation.service.ts` |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `lookup(token)` | `string` | `Observable<InviteLookup>` | 404 | GET /auth/invitations/{token} |
| `accept(req)` | `AcceptInviteRequest` | `Observable<AuthResponse>` | 400, 404 | POST /auth/accept-invite |

---

### Frontend Angular — `CurrentUserStore`

> Réf: FR-018, FR-024, US-010

| Aspect | Détail |
|--------|--------|
| Responsabilité | State global user courant (signals) |
| Fichier | `app/src/app/core/stores/current-user.store.ts` |

**Signals exposés** :

| Signal | Type | Description |
|--------|------|-------------|
| `user` | `Signal<CurrentUser \| null>` | Utilisateur chargé après login / refresh |
| `isAdmin` | `Signal<boolean>` | Computed de `user()?.isAdmin ?? false` |

**Méthodes** :

| Méthode | Paramètres | Retour | Description |
|---------|------------|--------|-------------|
| `loadMe()` | — | `Observable<CurrentUser>` | `GET /users/me` → set signal |
| `clear()` | — | `void` | Sur logout |

---

### Frontend Flutter — `AdminRepository`

> Réf: FR-003 à FR-008, FR-021

| Aspect | Détail |
|--------|--------|
| Responsabilité | Contrat d'accès (remote-only, pas de Drift) |
| Fichier | `flutter/lib/src/features/admin/data/admin_repository.dart` (interface) + `admin_remote_repository.dart` (impl Dio) |

**Méthodes publiques** :

| Méthode | Paramètres | Retour | Erreurs | Description |
|---------|------------|--------|---------|-------------|
| `createInvitation(email)` | `String` | `Future<InvitationCreated>` | `DioException` | POST |
| `listInvitations()` | — | `Future<List<Invitation>>` | | GET |
| `revokeInvitation(id)` | `int` | `Future<void>` | | DELETE |
| `listUsers()` | — | `Future<List<AdminUser>>` | | GET |
| `disableUser(id)` | `String` | `Future<void>` | DioException 409 propagée (UI affiche snackbar) | PATCH |
| `enableUser(id)` | `String` | `Future<void>` | | PATCH |

---

### Frontend Flutter — `InvitationsNotifier` / `AdminUsersNotifier`

> Réf: FR-021, US-008, US-009

Pattern projet : `Notifier<ListState<T>>` avec `loadItems`, `create`, `update`, `delete`, `loadMore` (non utilisé ici — pas de pagination). État immutable Freezed (`ListState<Invitation>`, `ListState<AdminUser>`).

**Méthodes publiques `InvitationsNotifier`** :

| Méthode | Paramètres | Retour | Description |
|---------|------------|--------|-------------|
| `loadItems()` | — | `Future<void>` | Peuple `state.items` |
| `createInvitation(email)` | `String` | `Future<InvitationCreated>` | Retourne pour permettre copie du lien |
| `revoke(id)` | `int` | `Future<void>` | Optimistic UI (mutating IDs) |

**Méthodes publiques `AdminUsersNotifier`** :

| Méthode | Paramètres | Retour | Description |
|---------|------------|--------|-------------|
| `loadItems()` | — | `Future<void>` | |
| `disable(id)` | `String` | `Future<void>` | Catch 409 → propager pour UI |
| `enable(id)` | `String` | `Future<void>` | |

## Résumé

| Type | Nombre |
|------|--------|
| Interfaces & Types | 14 (2 entités JPA, 1 enum, 7 DTOs backend, 4 modèles Angular/Flutter hors duplicats) |
| API Endpoints | 9 (8 nouveaux + 1 modifié) |
| Contrats composants | 4 (2 Angular, 2 Flutter) |
| Contrats services | 9 (4 backend, 3 Angular, 2 Flutter) |
| FR couverts | 24 sur 24 (FR-001 à FR-024) |
