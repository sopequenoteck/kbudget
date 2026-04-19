# Plan — KKS-232 : Onboarding contrôlé : flux d'invitation admin

> Date : 2026-04-19
> Issue : KKS-232
> Spec : [spec.md](./spec.md)
> Research : [research.md](./research.md)

---

## Constitution Check

> Vérification des 7 principes de `.specify/memory/constitution.md` (v2.1.2).

| Principe | Statut | Commentaire |
|---------|--------|-------------|
| I — API-First | PASS | Tous les FR P1 sont des endpoints REST (FR-003 à FR-011), DTOs records dédiés (`AcceptInviteRequest`, `InvitationResponse`, `AdminUserResponse`), `/api` context path respecté. Aucune entité JPA exposée. |
| II — Sécurité par défaut | PASS | JWT sur tous les endpoints sauf `/auth/accept-invite` et `/auth/invitations/:token` (permitAll justifié). BCrypt sur password (FR-010, NFR-005). Bean Validation (NFR-004). Isolation user préservée (NFR-003). `AdminAuthorizationFilter` + `ConflictException` → pas de stack traces exposées. |
| III — YAGNI | PASS | Pas de colonne `role` (admin via env var). Pas de pagination ni filtres serveur (CL-002). Pas de table audit (CL-003). Logique eager directement dans `AcceptInviteService` sans service intermédiaire (RES-001). |
| IV — Mobile-First UX | PASS | Page acceptation = 4 champs, 1 soumission, auto-login → dashboard. `Settings > Utilisateurs` en 2-3 taps (onglet Invitations + action `+ Inviter`). Flutter + Angular parité. |
| V — Testabilité | PASS | Tests d'intégration (endpoints publics + admin + filter). Tests unitaires (AdminService, InvitationService, garde-fou). Cas limites explicites (NFR-006, SC-003 à SC-013). Nommage `should_[résultat]_when_[condition]`. |
| VI — Observabilité | PASS | SLF4J INFO au format `"Admin action: <action> by <adminEmail> target=<resource>:<id>"` (NFR-002). WARN au boot pour `AdminEmailResolver` si mal configuré (NFR-008). Pas de `System.out.println`. |
| VII — Self-Hosted Ready | PASS | Aucune nouvelle dépendance Maven / npm / pub (research RES). PostgreSQL seule dépendance infra. Env var `ADMIN_EMAILS` en production. Pas de SMTP. Démarrage via `mvn spring-boot:run`. |

### Dérogations

Aucune dérogation aux principes de la constitution.

| Article | Dérogation | Justification |
|---------|------------|---------------|
| — | — | — |

### Complexity Tracking

