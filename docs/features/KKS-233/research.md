# Research — KKS-233 : Bootstrap du premier admin sur DB vide

> Date : 2026-04-22
> Issue : KKS-233
> Spec : [spec.md](./spec.md)
> Clarify : [clarify-log.md](./clarify-log.md)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Backend — Architecture | Comment factoriser la logique de création `User + Categories + Account + Preferences` (actuellement inline dans `AcceptInviteService.acceptInvite`) pour la rendre réutilisable par le seed bootstrap ? | Haute |
| RES-002 | Backend — Cycle de vie | Mécanisme Spring pour exécuter (a) le seed bootstrap si DB vide et (b) le synchroniseur admin, post-Flyway mais avant l'ouverture des endpoints ? | Haute |
| RES-003 | Backend — Sécurité | Intégration du claim `mustResetCredentials` dans le JWT : extension de `JwtUtil` vs encapsulation dédiée ? | Haute |
| RES-004 | Backend — Sécurité | Gate "reset-only" : modification de `JwtFilter`, nouveau filter dédié, ou `@PreAuthorize` method-level ? | Haute |
| RES-005 | Backend — Config | Validation de `BOOTSTRAP_EMAIL` au démarrage : `@Value` + `@PostConstruct` manuel vs `@ConfigurationProperties` + `@Validated` ? | Moyenne |
| RES-006 | Backend — API | Extension de `AuthResponse` pour porter `mustResetCredentials` : champ toujours présent vs optionnel ? (Q-DIFF-01) | Moyenne |
| RES-007 | Backend — Crypto | Génération du password aléatoire 32 chars : `SecureRandom` direct vs libs externes (Apache Commons Text) ? | Basse |
| RES-008 | Backend — DB | Numérotation Flyway (V30/V31 ou suite libre) et nommage des colonnes (snake_case cohérent) | Basse |
| RES-009 | Frontend Angular — Routing | Router guard pour forcer la redirection vers `/first-login-reset` : nouveau guard vs extension de `authGuard` ? | Moyenne |
| RES-010 | Frontend Angular — State | Stockage du flag `mustResetCredentials` côté client : `UserInfo` + localStorage vs signal in-memory uniquement ? | Moyenne |
| RES-011 | Frontend Angular — Structure | Organisation du feature `first-login-reset` : nouveau dossier sous `features/` vs extension de `features/auth/` ? | Basse |
| RES-012 | Observabilité | Stratégie de log de la bannière WARN : `log.warn` multi-lignes direct vs helper formateur dédié ? | Basse |

---

## Décisions techniques

### RES-001 — Factorisation de la logique d'onboarding

- **Contexte** : `AcceptInviteService.acceptInvite()` (`api/src/main/java/fr/kksdev/budget/api/service/AcceptInviteService.java:30-56`) contient inline la séquence : `User.builder().email(...)` → `userRepository.save` → `categoryService.seedSystemCategories` → `accountService.createDefaultAccount` → `preferenceService.createInitialPreference` → `invitationService.markUsed` → `jwtUtil.generateToken` + `refreshTokenService.generateRefreshToken`. Le ticket KKS-233 a besoin d'exécuter une séquence **quasi-identique** (sans `invitation.markUsed`, sans invitation en entrée, avec deux flags spécifiques `isAdmin = true` et `passwordResetRequired = true`, et sans génération de refresh token puisque le user est seed en arrière-plan). La session sparring a expliqué la dépendance "KKS-232 est mergé — KKS-233 réutilise la logique". La lecture du code confirme que cette logique **n'est pas encore factorisée** : elle vit toujours inline dans `AcceptInviteService`.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Dupliquer la séquence dans un nouveau `BootstrapService`, sans toucher à `AcceptInviteService` | Isolation totale, zéro risque de régression sur KKS-232 | Duplication de 6 appels inter-services, violation explicite du principe DRY sur un flux métier | 2/5 |
| B — Extraire un service `UserOnboardingService` (méthode `provisionUser(email, rawPassword, displayName, currency, timezone, isAdmin, passwordResetRequired)`) consommé par `AcceptInviteService` **et** par `BootstrapService` | Un seul point de vérité pour la séquence ; ajout de deux paramètres `isAdmin` et `passwordResetRequired` mutualisé ; futur reset-admin CLI réutilise aussi | Refactor de `AcceptInviteService` (risque faible, couverture test existante) | **5/5** |
| C — Déplacer la séquence dans une méthode package-private de `AcceptInviteService`, appelée depuis `BootstrapService` via injection | Factorisation sans nouveau service | Couplage `BootstrapService → AcceptInviteService` sémantiquement bizarre (le bootstrap n'accepte pas d'invitation) | 2/5 |

