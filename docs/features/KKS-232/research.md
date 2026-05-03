# Research — KKS-232 : Onboarding contrôlé : flux d'invitation admin

> Date : 2026-04-19
> Issue : KKS-232
> Spec : [spec.md](./spec.md)
> Clarify : [clarify-log.md](./clarify-log.md)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Backend — Architecture | Où héberger la logique eager `User + Categories + Account + Preferences + RefreshToken` actuellement inline dans `AuthService.register()` ? | Haute |
| RES-002 | Backend — Sécurité | Comment intégrer le check `disabled_at` dans `JwtFilter` sans casser le flow existant ? | Haute |
| RES-003 | Backend — Config | Mécanisme Spring pour charger `ADMIN_EMAILS` : `@Value` simple vs `@ConfigurationProperties` ? | Moyenne |
| RES-004 | Backend — Sécurité | Protection des endpoints `/api/admin/*` : `@PreAuthorize` method security vs filter HTTP custom ? | Haute |
| RES-005 | Backend — API | Enrichissement du flag `isAdmin` : étendre `UserResponse` (`GET /users/me`) ou créer endpoint dédié ? | Basse |
| RES-006 | Backend — DB | Numéro de migration Flyway pour `invitation` + `disabled_at` | Basse |
| RES-007 | Frontend Angular | Exposer la page `/accept-invite/:token` hors `authGuard` sans casser la structure `/auth/**` | Moyenne |
| RES-008 | Frontend Flutter | Exposer la route `/accept-invite/:token` dans le `GoRouter` avec `redirect` global actuel | Moyenne |
| RES-009 | Frontend — UX | Affichage conditionnel de la section `Settings > Utilisateurs` selon `isAdmin` (Angular + Flutter) | Basse |
| RES-010 | Frontend — URL | Format du lien d'invitation (origin à utiliser, Angular vs Flutter deep-link) | Moyenne |

---

## Décisions techniques

### RES-001 — Hébergement de la logique d'onboarding eager

- **Contexte** : `AuthService.register()` (cf. `api/src/main/java/fr/kksdev/budget/api/service/AuthService.java:30-52`) contient inline la séquence eager : `UserRepository.save` → `CategoryService.seedSystemCategories` → `AccountService.createDefaultAccount` → `PreferenceService.createInitialPreference` → `JwtUtil.generateToken` + `RefreshTokenService.generateRefreshToken`. La feature KKS-232 supprime `POST /auth/register` et introduit `POST /auth/accept-invite` qui doit exécuter la même séquence mais avec un paramètre supplémentaire (`invitation.token` à marquer `usedAt`). L'Assumption A-003 envisageait une factorisation : la lecture du code confirme que cette factorisation **n'existe pas**.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Déplacer la logique directement dans `AcceptInviteService` (nouveau service) | Pas de service intermédiaire — YAGNI, un seul appelant après suppression de `register` | Si besoin futur (bootstrap admin, etc.), on duplique | **3/5** |
| B — Extraire une méthode privée `createUserWithDefaults(email, password, name, currency, timezone)` dans `AuthService` et l'appeler depuis `AcceptInviteService` via injection | Factorisation légère, `AuthService` garde la cohésion auth | `AuthService` devient dépendance d'`AcceptInviteService` (couplage cross-service) | 2/5 |
| C — Créer un nouveau service `OnboardingService` dédié, consommé par `AcceptInviteService` (et préparé pour futur bootstrap-admin) | Séparation des responsabilités claire, réutilisable | Sur-ingénierie pour un seul consommateur v1 (principe III) | 2/5 |