| # | Complexité | Justification | Alternative envisagée |
|---|-----------|---------------|----------------------|
| CX-001 | Introduction d'un nouveau `OncePerRequestFilter` (`AdminAuthorizationFilter`) en plus du `JwtFilter` existant | Pattern déjà en place (`JwtFilter`). Alternative `@PreAuthorize` rejetée (RES-004) : principal du projet = `UUID`, résolution email → SpEL verbeux. Un filter unique centralise le check et évite d'oublier une route admin. | `@EnableMethodSecurity` + `@PreAuthorize("@adminEmailResolver.isAdminEmail(...)")` (RES-004 option A) |
| CX-002 | Suppression de `AuthService.register()` + DTO `RegisterRequest` + route `POST /auth/register` | Violation directe de la constitution v2.1.2 (principe VII + Contexte d'usage : "L'inscription publique N'EST PAS un objectif"). Retrait = condition de conformité. | Aucune — la constitution exige la suppression. |
| CX-003 | Supprimer `RegisterScreen` côté Flutter et son import dans `app_router.dart` | Symétrie avec la suppression backend. Supprimer plutôt que cacher évite du code mort. | Garder `RegisterScreen` et masquer la route — rejeté (code mort). |

## Résumé de l'approche

Suppression de l'inscription publique (`POST /auth/register`, `RegisterRequest`, `AuthService.register`, `RegisterScreen` Flutter, bouton "Créer un compte" Angular) et introduction d'un flux d'invitation admin en trois points : (a) **entité `Invitation`** avec token UUID v4 révocable en DB + colonne `disabled_at` sur `users`, (b) **couche admin** (`AdminEmailResolver` + `AdminAuthorizationFilter` + 6 endpoints `/api/admin/*`), (c) **endpoints publics** `/api/auth/invitations/:token` (vérif) et `/api/auth/accept-invite` (création User + Account + Preferences + Categories eager + JWT). Côté frontend : pages `Settings > Utilisateurs` sur Angular et Flutter avec flag `isAdmin` exposé par `GET /users/me` enrichi, et page publique `/accept-invite/:token` sur les deux fronts. Zéro nouvelle dépendance.

## Contexte technique

- **Stack** :
  - Backend : Spring Boot 4, Java 21, Maven, PostgreSQL 15+, Spring Security + JWT (jjwt), Spring Data JPA, Flyway, Lombok, Bean Validation
  - Frontend PWA : Angular 21+, TypeScript 5.9, SCSS tokens, signals-first, RxJS minimal
  - Mobile : Flutter ≥ 3.27, Dart ≥ 3.6, Riverpod, go_router, Dio, Freezed, json_serializable
- **Dépendances nouvelles** : **Aucune** (cf. research RES "Dépendances techniques" — principe VII).
- **Dépendances existantes impactées** :
  - Backend : `AuthService` (retrait `register`), `AuthController` (retrait endpoint), `JwtFilter` (ajout 1 filtre `disabled_at`), `SecurityConfig` (ajout filter admin + update `permitAll`), `UserResponse` (ajout `isAdmin`), `UserService.getProfile` (peuple `isAdmin`).
  - Angular : `auth.routes.ts` (ajout `accept-invite`, retrait `register`), `CurrentUserStore` / signal global (ajout `isAdmin`), menu `settings`, `ApiClient` (nouveaux endpoints).
  - Flutter : `app_router.dart` (ajout `acceptInvite`, retrait `register`), `RouteNames`, `UserModel` (regen Freezed avec `isAdmin`), `ApiClient Dio`, `dataModeProvider` n'est pas impacté (flux admin server-only).

## Architecture

### Structure des fichiers impactés

```
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── config/
│   │   ├── AdminEmailResolver.java                 # (C) composant config
│   │   ├── AdminAuthorizationFilter.java           # (C) OncePerRequestFilter
│   │   ├── JwtFilter.java                          # (M) filtre disabled_at
│   │   └── SecurityConfig.java                     # (M) +filter admin, +permitAll, retrait register
│   ├── controller/
│   │   ├── AuthController.java                     # (M) retrait register, ajout invitations/:token + accept-invite
│   │   ├── AdminInvitationController.java          # (C) /admin/invitations (POST, GET, DELETE)
│   │   └── AdminUserController.java                # (C) /admin/users (GET, PATCH disable/enable)
│   ├── service/
│   │   ├── AuthService.java                        # (M) retrait register
│   │   ├── AcceptInviteService.java                # (C) accept-invite logic (eager + usedAt)
│   │   ├── InvitationService.java                  # (C) create, list, revoke, validate
│   │   └── AdminUserService.java                   # (C) list, disable, enable (+ garde-fou dernier admin)
│   ├── model/
│   │   ├── User.java                               # (M) ajout disabled_at
│   │   └── Invitation.java                         # (C) entité JPA
│   ├── repository/
│   │   └── InvitationRepository.java               # (C) JpaRepository
│   ├── dto/
│   │   ├── request/
│   │   │   ├── AcceptInviteRequest.java            # (C) remplace RegisterRequest
│   │   │   ├── CreateInvitationRequest.java        # (C) { email }
│   │   │   └── RegisterRequest.java                # (D) supprimé
│   │   └── response/
│   │       ├── InvitationCreatedResponse.java      # (C) { token, expiresAt }
│   │       ├── InvitationResponse.java             # (C) list DTO (+status derived)
│   │       ├── AdminUserResponse.java              # (C) list DTO
│   │       ├── InviteLookupResponse.java           # (C) { email } pour GET /:token
│   │       └── UserResponse.java                   # (M) + isAdmin
│   ├── enums/
│   │   └── InvitationStatus.java                   # (C) ACTIVE/EXPIRED/USED/REVOKED
│   ├── exception/
│   │   └── (réutilise ConflictException, EntityNotFoundException)
│   └── service/UserService.java                    # (M) getProfile peuple isAdmin
├── src/main/resources/
│   ├── application.yaml                            # (M) app.admin-emails (défaut vide)
│   └── db/migration/
│       ├── V28__add_invitations.sql                # (C)
│       └── V29__add_user_disabled_at.sql           # (C)
└── src/test/java/fr/kksdev/budget/api/
    ├── service/
    │   ├── AcceptInviteServiceTest.java            # (C)
    │   ├── InvitationServiceTest.java              # (C)
    │   └── AdminUserServiceTest.java               # (C) garde-fou dernier admin
    ├── controller/
    │   ├── AdminInvitationControllerIT.java        # (C)
    │   ├── AdminUserControllerIT.java              # (C)
    │   └── AuthControllerIT.java                   # (M) cas accept-invite, lookup, suppression register
    └── config/
        ├── AdminAuthorizationFilterIT.java         # (C) matrice endpoints × rôles
        └── JwtFilterTest.java                      # (M) cas disabled_at

app/ (Angular)
├── src/app/
│   ├── features/auth/
│   │   ├── auth.routes.ts                          # (M) +accept-invite/:token, -register
│   │   ├── pages/
│   │   │   ├── accept-invite/
│   │   │   │   ├── accept-invite.ts                # (C) composant standalone
│   │   │   │   ├── accept-invite.html              # (C)
│   │   │   │   └── accept-invite.scss              # (C)
│   │   │   └── register/                           # (D) supprimé
│   │   └── services/auth.service.ts                # (M) -register(), +acceptInvite(), +lookupInvite()
│   ├── features/settings/
│   │   ├── settings.routes.ts                      # (M) +users
│   │   └── pages/users/
│   │       ├── users.ts                            # (C) page Settings > Utilisateurs
│   │       ├── users.html                          # (C)
│   │       └── users.scss                          # (C)
│   ├── core/
│   │   ├── services/admin.service.ts               # (C) HTTP client /admin/*
│   │   ├── services/invitation.service.ts          # (C) HTTP client invitations publiques
│   │   └── stores/current-user.store.ts            # (M) +isAdmin signal
│   └── shared/models/
│       ├── invitation.model.ts                     # (C) types
│       └── user.model.ts                           # (M) +isAdmin

flutter/lib/
├── src/
│   ├── routing/
│   │   ├── app_router.dart                         # (M) +acceptInvite route, redirect update, -register
│   │   └── route_names.dart                        # (M) +acceptInvite/acceptInviteName, -register
│   ├── features/
│   │   ├── auth/presentation/
│   │   │   ├── accept_invite_screen.dart           # (C)
│   │   │   └── register_screen.dart                # (D) supprimé
│   │   ├── admin/                                  # (C) nouvelle feature
│   │   │   ├── data/
│   │   │   │   ├── admin_repository.dart           # (C) abstract
│   │   │   │   ├── admin_remote_repository.dart    # (C) Dio impl (pas de Drift)
│   │   │   │   └── invitation_model.dart           # (C) Freezed
│   │   │   ├── application/
│   │   │   │   ├── invitations_notifier.dart       # (C)
│   │   │   │   └── admin_users_notifier.dart       # (C)
│   │   │   └── presentation/
│   │   │       ├── users_screen.dart               # (C) Settings > Utilisateurs
│   │   │       ├── invite_dialog.dart              # (C)
│   │   │       └── widgets/                        # (C) list items
│   │   └── settings/presentation/
│   │       └── settings_screen.dart                # (M) +tuile Utilisateurs (conditionnelle isAdmin)
│   └── features/user/data/user_model.dart          # (M) +isAdmin (regen Freezed)

docs/
├── deployment.md                                   # (M) doc ADMIN_EMAILS
├── api-examples.md                                 # (M) exemples invitations/accept-invite/admin
└── api-errors.md                                   # (M) LAST_ADMIN_CANNOT_BE_DISABLED
```

### Diagramme de flux

```
[Admin authentifié]
      |
      | 1. POST /api/admin/invitations { email }
      v
[AdminAuthorizationFilter] -> 401/403 si non-admin
      |
      v
[InvitationService.create]
  - UUID.randomUUID()
  - expiresAt = now + 7j
  - log INFO "Admin action: invitation.create by <adminEmail> target=invitation:<id>"
      |
      v
[ResponseEntity { token, expiresAt }]
      |
      v (admin copie le lien côté Angular/Flutter : origin + /auth/accept-invite/<token>)
      |
      v (transmission hors bande — Signal, SMS, face à face)
      |
[Invité clique sur le lien]
      |
      | 2. GET /api/auth/invitations/:token  (public)
      v
[InvitationService.validateToken]
  - if not found / expired / used / revoked -> 404
      |
      v
[ResponseEntity { email }]
      |
      v (formulaire : email lecture seule, password/displayName/currency/timezone)
      |
      | 3. POST /api/auth/accept-invite { token, password, displayName, currency, timezone }
      v
[AcceptInviteService.acceptInvite]  (@Transactional)
  - valide invitation (token actif)
  - userRepository.save(User)
  - categoryService.seedSystemCategories(user)
  - accountService.createDefaultAccount(user, currency)
  - preferenceService.createInitialPreference(user, currency, timezone)
  - invitation.usedAt = now
  - jwtUtil.generateToken + refreshTokenService.generateRefreshToken
  - log INFO "User onboarded via invitation: <email>"
      |
      v
[AuthResponse { token, refreshToken, email, name }]
      |
      v (auto-login → dashboard)


[Admin] -- PATCH /admin/users/:id/disable -->
      [AdminUserService.disable]
        - if id == currentAdmin && countActiveAdmins() == 1 -> ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED")  => 409
        - else user.disabledAt = now
      log INFO "Admin action: user.disable by <adminEmail> target=user:<id>"

[Requête authentifiée d'un user désactivé]
      |
      v
[JwtFilter]
  - token valide, email extrait
  - userRepository.findByEmail(email)
      .filter(u -> u.getDisabledAt() == null)   <-- check ajouté
      .ifPresent(...)
  - si filtré → pas d'auth posée → HttpStatusEntryPoint → 401
```

## Approche par composant

### Composant 1 — `AdminEmailResolver`

- **Responsabilité** : unique source de vérité pour "cet email est-il admin ?" (via property Spring `app.admin-emails`).
- **Fichiers** : `config/AdminEmailResolver.java` (C), `application.yaml` (M).
- **Requirements couverts** : FR-012.
- **Approche** :
  - Composant Spring `@Component`.
  - Injection `@Value("${app.admin-emails:}") List<String> rawAdminEmails` (split virgules natif Spring).
  - `@PostConstruct` : normaliser (trim + lowercase) → `Set<String> adminEmails` immutable.
  - API : `boolean isAdminEmail(String email)`, `Set<String> listAdminEmails()`.
  - Au boot : `if (adminEmails.isEmpty()) log.warn(...)` et aussi `if (noneMatch(user -> !user.isDisabled()))` via `UserRepository` (lecture défensive).
  - Couvre NFR-008 et Assumption A-002.

### Composant 2 — `AdminAuthorizationFilter`

- **Responsabilité** : bloquer en 403 les appels `/admin/**` de users authentifiés mais non-admin.
- **Fichiers** : `config/AdminAuthorizationFilter.java` (C), `config/SecurityConfig.java` (M).
- **Requirements couverts** : FR-019, SC-002.
- **Approche** :
  - `OncePerRequestFilter` dans le même package que `JwtFilter`.
  - Enregistré via `.addFilterAfter(adminAuthorizationFilter, JwtFilter.class)`.
  - Logique : si le path ne matche pas `/admin/**` → `filterChain.doFilter(...)` immédiat. Sinon, résoudre le principal (UUID) → `userRepository.findById(id)` → `AdminEmailResolver.isAdminEmail(user.email)`. Si false → `response.sendError(403)`. Si pas authentifié → `HttpStatusEntryPoint` s'en occupera (401 natif).

### Composant 3 — `Invitation` (entité + repository)

- **Responsabilité** : persistance de l'invitation.
- **Fichiers** : `model/Invitation.java` (C), `repository/InvitationRepository.java` (C), `enums/InvitationStatus.java` (C), migration Flyway `V28__add_invitations.sql` (C).
- **Requirements couverts** : FR-001, FR-013, FR-014.
- **Approche** :
  - Entité Lombok `@Data @Builder @NoArgsConstructor @AllArgsConstructor`, `@Entity @Table(name = "invitation")`.
  - Champs : `id` (Long, `@GeneratedValue`), `token` (UUID, `@Column(unique=true, nullable=false)`), `email` (String, nullable=false), `invitedBy` (ManyToOne User, FK `invited_by_user_id`), `expiresAt`, `usedAt`, `revokedAt`, `createdAt` (`@CreationTimestamp`).
  - Enum `InvitationStatus { ACTIVE, EXPIRED, USED, REVOKED }` — dérivé dans le DTO, pas stocké.
  - Repository : `findByToken(UUID)`, `findAllByOrderByCreatedAtDesc()`.

### Composant 4 — `InvitationService`

- **Responsabilité** : création / listage / validation / révocation.
- **Fichiers** : `service/InvitationService.java` (C), `exception/InvitationNotFoundException.java` ou réutilisation `EntityNotFoundException`.
- **Requirements couverts** : FR-003, FR-004, FR-005, FR-009, FR-013, FR-014.
- **Approche** :
  - `create(User invitedBy, String email)` → persist + log INFO.
  - `list()` → retourne `List<InvitationResponse>` avec `status` dérivé (ACTIVE si `revokedAt == null && usedAt == null && expiresAt > now`, EXPIRED si `expiresAt <= now`, etc.).
  - `revoke(Long id)` → set `revokedAt = now`, log INFO.
  - `validatePublic(UUID token)` → `Optional<Invitation>` uniquement si ACTIVE, sinon vide (404 côté controller).
  - `markUsed(Invitation inv)` → `usedAt = now`, appelé par `AcceptInviteService` sous transaction.

### Composant 5 — `AcceptInviteService`

- **Responsabilité** : exécuter l'onboarding complet à partir d'une invitation valide.
- **Fichiers** : `service/AcceptInviteService.java` (C), `service/AuthService.java` (M — retrait `register`), `dto/request/AcceptInviteRequest.java` (C), `dto/request/RegisterRequest.java` (D).
- **Requirements couverts** : FR-010, FR-011, FR-014, FR-015, FR-020 (ancre back).
- **Approche** :
  - `@Transactional public AuthResponse acceptInvite(AcceptInviteRequest req)`.
  - Récupère l'invitation via `InvitationService.validatePublic(req.token())`. 404 si absente.
  - Crée l'utilisateur en réutilisant la séquence exacte de `AuthService.register` (encode password, save user, `seedSystemCategories`, `createDefaultAccount`, `createInitialPreference`, `generateToken`, `generateRefreshToken`).
  - Appelle `InvitationService.markUsed`.
  - Log INFO `"User onboarded via invitation: {}"`.
  - Retourne `AuthResponse` identique au contrat actuel de `register`.
  - Pas de service intermédiaire d'onboarding (cf. RES-001).

### Composant 6 — `AdminUserService`

- **Responsabilité** : list / disable / enable users avec garde-fou dernier admin.
- **Fichiers** : `service/AdminUserService.java` (C), `dto/response/AdminUserResponse.java` (C).
- **Requirements couverts** : FR-006, FR-007, FR-008, FR-017.
- **Approche** :
  - `list()` → `List<AdminUserResponse>` (id, email, displayName, createdAt, disabledAt, isAdmin).
  - `disable(UUID id)` : si l'utilisateur cible a un email ∈ ADMIN_EMAILS ET est le seul admin actif (count via `userRepository.findAll().stream().filter(u -> adminEmailResolver.isAdminEmail(u.email) && u.disabledAt == null).count() == 1`), lever `ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED")` — mappé en 409 par `GlobalExceptionHandler`.
  - Sinon `user.disabledAt = now` + log INFO.
  - `enable(UUID id)` : `user.disabledAt = null` + log INFO.

### Composant 7 — Controllers admin + public

- **Responsabilité** : exposer les 8 endpoints (6 admin + 2 publics).
- **Fichiers** :
  - `controller/AdminInvitationController.java` (C) — `/admin/invitations` (POST, GET, DELETE).
  - `controller/AdminUserController.java` (C) — `/admin/users` (GET, PATCH disable, PATCH enable).
  - `controller/AuthController.java` (M) — ajout GET `invitations/:token`, POST `accept-invite` ; retrait POST `register`.
- **Requirements couverts** : FR-003 à FR-011, FR-018.
- **Approche** :
  - Annotations Swagger (`@Tag`, `@Operation`) alignées avec l'existant.
  - `Authentication` injecté pour obtenir `currentUserId` (UUID principal).
  - Retours : `ResponseEntity.status(201)` pour POST, `ResponseEntity.noContent()` pour DELETE/PATCH disable/enable, `ResponseEntity.ok(...)` pour GET.

### Composant 8 — `JwtFilter` + `UserResponse` + `/users/me`

- **Responsabilité** : bloquer les users désactivés et exposer le flag `isAdmin`.
- **Fichiers** : `config/JwtFilter.java` (M), `dto/response/UserResponse.java` (M), `service/UserService.java` (M).
- **Requirements couverts** : FR-016, FR-018, SC-007.
- **Approche** :
  - `JwtFilter` : ajouter `.filter(u -> u.getDisabledAt() == null)` avant `ifPresent`.
  - `UserResponse` : `(String name, String email, boolean isAdmin)`.
  - `UserService.getProfile(userId)` : inject `AdminEmailResolver`, peuple `isAdmin = resolver.isAdminEmail(user.email)`.

### Composant 9 — `SecurityConfig` update

- **Responsabilité** : permitAll sur nouvelles routes publiques, retrait de `/auth/register` implicite.
- **Fichiers** : `config/SecurityConfig.java` (M).
- **Requirements couverts** : FR-011 (ancre), FR-019 (via filter).
- **Approche** : `/auth/**` reste permitAll. La route `/auth/register` n'existe plus dans `AuthController`. Ajout `.addFilterAfter(adminAuthorizationFilter, JwtFilter.class)`.

### Composant 10 — Frontend Angular `Settings > Utilisateurs`

- **Responsabilité** : UI admin de gestion invitations + users, exposition flag `isAdmin`.
- **Fichiers** :
  - `features/settings/settings.routes.ts` (M), `features/settings/pages/users/*` (C).
  - `core/services/admin.service.ts` (C) — HTTP client.
  - `core/services/invitation.service.ts` (C).
  - `core/stores/current-user.store.ts` (M) — `isAdmin` signal.
  - `shared/models/invitation.model.ts` (C), `shared/models/user.model.ts` (M).
- **Requirements couverts** : FR-020, FR-024, US-011.
- **Approche** :
  - Composant standalone `OnPush` signals-first (pattern projet).
  - Deux sections dans une même page : "Invitations" (liste + bouton `+ Inviter` en bottom-sheet), "Utilisateurs" (liste + actions disable/enable).
  - Entrée de menu `Utilisateurs` dans `settings.routes.ts` avec garde frontend (`@if (currentUser.isAdmin())`) dans le composant Settings (pas de router guard — cf. RES-009, défense en profondeur seulement).
  - URL d'invitation composée côté client : `${location.origin}/auth/accept-invite/${token}` + `navigator.clipboard.writeText(...)`.
  - Design tokens `var(--...)` (pas de hex), patterns `_list-patterns.scss` et `_bottom-sheet.scss` (cf. CLAUDE.md).

### Composant 11 — Frontend Angular page publique `/auth/accept-invite/:token`

- **Responsabilité** : formulaire d'acceptation.
- **Fichiers** : `features/auth/auth.routes.ts` (M), `features/auth/pages/accept-invite/*` (C), `features/auth/services/auth.service.ts` (M).
- **Requirements couverts** : FR-022, US-002, US-013.
- **Approche** :
  - Route `{ path: 'accept-invite/:token', loadComponent: ... }` dans `AUTH_ROUTES`.
  - Composant standalone : `token = input.required<string>()` (ou lecture `ActivatedRoute.params`).
  - Au mount : `GET /auth/invitations/:token` → récupère email ; si 404 → page d'erreur "lien invalide / expiré / déjà utilisé".
  - Formulaire : email (disabled), password, displayName, currency (select), timezone (select préremplis).
  - Submit : `POST /auth/accept-invite` → stocke JWT via auth service existant → redirection `/dashboard`.
  - Suppression de `features/auth/pages/register` + lien "Créer un compte" sur la page de login.

### Composant 12 — Frontend Flutter `Settings > Utilisateurs`

- **Responsabilité** : parité Angular.
- **Fichiers** : `features/admin/*` (C), `features/settings/presentation/settings_screen.dart` (M), `features/user/data/user_model.dart` (M avec regen).
- **Requirements couverts** : FR-021, FR-024, US-012.
- **Approche** :
  - Feature dédiée `features/admin/` avec pattern projet : `data/` (repository abstrait + impl remote Dio, pas de Drift car données non mises en cache local), `application/` (Notifiers Riverpod `ListState<T>`), `presentation/` (screens + widgets).
  - `currentUserProvider` expose `user.isAdmin` → `SettingsScreen` affiche la tuile `Utilisateurs` conditionnellement.
  - Bouton `+ Inviter` ouvre un `showModalBottomSheet` avec champ email.
  - Copy-to-clipboard : `Clipboard.setData(ClipboardData(text: '${AppConfig.frontendBaseUrl}/auth/accept-invite/$token'))`.
  - Design tokens `AppColors`, `AppSpacing`, etc.

### Composant 13 — Frontend Flutter page publique `/accept-invite/:token`

- **Responsabilité** : formulaire d'acceptation.
- **Fichiers** : `routing/app_router.dart` (M), `routing/route_names.dart` (M), `features/auth/presentation/accept_invite_screen.dart` (C), `features/auth/presentation/register_screen.dart` (D).
- **Requirements couverts** : FR-023, US-002, US-013.
- **Approche** :
  - `RouteNames.acceptInvite = '/accept-invite/:token'` + `acceptInviteName`.
  - `redirect` global : exclure aussi `isAcceptInviteRoute` du forçage login.
  - Nouveau `GoRoute` utilise `state.pathParameters['token']`.
  - Écran `ConsumerStatefulWidget` — même flow que l'Angular (lookup au mount, form, submit → auto-login → go dashboard).
  - Suppression de `register_screen.dart` + import + routes `register` / `registerName`.

## Risques et mitigations

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| Migration prod Kelly : oubli de `ADMIN_EMAILS` dans l'env → aucun admin → deadlock opérationnel | Haut | Bas | WARN explicite au boot (NFR-008). Documentation `docs/deployment.md`. Kelly configure `ADMIN_EMAILS=so-pequeno@live.fr` avant déploiement. |
| Rupture contrat `UserResponse` (ajout `isAdmin`) côté Angular / Flutter | Moyen | Bas | Le champ est ajouté (non breaking) ; les consommateurs qui ne le lisent pas ignorent simplement le champ. Flutter : regen Freezed + json_serializable. |
| `AdminAuthorizationFilter` trop strict / trop permissif | Haut | Moyen | Test d'intégration matriciel (endpoints × rôles) : anonyme → 401, user non-admin → 403, admin → 200/201/204. `AdminAuthorizationFilterIT` couvre la matrice complète. |
| Double-usage d'un token via race condition (deux submits simultanés) | Moyen | Bas | Transaction `@Transactional` + `invitation.usedAt != null` checké à l'entrée et en fin (optimistic lock implicite via version ou second read). Sinon, UNIQUE constraint sur `(token, usedAt IS NULL)` n'est pas exprimable en Postgres simple ; accepter le risque faible (volume users très bas). |
| Suppression `POST /auth/register` casse les tests existants et potentiellement des clients externes | Haut | Haut | Inventaire tests à adapter (`AuthControllerIT.register_*`). Pas de client externe (self-hosted, instance Kelly). |
| Token UUID prédictible | Haut | Très bas | `UUID.randomUUID()` = v4 cryptographique. Lien transmis hors bande (A-001). |
| Lien transmis sur canal intercepté | Haut | Bas | Out of scope (A-001). TTL 7j + révocation manuelle (US-003). |
| Regen Freezed oubliée en Flutter → `UserModel.isAdmin` absent | Moyen | Moyen | Doc quickstart : `dart run build_runner build --delete-conflicting-outputs`. Check CI si présent. |

## Artefacts complémentaires

| Artefact | Fichier | Généré | Justification |
|----------|---------|--------|---------------|
| Research | [research.md](./research.md) | Oui | 10 inconnues techniques résolues avant le plan |
| Data Model | [data-model.md](./data-model.md) | Oui | 2 entités impliquées (`Invitation` nouvelle, `User` modifiée) + migrations Flyway |
| Quickstart | [quickstart.md](./quickstart.md) | Oui | Guide d'exécution du plan pour l'implémentation |

## Hors scope

- **Bootstrap du premier admin sur DB vide** (pour adoption par d'autres self-hosters) — ticket séparé.
- **Envoi automatique d'email** des invitations (SMTP) — viole principe VII en v1.
- **Rôles multiples** (`owner` / `admin` / `moderator`) — YAGNI, pas de besoin actuel.
- **Audit log dédié** (table `audit_log` ou stream externe) — logs SLF4J INFO suffisants (CL-003).
- **Pagination / filtres serveur** sur `GET /admin/invitations` — YAGNI v1 (CL-002).
- **Deep-linking natif** mobile Flutter pour `/accept-invite/:token` — le lien PWA Angular est le canal principal.
- **UI de rotation d'admin** (changer la liste `ADMIN_EMAILS` via UI) — géré par env var + redémarrage.