- **Décision** : **Option B** — créer un service `UserOnboardingService` (package `service/`) exposant une méthode `provisionUser(provisioningRequest)` où `UserProvisioningRequest` est un record interne portant les paramètres. `AcceptInviteService.acceptInvite` appelle `userOnboardingService.provisionUser(...)` puis gère la partie spécifique invitation (validation token, `markUsed`, refresh token, JWT).
- **Rationale** : Principe III YAGNI respecté (un seul nouveau service, pas d'abstraction prématurée) tout en satisfaisant la dépendance explicite du ticket envers KKS-232. Deux consommateurs immédiats et potentiellement un troisième (reset-admin CLI hors scope KKS-233) justifient la factorisation.
- **Alternatives rejetées** : A (duplication inacceptable), C (couplage sémantique faux).
- **Impact sur le plan** :
  - Créer `UserOnboardingService` + record `UserProvisioningRequest(email, rawPassword, displayName, currency, timezone, isAdmin, passwordResetRequired)`.
  - Refactor `AcceptInviteService.acceptInvite` pour déléguer la création à `UserOnboardingService` (validation invitation + JWT/refresh token restent dans `AcceptInviteService`).
  - Résout Q-DIFF-05 implicitement : `UserOnboardingService.provisionUser` appelle toujours `categoryService.seedSystemCategories` (le bootstrap admin bénéficie aussi des catégories système — compte fonctionnel dès le reset).
  - Tests : couverture unitaire existante de `AcceptInviteService` réaffectée au nouveau service + test d'intégration dédié pour la variante bootstrap (sans invitation).

### RES-002 — Mécanisme de déclenchement au démarrage

- **Contexte** : Le seed bootstrap (FR-001) et le synchroniseur admin (FR-012b) doivent s'exécuter **après** Flyway mais **avant** l'ouverture du port HTTP. Aucun `ApplicationRunner` ni `CommandLineRunner` n'existe actuellement dans le codebase (confirmé par `Grep ApplicationRunner|CommandLineRunner|ApplicationReadyEvent` → 0 match). Le pattern est donc à introduire.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `@Component` implémentant `ApplicationRunner.run(ApplicationArguments args)` | Déclenche post-Flyway et avant l'acceptation des requêtes (Spring Boot lifecycle standard). Injection dépendances standard. Intégration transactions fluide | Aucun inconvénient notable | **5/5** |
| B — `@EventListener(ApplicationReadyEvent.class)` | Idiomatique pour "l'app est prête" | Déclenché **après** l'ouverture du port HTTP → fenêtre théorique où un user arrive avant le seed. Contredit le principe "zéro surface réseau avant bootstrap complet" | 2/5 |
| C — `@PostConstruct` sur un service dédié | Fonctionne immédiatement après l'injection | Non garanti post-Flyway si l'ordre d'initialisation des beans diverge. Pas de `ApplicationArguments` | 2/5 |
| D — Migration Java Flyway (`BaseJavaMigration`) | Strictement ordonnée avec les migrations SQL | Impossible : les beans Spring (services métier, `PasswordEncoder`) ne sont pas disponibles dans le contexte Flyway. Contradictoire avec FR-012a qui interdit la lecture de `ADMIN_EMAILS` en migration | 1/5 |

- **Décision** : **Option A** — deux composants distincts `BootstrapSeedRunner` et `AdminSyncRunner`, tous deux `@Component implements ApplicationRunner`.
- **Rationale** : Standard Spring Boot, post-Flyway garanti (les `ApplicationRunner` sont appelés dans `SpringApplication.callRunners` après `run` et avant `SpringApplication.running = true`). Séparation des responsabilités entre seed (conditionnel sur DB vide) et sync admin (idempotent à chaque boot) facilite les tests unitaires.
- **Alternatives rejetées** : B (fenêtre d'accès HTTP avant seed), C (ordre non garanti vs Flyway), D (incompatible FR-012a).
- **Impact sur le plan** :
  - `BootstrapSeedRunner implements ApplicationRunner` avec logique `if (userRepository.count() == 0) { userOnboardingService.provisionUser(...); logBanner(...); }`.
  - `AdminSyncRunner implements ApplicationRunner` avec logique `adminEmails.forEach(email -> promoteIfNotAlreadyAdmin(email))` — promotion uniquement, jamais rétrogradation.
  - Ordre d'exécution : Spring n'en garantit pas un entre deux `ApplicationRunner` par défaut. Annoter avec `@Order(1)` et `@Order(2)` pour forcer `BootstrapSeedRunner` avant `AdminSyncRunner` — le seed bootstrap crée un user admin avec `isAdmin=true` avant que le sync ne tente de promouvoir.

### RES-003 — Claim `mustResetCredentials` dans le JWT

- **Contexte** : `JwtUtil.generateToken(String email)` (`api/src/main/java/fr/kksdev/budget/api/config/JwtUtil.java:26-33`) ne supporte **aucun claim custom** — uniquement `subject`, `issuedAt`, `expiration`. Le spec FR-008 exige un claim `mustResetCredentials: true` vérifiable côté filter. Deux surfaces à modifier : émission (login / acceptInvite / first-login-reset) et vérification (filter).
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Ajouter une surcharge `JwtUtil.generateToken(String email, Map<String, Object> claims)` — l'appelant fournit les claims, la surcharge sans claims reste défaut `Map.of()` | Rétro-compatible : les consommateurs existants continuent d'appeler `generateToken(email)` sans modification ; extensible pour futurs claims | Légère asymétrie d'API (2 surcharges) | **5/5** |
| B — Méthode dédiée `generateTokenWithResetFlag(String email)` | Intention claire | Non extensible ; redondant si un futur ticket ajoute un autre claim | 2/5 |
| C — Abstraction `JwtClaimsBuilder` fluent | Extensible à l'infini | Sur-ingénierie pour 1 claim (YAGNI) | 1/5 |

- **Décision** : **Option A** — surcharge `generateToken(String email, Map<String, Object> extraClaims)`. Ajouter également `JwtUtil.extractClaim(String token, String claimName)` pour la lecture côté filter.
- **Rationale** : Rétro-compatible (aucun callsite à modifier sauf ceux qui doivent porter le claim), pattern minimal, extensible sans refactor ultérieur.
- **Alternatives rejetées** : B (non extensible), C (sur-ingénierie).
- **Impact sur le plan** :
  - Étendre `JwtUtil` : surcharge `generateToken` + accesseur `extractClaim`.
  - `UserOnboardingService` / `BootstrapSeedRunner` / login : si user a `passwordResetRequired = true`, émettre un JWT avec `Map.of("mustResetCredentials", true)`.
  - `first-login-reset` endpoint : émettre un JWT **sans** ce claim.
  - Tests unitaires dédiés sur `JwtUtil` pour la lecture/écriture des claims custom.

### RES-004 — Gate "reset-only" côté backend

- **Contexte** : FR-008 exige que tout JWT porteur du claim `mustResetCredentials: true` n'autorise que `POST /api/auth/first-login-reset` (+ logout, cf. ajustement spec). Les endpoints protégés standards doivent renvoyer `403`. `JwtFilter` existant (`api/src/main/java/fr/kksdev/budget/api/config/JwtFilter.java:28-62`) pose simplement l'authentification ou non — il ne porte pas de logique d'autorisation par endpoint.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Nouveau filtre `PasswordResetRequiredFilter extends OncePerRequestFilter` posé **après** `JwtFilter` dans `SecurityConfig`. Si authentification posée + claim présent + path ∉ allowlist → `403 Forbidden`. | Séparation des responsabilités (auth vs autorisation conditionnelle). Cohérent avec `AdminAuthorizationFilter` déjà en place sur `/admin/*`. Pattern reproductible et testable | Nouveau bean filter à configurer dans `SecurityConfig` | **5/5** |
| B — Ajouter la logique dans `JwtFilter` directement | Un seul filtre | `JwtFilter` cumule auth + autorisation = antipattern Spring Security. Complique les tests | 2/5 |
| C — `@PreAuthorize("!hasAuthority('MUST_RESET')")` sur chaque endpoint à protéger | Déclaratif par endpoint | Nécessite de configurer method security (pas encore activée) + propagation du flag en authority — surcharge importante | 2/5 |

- **Décision** : **Option A** — `PasswordResetRequiredFilter`, enregistré après `JwtFilter` dans la chaîne `SecurityConfig.securityFilterChain`. Allowlist de paths exact-match : `POST /auth/first-login-reset`, `POST /auth/logout`. Retourne `403 Forbidden` avec payload `{ error: "PASSWORD_RESET_REQUIRED" }` sinon.
- **Rationale** : Cohérent avec le pattern `AdminAuthorizationFilter` (filtre dédié pour autorisation conditionnelle), testable isolément, ne touche pas à la logique d'auth pure.
- **Alternatives rejetées** : B (cumul auth/autorisation), C (surcharge de configuration).
- **Impact sur le plan** :
  - Créer `PasswordResetRequiredFilter` dans `config/`.
  - Ajouter le bean à `SecurityConfig.securityFilterChain` après `jwtFilter` et avant `adminAuthorizationFilter` (ordre : auth → reset gate → admin gate).
  - Ne nécessite pas de vérification DB dans le filtre lui-même : le claim JWT fait foi pour le gate. La vérification DB (flag encore `true`) reste côté endpoint `first-login-reset` (FR-010) pour neutraliser les anciens JWT après reset.

### RES-005 — Validation `BOOTSTRAP_EMAIL` au démarrage

- **Contexte** : FR-017 exige fail-fast si `BOOTSTRAP_EMAIL` est défini avec un format invalide. Le projet utilise actuellement `@Value("${app.admin-emails:}")` (pattern simple) et n'a pas de `@ConfigurationProperties` existant (vérifié dans RES-003 de KKS-232). Pas de précédent typé-validé.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `@ConfigurationProperties(prefix = "app.bootstrap")` + `@Validated` + `@Email` sur le champ `email` | Fail-fast natif Spring Boot : si format invalide, l'app ne démarre pas avec `ConfigurationPropertiesBindException` contenant message structuré | Introduit un premier `@ConfigurationProperties` dans le projet (nouveau pattern) | **4/5** |
| B — `@Value("${app.bootstrap.email:admin@localhost}")` + validation manuelle dans `@PostConstruct` via `Validator.validate` ou regex | Cohérent avec pattern existant (`@Value`) | Validation manuelle moins expressive que Bean Validation ; fail-fast dépend du `throw` manuel ; erreur moins propre | 3/5 |
| C — Pas de validation, accepter toute chaîne | Simplicité | Contradit FR-017 | 1/5 |

- **Décision** : **Option A** — créer `BootstrapProperties @ConfigurationProperties(prefix = "app.bootstrap") @Validated` avec un champ `@Email(message = "...") String email` défaut `admin@localhost`. Activer explicitement via `@EnableConfigurationProperties(BootstrapProperties.class)` dans une classe de config ou directement `@Component` sur la classe properties.
- **Rationale** : Le bénéfice de Bean Validation native + message d'erreur structuré au démarrage justifie l'introduction du pattern. Le projet grossira, d'autres configs validées suivront.
- **Alternatives rejetées** : B (validation manuelle moins robuste), C (contradit spec).
- **Impact sur le plan** :
  - Créer `config/BootstrapProperties.java` record ou classe Lombok `@Data`.
  - Injection dans `BootstrapSeedRunner` via constructeur.
  - Ajouter dans `application.yaml` : `app.bootstrap.email: ${BOOTSTRAP_EMAIL:admin@localhost}`.
  - Test d'intégration couvrant le fail-fast (SpringBootTest avec context chargement qui doit échouer).

### RES-006 — Extension d'`AuthResponse` pour `mustResetCredentials`

- **Contexte** : `AuthResponse` (`api/src/main/java/fr/kksdev/budget/api/dto/response/AuthResponse.java`) est actuellement `record AuthResponse(String token, String refreshToken, String email, String name)`. Q-DIFF-01 laissait ouvert le choix entre présence conditionnelle (uniquement si `true`) et présence systématique (boolean toujours présent).
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Ajouter un champ `boolean mustResetCredentials` toujours présent (default `false`) | Parsing front trivial (pas d'undefined), cohérent TypeScript | Change légèrement le contrat pour les consommateurs existants | **4/5** |
| B — Ajouter `Boolean mustResetCredentials` wrappé — présent uniquement si `true`, sinon `null` (nécessite `@JsonInclude(NON_NULL)`) | Payload minimal | Gestion `undefined` côté front, bugs potentiels sur parsing strict | 2/5 |
| C — Nouveau DTO `AuthResponseWithReset` distinct | Séparation des cas | Bifurcation du contrat login, complication côté front | 1/5 |

- **Décision** : **Option A** — enrichir `AuthResponse` : `record AuthResponse(String token, String refreshToken, String email, String name, boolean mustResetCredentials)`. Valeur `false` par défaut dans tous les flows existants (`login` user normal, `accept-invite`, `refresh`).
- **Rationale** : Résout Q-DIFF-01 définitivement. Parsing front strict-friendly. Compatible avec l'interface TypeScript `AuthResponse` existante côté Angular (ajout d'un champ).
- **Alternatives rejetées** : B (gestion undefined fragile), C (fragmentation contrat).
- **Impact sur le plan** :
  - Modifier `AuthResponse` : ajouter le champ.
  - Adapter `AuthService.login` et `AcceptInviteService.acceptInvite` et `RefreshTokenService.refreshAccessToken` pour renseigner `user.isPasswordResetRequired()`.
  - Mettre à jour l'interface TypeScript côté Angular (`app/src/app/core/models/auth.model.ts`).
  - Impact Q-DIFF-01 : **résolu**.

### RES-007 — Génération du password aléatoire

- **Contexte** : FR-002 + SC-007 imposent 32 chars alphanumériques `[A-Za-z0-9]` via `SecureRandom`. Pas de lib externe requise.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Helper statique `PasswordGenerator.generate(int length)` avec `java.security.SecureRandom` et boucle indexation sur une String alphabet | Zéro dépendance externe, trivial à tester | - | **5/5** |
| B — `org.apache.commons.text.RandomStringGenerator` | Plus d'options (filters, ranges Unicode) | Ajout dépendance pour usage unique (YAGNI) | 2/5 |
| C — Spring Security `BCryptPasswordEncoder` + random plaintext via `UUID.randomUUID().toString()` | Utilise du code déjà existant | UUID contient des tirets, pas alphanumérique pur | 1/5 |

- **Décision** : **Option A** — classe `util/PasswordGenerator` (ou méthode utilitaire privée dans `BootstrapSeedRunner` si usage unique).
- **Rationale** : YAGNI, zéro dépendance, test unitaire simple (distribution statistique + longueur + alphabet).
- **Alternatives rejetées** : B (dépendance injustifiée), C (alphabet incorrect).
- **Impact sur le plan** :
  - Créer `util/PasswordGenerator.java` (classe finale avec constructeur privé + méthode statique) OU méthode privée inline si classe `BootstrapSeedRunner` reste petite.
  - Test unitaire sur SC-007 : 1000 appels → longueur 32 + chars ∈ `[A-Za-z0-9]`.

### RES-008 — Numérotation Flyway et nommage colonnes

- **Contexte** : Dernière migration Flyway présente : `V29__add_user_disabled_at.sql` (cf. `api/src/main/resources/db/migration/`). V24 et V25 sont absents (trous de numérotation acceptés par Flyway). Convention projet : snake_case pour colonnes (`disabled_at`, `created_at`), numérotation croissante avec double underscore.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Deux migrations séparées `V30__add_user_is_admin.sql` et `V31__add_user_password_reset_required.sql` | Atomicité par concept, rollback indépendant facile | Deux fichiers | **5/5** |
| B — Une seule migration `V30__add_user_admin_and_reset_flags.sql` | Un seul fichier | Couples deux concepts orthogonaux (rôle admin, exigence de reset) | 3/5 |

- **Décision** : **Option A** — `V30__add_user_is_admin.sql` (ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE) + `V31__add_user_password_reset_required.sql` (ALTER TABLE users ADD COLUMN password_reset_required BOOLEAN NOT NULL DEFAULT FALSE).
- **Rationale** : Séparation sémantique, historique clair en git blame pour chaque concept, conforme FR-012a (ALTER TABLE uniquement, pas de data).
- **Alternatives rejetées** : B (couple deux concepts sans raison).
- **Impact sur le plan** :
  - 2 fichiers SQL à ajouter dans `api/src/main/resources/db/migration/`.
  - Mise à jour de `User.java` : ajout de 2 champs `@Column(name = "is_admin", nullable = false) private boolean isAdmin;` et `@Column(name = "password_reset_required", nullable = false) private boolean passwordResetRequired;`.

### RES-009 — Router guard Angular pour redirection reset

- **Contexte** : `authGuard` existant (`app/src/app/core/guards/auth.guard.ts`) redirige vers `/auth` si non authentifié. Il ne gère pas le cas "authentifié mais reset requis". `AuthService.isAdmin` est déjà un computed signal — pattern analogue possible pour `mustResetCredentials`.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Nouveau guard `passwordResetGuard` appliqué sur toutes les routes protégées, en **second** dans le tableau `canActivate`. Si `authService.mustResetCredentials()` → redirige vers `/first-login-reset`. | Responsabilité séparée (auth vs reset), testable isolément, composable | Il faut l'ajouter partout où `authGuard` est présent (grep route config) | **5/5** |
| B — Étendre `authGuard` : si authentifié + flag → redirige vers `/first-login-reset` | Un seul guard à appliquer | Cumule responsabilités, test du guard devient multi-scénarios | 3/5 |
| C — Interceptor HTTP qui redirige sur 403 `PASSWORD_RESET_REQUIRED` | Déclenché au premier appel API | Trop tard : la page cible s'affiche brièvement avant le 403 (UX dégradée) | 2/5 |

- **Décision** : **Option A** — guard `passwordResetGuard` distinct, composé avec `authGuard` via `canActivate: [authGuard, passwordResetGuard]` dans la route config. Le guard `/first-login-reset` inclut un inverse-guard `notPasswordResetGuard` qui empêche l'accès si `mustResetCredentials == false` (redirige vers `/`).
- **Rationale** : Principe Single Responsibility par guard. `authGuard` reste focalisé sur "est-il authentifié". Testabilité unitaire optimale.
- **Alternatives rejetées** : B (cumul responsabilités), C (UX dégradée).
- **Impact sur le plan** :
  - Créer `core/guards/password-reset.guard.ts` et `not-password-reset.guard.ts`.
  - Modifier `app.routes.ts` (ou le fichier équivalent) pour appliquer les deux guards sur les routes concernées.
  - Tests unitaires des guards.

### RES-010 — Stockage du flag `mustResetCredentials` côté client

- **Contexte** : `AuthService.saveAuth()` (`app/src/app/core/services/auth.ts:133-145`) stocke le `UserInfo` dans `localStorage` sous la clé `budget_user`. Signal `currentUser` maintient l'état in-memory. `computed isAdmin` dérive du `currentUser`.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Ajouter `mustResetCredentials?: boolean` au modèle `UserInfo`, sauvegarder en localStorage, dériver `mustResetCredentials` en computed signal | Cohérent avec pattern existant (`isAdmin`), persiste entre rechargements de page (cas : user recharge l'onglet pendant le reset) | Stocke un flag en localStorage (mineur en termes de sécurité : le claim JWT fait foi côté backend) | **5/5** |
| B — Signal in-memory uniquement, jamais en localStorage | Pas de persistance du flag | Si l'utilisateur recharge la page pendant le reset, le guard perd l'info → il accède au dashboard. Le backend le bloquera à la première requête mais UX dégradée | 2/5 |
| C — Lire le claim JWT à chaque check | Source de vérité unique | Décodage JWT côté front à chaque computed → overhead + complexité | 2/5 |

- **Décision** : **Option A** — `UserInfo` enrichi de `mustResetCredentials: boolean` (toujours présent, default `false`). Signal `currentUser` + computed `mustResetCredentials` dans `AuthService`. Sauvegarde en localStorage avec le reste du `UserInfo`.
- **Rationale** : Cohérence stricte avec le pattern `isAdmin` existant. Pas de régression côté rechargement de page.
- **Alternatives rejetées** : B (UX dégradée au reload), C (overhead inutile).
- **Impact sur le plan** :
  - Enrichir `UserInfo` model (`app/src/app/core/models/user.model.ts`).
  - Enrichir `saveAuth` pour stocker `response.mustResetCredentials`.
  - Ajouter `mustResetCredentials` computed signal dans `AuthService`.
  - Adapter `AuthService.login` / `saveAuth` / `restoreSession` pour lire le nouveau champ.

### RES-011 — Structure feature `first-login-reset` Angular

- **Contexte** : Features Angular organisées en dossiers `app/src/app/features/<nom>/` avec `*.routes.ts` et composants associés. La feature `auth` contient déjà login + potentiellement accept-invite.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Nouveau dossier `features/first-login-reset/` avec son propre routing | Séparation claire, intent explicite, ne pollue pas `features/auth/` | Un petit feature dossier pour un seul écran | 3/5 |
| B — Ajouter la route dans `features/auth/auth.routes.ts` avec un composant `first-login-reset.component.ts` sous `features/auth/` | Colocalisation des écrans liés à l'authentification | Mélange login public et reset authentifié ; le guard `notPasswordResetGuard` rend les deux contextes hétérogènes | **4/5** |

- **Décision** : **Option B** — composant sous `features/auth/first-login-reset/` + route dans `auth.routes.ts`. La route est *authentifiée* (guards `authGuard` + `notPasswordResetGuard` inversé appliqués) mais thématiquement liée au flow d'authentification.
- **Rationale** : Cohérence thématique (tout ce qui touche à l'authentification reste sous `features/auth/`). YAGNI : pas de feature module dédié pour un écran unique.
- **Alternatives rejetées** : A (sur-découpage pour un seul écran).
- **Impact sur le plan** :
  - Créer `features/auth/first-login-reset/first-login-reset.component.ts` (standalone).
  - Ajouter la route dans `features/auth/auth.routes.ts` : `{ path: 'first-login-reset', canActivate: [authGuard], component: FirstLoginResetComponent }` — note : ce chemin sera en dehors de `/auth` pour l'UX (route racine `/first-login-reset`), mais le composant et la route technique restent sous `auth`. À affiner en phase plan (voir Q-DIFF-04 pour décision finale displayName).
  - Tests du composant : formulaire de reset, appel API, redirection post-succès.

### RES-012 — Stratégie de log de la bannière WARN

- **Contexte** : FR-004 exige une bannière multi-lignes encadrée, visible dans `docker compose logs`. SLF4J `log.warn()` est standard projet.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Un seul `log.warn(bannerAsString)` avec `\n` internes dans la chaîne | Un seul appel, atomique | Dépend du layout Logback pour que les `\n` soient bien rendus (par défaut oui, pas de prefix timestamp par ligne) | **4/5** |
| B — Plusieurs `log.warn()` successifs (1 par ligne) | Lisibilité dans le code Java | Chaque ligne reçoit son timestamp/thread prefix de Logback → bannière "cassée" visuellement dans les logs | 2/5 |

- **Décision** : **Option A** — bannière construite comme une chaîne multi-lignes (text block Java 15+), un seul `log.warn(banner)`.
- **Rationale** : Logback par défaut n'insère pas de préfixe par ligne dans un message contenant `\n`. La bannière reste lisible. Un seul appel = atomicité garantie (pas de log entrelacé avec une autre thread).
- **Alternatives rejetées** : B (bannière cassée visuellement).
- **Impact sur le plan** :
  - Méthode privée `BootstrapSeedRunner.buildBanner(String email, String password)` retournant un `String` via text block.
  - Test : vérifier que la méthode produit exactement N lignes et contient les valeurs.
  - Résout partiellement Q-DIFF-03 (cadre : `=` sur 48 chars, format label/valeur aligné) — détail cosmétique final laissé au plan.

---

## Synthèse

- **Inconnues identifiées** : 12
- **Décisions prises en research** : 12
- **Q-DIFF résolus (implicitement ou explicitement)** : Q-DIFF-01 (résolu par RES-006), Q-DIFF-05 (résolu par RES-001 — seedSystemCategories inclus)
- **Q-DIFF restants pour le plan** : Q-DIFF-02 (véhicule JWT post-reset body vs cookie), Q-DIFF-03 (format final bannière), Q-DIFF-04 (displayName obligatoire/optionnel dans first-login-reset)
- **Nouvelles dépendances externes** : aucune (pas de nouvelle lib Maven ou npm).
- **Nouveaux patterns introduits dans le projet** :
  - `ApplicationRunner` (premier usage dans le codebase, justifié par le besoin post-Flyway).
  - `@ConfigurationProperties + @Validated` (premier usage typé, justifié par FR-017).
- **Refactorings induits** :
  - Extraction `UserOnboardingService` depuis `AcceptInviteService`.
  - Refactor `AdminAuthorizationFilter` pour lire `user.isAdmin()`.
  - Refactor `UserService.toResponse()` pour lire `user.isAdmin()`.
  - Extension `JwtUtil` (nouveau surcharge `generateToken` + accesseur `extractClaim`).
  - Extension `AuthResponse` (+ `mustResetCredentials`).
  - Extension `UserInfo` côté Angular (+ `mustResetCredentials`).