- **Décision** : **Option A** — la logique migre intégralement dans `AcceptInviteService.acceptInvite(AcceptInviteRequest)`. `AuthService` conserve uniquement `login()`.
- **Rationale** : Principe III (YAGNI). Un seul consommateur en v1 (le flux d'invitation). Si le bootstrap admin (hors scope) arrive plus tard, on extraira à ce moment-là (principe "trois lignes similaires valent mieux qu'une abstraction prématurée"). La suppression parallèle de `AuthService.register` évite la duplication.
- **Alternatives rejetées** : B et C — coût architectural non justifié pour un seul appelant.
- **Impact sur le plan** :
  - Supprimer `AuthService.register()` et `RegisterRequest`.
  - Créer `AcceptInviteService.acceptInvite(AcceptInviteRequest)` avec la séquence eager + validation invitation + marquage `usedAt` dans une même `@Transactional`.
  - Tests : migrer les cas nominaux de `AuthServiceTest.register` vers `AcceptInviteServiceTest`.

### RES-002 — Check `disabled_at` dans `JwtFilter`

- **Contexte** : `JwtFilter.doFilterInternal` (cf. `api/src/main/java/fr/kksdev/budget/api/config/JwtFilter.java:28-57`) extrait l'email depuis le JWT, charge le user via `UserRepository.findByEmail(email)` et pose l'authentification dans le SecurityContext si présent. Le spec exige : si `user.disabled_at IS NOT NULL`, renvoyer 401 sans authentifier.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Filtrer dans le `ifPresent` : ne poser l'auth que si `user.getDisabledAt() == null` | Modification minimale d'une seule ligne, pas de 401 explicite (laisse `HttpStatusEntryPoint` faire) | Le user invalide traverse la chaîne → 401 natif via `authenticationEntryPoint` sur route protégée. Sur route publique, pas de 401 (mais c'est le comportement attendu) | **4/5** |
| B — Écrire un 401 explicite directement dans le filtre si `disabled_at` non null | Contrat HTTP explicite | Bypass du `HttpStatusEntryPoint` déjà configuré, double gestion de la réponse | 2/5 |
| C — Nouveau filter dédié `DisabledUserFilter` après `JwtFilter` | Séparation des responsabilités | Sur-ingénierie : le check tient en 1 condition | 2/5 |

- **Décision** : **Option A** — ajouter un `.filter(user -> user.getDisabledAt() == null)` avant `.ifPresent(...)` dans `JwtFilter`.
- **Rationale** : Principe III + le `HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)` déjà configuré dans `SecurityConfig` garantit le 401 natif sur route protégée sans code supplémentaire. Un user désactivé = user inconnu du point de vue auth.
- **Alternatives rejetées** : B casse le pattern existant, C est prématuré.
- **Impact sur le plan** :
  - Modifier `JwtFilter` : 1 ligne (ajout du filter Optional).
  - Ajouter log INFO `"User authentication blocked (disabled): {}"` pour observabilité.
  - Test d'intégration dédié (SC-007) : JWT valide + user `disabled_at` non null → 401.

### RES-003 — Chargement de `app.admin-emails`

- **Contexte** : Le codebase utilise `@Value("${app.jwt.secret}")` (cf. `JwtUtil.java:20`) et `@Value("${app.cors.allowed-origins:...}")` avec binding `List<String>` (cf. `SecurityConfig.java:32-33`). Pas de `@ConfigurationProperties` existant.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `@Value("${app.admin-emails:}") List<String>` dans `AdminEmailResolver` | Pattern existant (`cors.allowed-origins`), aucune nouvelle classe | Coupling direct à la chaîne de property | **5/5** |
| B — Classe `@ConfigurationProperties("app")` typée (AdminProperties) | Type safety Spring | Introduit un pattern nouveau pour une seule property — inutile | 2/5 |

- **Décision** : **Option A** — `@Value("${app.admin-emails:}") List<String> adminEmails` dans un composant `AdminEmailResolver`.
- **Rationale** : Cohérence avec le pattern `cors.allowed-origins` déjà présent. Binding `List<String>` natif via virgules (Spring split automatique). Principe III.
- **Alternatives rejetées** : B (pas de bénéfice pour 1 property).
- **Impact sur le plan** :
  - Créer `fr.kksdev.budget.api.config.AdminEmailResolver` (composant Spring).
  - Normaliser les emails (trim + lowercase) au constructeur via `@PostConstruct`.
  - Ajouter la property dans `application.yaml` (défaut vide) et documenter `ADMIN_EMAILS` dans `docs/deployment.md`.
  - API publique de `AdminEmailResolver` : `isAdminEmail(String email)`, `listAdminEmails()`.

### RES-004 — Protection des endpoints `/api/admin/*`

- **Contexte** : `SecurityConfig` (cf. `config/SecurityConfig.java:42-48`) utilise `requestMatchers(...).permitAll()` et `anyRequest().authenticated()` — pas d'autorisation plus fine. Les endpoints admin doivent renvoyer 403 pour un non-admin authentifié.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `@PreAuthorize` via `@EnableMethodSecurity` + SpEL `@adminEmailResolver.isAdminEmail(authentication.principal)` | Annotation expressive, activation fine par méthode | Nécessite d'activer `@EnableMethodSecurity` (nouveau), SpEL verbeux, `authentication.principal` est un `UUID` dans ce projet (cf. `JwtFilter:46-47`) — il faut résoudre l'email depuis `UserRepository` | 3/5 |
| B — Filter HTTP custom `AdminAuthorizationFilter` sur `/api/admin/*` après `JwtFilter` | Pattern aligné avec `JwtFilter`, traite tous les endpoints admin en un point unique, 403 natif | Une autre couche de filter | **5/5** |
| C — Check manuel dans chaque controller admin (ex : `if (!adminEmailResolver.isAdminEmail(...)) throw new AccessDeniedException()`) | Simple, explicite | Duplication (6 endpoints) — viole DRY | 2/5 |

- **Décision** : **Option B** — créer `AdminAuthorizationFilter` (`OncePerRequestFilter`) déclaré dans `SecurityConfig` après `JwtFilter`, matchant le path pattern `/admin/**` (après stripping du context path `/api`).
- **Rationale** :
  - Pattern déjà en place (`JwtFilter` est un `OncePerRequestFilter` enregistré via `addFilterBefore`).
  - Un point d'entrée unique : impossible d'oublier le check sur un nouvel endpoint admin.
  - Compatible avec le `HttpStatusEntryPoint` qui renvoie 401 si pas authentifié → 403 uniquement si authentifié mais non-admin.
  - Le principal du SecurityContext est l'`UUID` du user (cf. `JwtFilter:46`) → le filter doit résoudre l'email via `UserRepository.findById(userId)` avant de passer à `AdminEmailResolver.isAdminEmail`.
- **Alternatives rejetées** : A (SpEL complexe pour résoudre l'email depuis le UUID principal), C (duplication).
- **Impact sur le plan** :
  - Créer `AdminAuthorizationFilter` dans `fr.kksdev.budget.api.config`.
  - Ajouter dans `SecurityConfig.securityFilterChain` : `.addFilterAfter(adminAuthorizationFilter, JwtFilter.class)`.
  - Le filter ignore toute requête ne matchant pas `/admin/**`, laisse passer.
  - Pour `/admin/**` : si non authentifié → laisser `HttpStatusEntryPoint` renvoyer 401 ; si authentifié non-admin → écrire `403` via `response.sendError(403)`.
  - Test : matrice `endpoints × (anonyme | user non-admin | admin)` (SC-002).

### RES-005 — Enrichissement `isAdmin`

- **Contexte** : `UserResponse` (cf. `dto/response/UserResponse.java`) est un record `(name, email)`. La feature exige que le frontend connaisse le statut admin pour afficher / masquer `Settings > Utilisateurs` (US-010, FR-018).
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Étendre `UserResponse` : `(name, email, isAdmin)` | Un seul appel existant `GET /users/me`, zéro endpoint nouveau | Modifie le contrat DTO existant — consommateurs Angular/Flutter doivent s'adapter | **5/5** |
| B — Nouveau endpoint `GET /users/me/admin` retournant `{ isAdmin: boolean }` | Séparation | Round-trip HTTP supplémentaire au boot pour chaque session | 2/5 |
| C — Exposer via un claim JWT custom | Zéro appel HTTP | Modification du flow JWT existant, invalidation cache si ADMIN_EMAILS change en runtime sans refresh | 2/5 |

- **Décision** : **Option A** — ajouter `boolean isAdmin` dans `UserResponse` et résoudre côté `UserService.getProfile` via `AdminEmailResolver.isAdminEmail(user.getEmail())`.
- **Rationale** : Endpoint `/users/me` déjà appelé au login et au refresh côté Angular / Flutter. Aucun round-trip supplémentaire. Modification de DTO typée (record) — consommation côté front avec types générés.
- **Alternatives rejetées** : B (round-trip inutile), C (changer le flow JWT pour une info dérivable).
- **Impact sur le plan** :
  - Modifier `UserResponse` : `(String name, String email, boolean isAdmin)`.
  - Modifier `UserService.getProfile(userId)` pour peupler `isAdmin`.
  - Mettre à jour le mapping côté Angular (`UserService` / signals) et Flutter (`UserModel` / Freezed + json_serializable → regénérer).

### RES-006 — Numérotation migration Flyway

- **Contexte** : Le dossier `api/src/main/resources/db/migration/` contient des migrations de V2 à V27. Les numéros ne sont pas strictement consécutifs (trous volontaires entre V23, V26, V27). Dernière migration : `V27__enable_unaccent_extension.sql`.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — V28 (simple incrément) pour une migration combinée `invitation` + `disabled_at` | Une seule migration | Moins granulaire si rollback partiel | 3/5 |
| B — V28 pour `invitation` + V29 pour `disabled_at` | Granularité, rollback / audit fin par changement | 2 fichiers pour une même feature | **4/5** |

- **Décision** : **Option B** — deux fichiers `V28__add_invitations.sql` (création table + index + FK) et `V29__add_user_disabled_at.sql` (ajout colonne).
- **Rationale** : Deux domaines distincts (nouvelle entité vs modification existante). Pattern observé dans le projet (V15/V16 sont séparés sur le même sujet notifications/debts). Facilite la lecture du log de migration.
- **Alternatives rejetées** : A (moins clair à la relecture).
- **Impact sur le plan** :
  - `V28__add_invitations.sql` : `CREATE TABLE invitation (id BIGSERIAL PRIMARY KEY, token UUID NOT NULL UNIQUE, email VARCHAR(255) NOT NULL, invited_by_user_id UUID NOT NULL REFERENCES users(id), expires_at TIMESTAMP NOT NULL, used_at TIMESTAMP, revoked_at TIMESTAMP, created_at TIMESTAMP NOT NULL DEFAULT NOW()); CREATE INDEX idx_invitation_token ON invitation(token);`
  - `V29__add_user_disabled_at.sql` : `ALTER TABLE users ADD COLUMN disabled_at TIMESTAMP NULL;`

### RES-007 — Route publique Angular `/accept-invite/:token`

- **Contexte** : `app/src/app/app.routes.ts` structure : `/auth/**` public (pas de `canActivate: [authGuard]`), `''` + `Shell` + `authGuard` pour le reste. Les routes "publiques" actuelles sont toutes sous `/auth/`.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Sous-route `/auth/accept-invite/:token` | Cohérent avec le regroupement public existant, zéro modification de la structure racine | URL plus longue (`/auth/accept-invite/...`) | **5/5** |
| B — Route top-level `/accept-invite/:token` dans `routes` (avant le `''` Shell) sans `authGuard` | URL courte | Casse la structure : ajoute une exception top-level | 2/5 |

- **Décision** : **Option A** — ajouter la route dans `features/auth/auth.routes.ts`.
- **Rationale** : Toutes les routes hors guard sont sous `/auth/`. Le lien transmis devient `https://<instance>/auth/accept-invite/<token>` — naturellement public. Pattern préservé.
- **Alternatives rejetées** : B (exception structurelle non justifiée).
- **Impact sur le plan** :
  - Ajouter dans `AUTH_ROUTES` : `{ path: 'accept-invite/:token', loadComponent: () => import('./pages/accept-invite/accept-invite').then(m => m.AcceptInvite) }`.
  - Créer le composant Angular standalone `AcceptInvite` avec signal `token = input.required<string>()` (route param) + form `password/displayName/currency/timezone`.

### RES-008 — Route publique Flutter `/accept-invite/:token`

- **Contexte** : `flutter/lib/src/routing/app_router.dart` a un `redirect` global qui force `/login` si non authentifié (sauf pour `login` et `register`). Il faudra étendre cette liste et ajouter la route `acceptInvite` aux `RouteNames`.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Ajouter `isAcceptInviteRoute` au `redirect` + nouvelle `GoRoute('/accept-invite/:token')` | Cohérent avec le pattern `login` / `register`, déjà en place | Mécanique existante à étendre | **5/5** |
| B — Sous-route de `/login` | Plus court à coder | URL incohérente avec Angular | 2/5 |

- **Décision** : **Option A** — même structure que `login` / `register`.
- **Rationale** : Pattern explicite déjà suivi pour 2 routes publiques. Ajouter une 3e reste trivial. URL cohérente entre Angular (`/auth/accept-invite/...`) et Flutter (`/accept-invite/...`) — cf. RES-010 pour la convergence URL.
- **Alternatives rejetées** : B (incohérent avec Angular).
- **Impact sur le plan** :
  - `RouteNames.acceptInvite = '/accept-invite/:token'` + `acceptInviteName`.
  - Modifier `redirect` : exclure également `isAcceptInviteRoute` du forçage login.
  - Nouveau `GoRoute` pointant vers `AcceptInviteScreen`.
  - Écran `ConsumerStatefulWidget` avec appel `GET /auth/invitations/:token` au mount pour récupérer l'email, puis formulaire.
  - Supprimer `RouteNames.register` + `RegisterScreen` + import (cohérence avec la suppression backend).

### RES-009 — Affichage conditionnel `Settings > Utilisateurs`

- **Contexte** : Le frontend doit cacher la section aux non-admins (FR-024). Défense en profondeur — le backend renvoie de toute façon 403.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Charger `isAdmin` au login via `/users/me`, stocker dans signal/provider global, `@if (isAdmin())` côté Angular, `Visibility` / `if` côté Flutter | Simple, déjà aligné avec RES-005 | Flag cache à invalider si user reconnecte | **5/5** |
| B — Router guard Angular + `redirect` Flutter | Plus strict (empêche l'accès URL direct) | Sur-ingénierie : le backend bloque déjà | 2/5 |

- **Décision** : **Option A** — flag dans le state user global (signal Angular / Riverpod Flutter).
- **Rationale** : Défense en profondeur uniquement (backend est la source de vérité via 403). Signal / provider déjà en place pour les infos user.
- **Alternatives rejetées** : B (sur-ingénierie, le 403 backend suffit en dernier recours).
- **Impact sur le plan** :
  - Angular : `CurrentUserStore` (ou équivalent) expose `isAdmin = computed(...)`. Le menu `Settings` conditionne l'entrée `Utilisateurs` via `@if`.
  - Flutter : `currentUserProvider` expose `user.isAdmin`. Le `SettingsScreen` conditionne la tuile.

### RES-010 — Format du lien d'invitation

- **Contexte** : L'admin copie le lien à transmettre. Angular et Flutter sont deux fronts distincts — le lien pointe nécessairement vers l'un des deux. L'usage principal est PWA (Angular) partagé par navigateur ; Flutter est secondaire et nécessiterait deep-link.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Backend retourne `{ token, expiresAt }` et Angular construit l'URL côté client : `${window.location.origin}/auth/accept-invite/${token}` | Zéro config serveur sur l'origin du front, flexibilité self-host | L'admin doit copier depuis Angular (ce qui est attendu puisqu'il opère depuis l'UI) | **5/5** |
| B — Backend construit et retourne l'URL complète via une property `app.frontend-base-url` | Lien utilisable partout | Exige une property de plus, duplication d'info déjà contenue dans le front appelant | 3/5 |

- **Décision** : **Option A** — `POST /api/admin/invitations` retourne `{ token, expiresAt }` ; l'UI Angular compose l'URL côté client. L'UI Flutter compose de la même façon depuis sa config (`AppConfig.frontendBaseUrl` si différente du backend). Pour le v1, la PWA Angular est le canal principal.
- **Rationale** : Pattern minimal (principe III). Self-hosted : chaque instance peut avoir un domaine différent → la flexibilité vient d'utiliser l'origin du front qui émet la requête.
- **Alternatives rejetées** : B (ajoute une property de config redondante).
- **Impact sur le plan** :
  - Réponse `POST /api/admin/invitations` : `InvitationCreatedResponse(String token, Instant expiresAt)`.
  - Angular : bouton "Copier le lien" construit `${location.origin}/auth/accept-invite/${token}`.
  - Flutter : même logique via sa propre config.
  - Documentation utilisateur : mentionner le format dans `docs/deployment.md` (onboarding admin).

---

## Analyse du codebase

### Patterns existants identifiés

- **Exception → HTTP status** : `ConflictException → 409` via `GlobalExceptionHandler` (cf. `config/GlobalExceptionHandler.java:73-81`). Pattern à réutiliser pour le garde-fou dernier admin (FR-017).
- **OncePerRequestFilter** : `JwtFilter` définit le pattern pour l'auth (cf. `config/JwtFilter.java`). `AdminAuthorizationFilter` suivra le même pattern.
- **Config via `@Value`** : `JwtUtil`, `SecurityConfig` utilisent `@Value("${app....}")` avec valeurs par défaut. `AdminEmailResolver` fera de même.
- **Service `@Transactional`** : Tous les services métier (cf. `AuthService.register`) utilisent `@Transactional` sur les opérations composées. `AcceptInviteService.acceptInvite` suivra.
- **DTO records** : `UserResponse`, `LoginRequest`, etc. sont des records. `AcceptInviteRequest`, `InvitationResponse`, `AdminUserResponse` seront des records.
- **Lombok sur entités JPA** : `@Data @Builder @NoArgsConstructor @AllArgsConstructor` (cf. `model/User.java`). `Invitation` suivra.
- **Principal = UUID** : `JwtFilter` pose `user.getId()` (UUID) comme principal. `UserController.getProfile` extrait via `(UUID) authentication.getPrincipal()`. `AdminAuthorizationFilter` suivra.
- **Flyway séparé par domaine** : V15/V16 séparent notifs/debts. Nos V28/V29 suivront.
- **Routes publiques Angular sous `/auth/**`** : confirme RES-007.
- **Routes publiques Flutter listées dans `redirect`** : `isLoginRoute` / `isRegisterRoute` dans `app_router.dart:84-85`. Extension simple pour `acceptInvite`.

### Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| `java.util.UUID` | JDK 21 natif | Token invitation via `UUID.randomUUID()` | Nul (déjà utilisé sur `User.id`) |
| `jjwt` | existant (via `JwtUtil`) | Inchangé | Nul |
| `Bean Validation` (`@Email`, `@NotBlank`, `@Size`) | existant | `AcceptInviteRequest`, `CreateInvitationRequest` | Nul |
| `BCryptPasswordEncoder` | existant (`SecurityConfig:56`) | Hash password à l'acceptation | Nul |
| Flyway | existant | V28/V29 | Nul |
| `OncePerRequestFilter` | Spring Security existant | `AdminAuthorizationFilter` | Nul |
| **Aucune nouvelle dépendance Maven / Gradle / npm / pub.** | — | — | Nul (principe VII) |

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 10 |
| Décisions prises | 10 |
| Nouvelles dépendances | 0 (principe VII respecté) |
| Patterns réutilisés | 9 (ConflictException, OncePerRequestFilter, @Value, @Transactional, DTO records, Lombok JPA, UUID principal, Flyway par domaine, routes publiques Angular/Flutter) |
| Assumption A-003 levée | Oui — logique eager non factorisée, intégration dans `AcceptInviteService` (option A) |
