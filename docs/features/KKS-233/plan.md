# Plan — KKS-233 : Bootstrap du premier admin sur DB vide (pattern password généré au premier boot)

> Date : 2026-04-22
> Issue : KKS-233
> Spec : [spec.md](./spec.md)
> Clarify : [clarify-log.md](./clarify-log.md)
> Research : [research.md](./research.md)
> Branche : `feature/KKS-233`

---

## Constitution Check

> Vérification des 7 principes de `.specify/memory/constitution.md` (v2.1.2).

| Principe | Statut | Commentaire |
|----------|--------|-------------|
| I — API-First | PASS | Nouvel endpoint REST `POST /api/auth/first-login-reset` (FR-009/FR-010) avec DTO dédié `FirstLoginResetRequest` (record). `AuthResponse` enrichi d'un champ `mustResetCredentials` (FR-007, RES-006). Aucune entité JPA exposée. Context path `/api` respecté. |
| II — Sécurité par défaut | PASS | Password initial généré via `SecureRandom` (FR-002, SC-007). BCrypt pour le hash (FR-010). Bean Validation sur `FirstLoginResetRequest` (FR-009). JWT claim `mustResetCredentials` + filtre dédié `PasswordResetRequiredFilter` (FR-008, RES-004). Isolation user préservée (aucun accès cross-user). Pas de stack traces exposées — payload d'erreur structuré `PASSWORD_RESET_REQUIRED` / `PASSWORD_UNCHANGED`. |
| III — YAGNI | PASS | Pas de wizard multi-étapes, pas de CLI dédié, pas d'endpoint bootstrap public, pas de notification externe. Password généré dans les logs (pattern éprouvé Jenkins/GitLab). Extraction `UserOnboardingService` justifiée par 2 consommateurs immédiats (RES-001). Deux `ApplicationRunner` distincts (seed + sync admin) au lieu d'abstraction générique. |
| IV — Mobile-First UX | N/A | Bootstrap est un événement **instance-level** exécuté une fois par le self-hoster, pas par l'utilisateur final. Flutter hors scope (FR-016). Angular : un écran dédié `/first-login-reset` (formulaire simple, 3 champs), pas de navigation. Pas de saisie mobile quotidienne en jeu. |
| V — Testabilité | PASS | Tests d'intégration backend : `BootstrapSeedRunner` (DB vide / DB non vide), `AdminSyncRunner` (promotion + non-rétrogradation), `PasswordResetRequiredFilter` (403 sur endpoints protégés), endpoint `first-login-reset` (nominal + erreurs 400/403). Tests unitaires : `PasswordGenerator`, `JwtUtil.extractClaim`, `BootstrapProperties` validation. Tests Angular : guards composables (`passwordResetGuard`, `notPasswordResetGuard`), composant `FirstLoginResetComponent`. Nommage `should_[résultat]_when_[condition]`. |
| VI — Observabilité | PASS | Log WARN bannière multi-lignes au seed (FR-004). Log INFO au démarrage pour chaque promotion admin (`Admin promoted via ADMIN_EMAILS sync: {email}`). Log INFO au reset (`User reset credentials: oldEmail={} → newEmail={}`). Pas de `System.out.println`. Format cohérent avec le projet. |
| VII — Self-Hosted Ready | PASS | Aucune nouvelle dépendance Maven ni npm (cf. research). PostgreSQL reste la seule dépendance infra. `BOOTSTRAP_EMAIL` optionnelle (défaut `admin@localhost`). `docker compose up -d` suffit (FR-018, SC-006). Pas de SMTP, pas de service externe. Démarrage standard `mvn spring-boot:run` ou `java -jar`. |

### Dérogations

Aucune dérogation aux principes de la constitution.

| Article | Dérogation | Justification |
|---------|------------|---------------|
| — | — | — |

### Complexity Tracking

| # | Complexité | Justification | Alternative envisagée |
|---|-----------|---------------|----------------------|
| CX-001 | Introduction du pattern `ApplicationRunner` (premier usage dans le codebase) — deux composants `BootstrapSeedRunner` et `AdminSyncRunner` | Besoin d'exécution **post-Flyway et avant ouverture HTTP**. Les beans Spring (services métier, `PasswordEncoder`, `JwtUtil`) sont nécessaires → `BaseJavaMigration` Flyway inapplicable (RES-002 option D). `@EventListener(ApplicationReadyEvent)` rejeté car post-ouverture HTTP. `@PostConstruct` rejeté car ordre vs Flyway non garanti. | Cf. RES-002 options B/C/D évaluées |
| CX-002 | Introduction du pattern `@ConfigurationProperties + @Validated` (premier usage typé dans le codebase) | Fail-fast natif Spring sur format email invalide (FR-017) avec message structuré. Alternative `@Value + @PostConstruct + validation manuelle` rejetée : moins expressive, erreur moins propre. | Cf. RES-005 option B |
| CX-003 | Nouveau filtre HTTP `PasswordResetRequiredFilter` en plus de `JwtFilter` et `AdminAuthorizationFilter` | Pattern cohérent avec `AdminAuthorizationFilter` existant (filtre dédié pour autorisation conditionnelle). Sépare auth (`JwtFilter`) / gate reset (`PasswordResetRequiredFilter`) / gate admin (`AdminAuthorizationFilter`). Testable isolément. Alternative `@PreAuthorize` rejetée (surcharge de configuration, method security non activée). | Cf. RES-004 options B/C |
| CX-004 | Refactor architecture admin : passage de résolution dynamique (`ADMIN_EMAILS` à chaque requête) à champ autoritaire `User.isAdmin` en DB | Exigé par FR-012 (et par la promesse UX self-hoster : aucune config à toucher après reset). Sans ce refactor, le self-hoster perd son rôle admin dès qu'il change son email lors du reset (car son nouvel email ne figure pas dans `ADMIN_EMAILS`). Refactor fait au plus petit coût : 2 filtres + 1 mapping DTO + 1 migration + 1 synchroniseur. | Option B (garder l'architecture actuelle + doc "après reset, mettez à jour ADMIN_EMAILS") explicitement rejetée par Kelly en session clarify (CL-001) |
| CX-005 | Extraction d'un service `UserOnboardingService` depuis `AcceptInviteService` | Mutualise la séquence `User + Categories + Account + Preferences` entre deux consommateurs immédiats (accept-invite + bootstrap seed). Principe DRY sur un flux métier central. | Cf. RES-001 options A (duplication) et C (méthode inter-service) |

---

## Résumé de l'approche

Ajout d'un mécanisme de bootstrap automatique du premier admin sur DB vide via deux `ApplicationRunner` Spring Boot exécutés après Flyway : `BootstrapSeedRunner` crée un compte admin seed si `users` est vide, avec password aléatoire 32 chars loggé en WARN ; `AdminSyncRunner` promeut (sans jamais rétrograder) les users dont l'email figure dans `ADMIN_EMAILS`. Introduction d'un nouvel endpoint `POST /api/auth/first-login-reset` pour forcer le changement de credentials à la première connexion, gardé par un filtre HTTP dédié `PasswordResetRequiredFilter` qui bloque tous les endpoints sauf reset + logout tant que le JWT porte le claim `mustResetCredentials: true`. Refactor de l'architecture admin : le statut administrateur est désormais stocké dans un champ autoritaire `User.isAdmin`, remplaçant la résolution dynamique via `ADMIN_EMAILS`. Côté Angular : écran dédié `/first-login-reset` avec deux guards composables (`passwordResetGuard` sur les routes protégées + `notPasswordResetGuard` sur la route de reset elle-même). Aucun impact sur Flutter (client indépendant).

## Contexte technique

- **Stack** :
  - Backend : Spring Boot 4, Java 21, Maven, PostgreSQL 15+, Spring Security + JWT (jjwt), Spring Data JPA, Flyway, Lombok, Bean Validation (JSR-303)
  - Frontend PWA : Angular 21+, TypeScript 5.9, SCSS tokens, signals-first, RxJS minimal
  - Mobile : Flutter ≥ 3.27 — **non impacté** (FR-016)
- **Nouvelles dépendances** : **Aucune** (cf. research).
- **Nouveaux patterns introduits** : `ApplicationRunner` (Spring Boot lifecycle) + `@ConfigurationProperties + @Validated` (config typée validée au démarrage) — tous deux justifiés en Complexity Tracking.
- **Migrations Flyway** : deux migrations SQL dédiées — `V30__add_user_is_admin.sql` et `V31__add_user_password_reset_required.sql`. Chacune contient un simple `ALTER TABLE users ADD COLUMN ...`. Aucune opération data dans les migrations (FR-012a).
- **Performance / scale** : négligeable. Le seed s'exécute une fois dans la vie d'une instance. Le synchroniseur admin itère sur `ADMIN_EMAILS` (au plus une dizaine d'entrées pour l'audience cible). Pas de contrainte perf.
- **Contraintes** : `docker compose up -d` doit suffire pour une instance vierge. Zéro configuration obligatoire au-delà de ce qui existe déjà (DB, JWT secret).

## Project Structure

### Documentation (this feature)

```text
docs/features/KKS-233/
├── spec.md                    # Phase /devflow.spec
├── clarify-log.md             # Phase /devflow.clarify
├── review-log.md              # Phases /devflow.review-*
├── research.md                # Phase /devflow.research
├── plan.md                    # Ce fichier (/devflow.plan)
├── data-model.md              # Annexe au plan (entités)
├── quickstart.md              # Annexe au plan (test local)
├── contracts.md               # Phase /devflow.contracts
├── tasks.md                   # Phase /devflow.tasks
└── state.json                 # Tracker devflow
```

### Source Code (repository root)

Backend — `api/`

```text
api/src/main/
├── java/fr/kksdev/budget/api/
│   ├── config/
│   │   ├── AdminAuthorizationFilter.java           # M — lit user.isAdmin()
│   │   ├── BootstrapProperties.java                # C — @ConfigurationProperties app.bootstrap
│   │   ├── JwtUtil.java                            # M — surcharge generateToken + extractClaim
│   │   ├── JwtFilter.java                          # (inchangé)
│   │   ├── PasswordResetRequiredFilter.java        # C — gate reset-only
│   │   └── SecurityConfig.java                     # M — injection du nouveau filter
│   ├── controller/
│   │   └── AuthController.java                     # M — endpoint POST /auth/first-login-reset
│   ├── dto/
│   │   ├── request/
│   │   │   └── FirstLoginResetRequest.java         # C — record validé
│   │   └── response/
│   │       └── AuthResponse.java                   # M — ajout mustResetCredentials
│   ├── model/
│   │   └── User.java                               # M — +isAdmin, +passwordResetRequired
│   ├── runner/
│   │   ├── AdminSyncRunner.java                    # C — @Order(2) ApplicationRunner
│   │   └── BootstrapSeedRunner.java                # C — @Order(1) ApplicationRunner
│   ├── service/
│   │   ├── AcceptInviteService.java                # M — délègue à UserOnboardingService
│   │   ├── AuthService.java                        # M — propage mustResetCredentials dans response
│   │   ├── RefreshTokenService.java                # M — propage mustResetCredentials dans response
│   │   ├── UserOnboardingService.java              # C — logique eager mutualisée
│   │   └── UserService.java                        # M — toResponse lit user.isAdmin()
│   └── util/
│       └── PasswordGenerator.java                  # C — SecureRandom + alphabet
└── resources/
    ├── application.yaml                            # M — app.bootstrap.email property
    └── db/migration/
        ├── V30__add_user_is_admin.sql              # C
        └── V31__add_user_password_reset_required.sql  # C

api/src/test/java/fr/kksdev/budget/api/
├── config/
│   ├── BootstrapPropertiesTest.java                # C — fail-fast si email invalide
│   └── PasswordResetRequiredFilterTest.java        # C — gate allowlist
├── controller/
│   └── AuthControllerFirstLoginResetIT.java        # C — intégration endpoint reset
├── runner/
│   ├── AdminSyncRunnerTest.java                    # C — promotion + non-rétrogradation
│   └── BootstrapSeedRunnerTest.java                # C — seed conditionnel
├── service/
│   ├── AcceptInviteServiceTest.java                # M — adapte appels à UserOnboardingService
│   └── UserOnboardingServiceTest.java              # C — logique eager
└── util/
    └── PasswordGeneratorTest.java                  # C — SC-007 longueur + alphabet
```

Frontend Angular — `app/`

```text
app/src/app/
├── core/
│   ├── guards/
│   │   ├── not-password-reset.guard.ts             # C — interdit l'accès à /first-login-reset si flag off
│   │   └── password-reset.guard.ts                 # C — redirige vers /first-login-reset si flag on
│   ├── models/
│   │   ├── auth.model.ts                           # M — AuthResponse +mustResetCredentials
│   │   └── user.model.ts                           # M — UserInfo +mustResetCredentials
│   └── services/
│       └── auth.ts                                 # M — persistance + computed mustResetCredentials
├── features/auth/
│   ├── auth.routes.ts                              # M — route /first-login-reset
│   └── first-login-reset/
│       ├── first-login-reset.component.html        # C
│       ├── first-login-reset.component.scss        # C
│       ├── first-login-reset.component.spec.ts     # C
│       └── first-login-reset.component.ts          # C — standalone, OnPush, signals
└── app.routes.ts                                   # M — passwordResetGuard global sur routes protégées
```

Documentation projet

```text
docs/deployment.md                                  # M — procédure premier démarrage self-hoster
```

**Structure Decision** : arborescence multi-module existante (backend + frontend Angular + Flutter non touché). Tous les artefacts nouveaux se placent dans les dossiers existants du projet, sans créer de nouveau module Maven ni npm. Le répertoire `runner/` est créé sous `api/src/main/java/fr/kksdev/budget/api/` pour regrouper les deux `ApplicationRunner` — cohérent avec la convention projet (un sous-package par responsabilité).

---

## Approche détaillée par composant

### C1 — Migrations Flyway

**Fichiers** : `api/src/main/resources/db/migration/V30__add_user_is_admin.sql`, `V31__add_user_password_reset_required.sql`

**Contenu V30** :

```sql
ALTER TABLE users
  ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE;
```

**Contenu V31** :

```sql
ALTER TABLE users
  ADD COLUMN password_reset_required BOOLEAN NOT NULL DEFAULT FALSE;
```

**Couvre** : FR-012a, FR-012 (champ `isAdmin` existant en base), FR-002 (champ `passwordResetRequired` requis pour seed).

### C2 — Entité `User` étendue

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/model/User.java`

**Modifications** :
- Ajouter `@Column(name = "is_admin", nullable = false) private boolean isAdmin;`
- Ajouter `@Column(name = "password_reset_required", nullable = false) private boolean passwordResetRequired;`

Les annotations Lombok `@Data @Builder @NoArgsConstructor @AllArgsConstructor` déjà présentes génèrent `isAdmin()` / `setAdmin()` et `isPasswordResetRequired()` / `setPasswordResetRequired()`.

**Couvre** : FR-002 (`isAdmin`, `passwordResetRequired`), Key Entities.

### C3 — `BootstrapProperties` + `application.yaml`

**Fichiers** : `api/src/main/java/fr/kksdev/budget/api/config/BootstrapProperties.java`, `api/src/main/resources/application.yaml`

**`BootstrapProperties`** :

```java
@Component
@ConfigurationProperties(prefix = "app.bootstrap")
@Validated
@Data
public class BootstrapProperties {
    @NotBlank @Email
    private String email = "admin@localhost";
}
```

**`application.yaml`** (ajout) :

```yaml
app:
  bootstrap:
    email: ${BOOTSTRAP_EMAIL:admin@localhost}
```

**Comportement** : si `BOOTSTRAP_EMAIL` est défini avec un format invalide, Spring Boot lève `ConfigurationPropertiesBindException` au démarrage → fail-fast (FR-017).

**Couvre** : FR-002 (source de l'email seed), FR-017 (fail-fast format invalide), SC-006 (zéro config obligatoire, défaut fourni).

### C4 — `PasswordGenerator`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/util/PasswordGenerator.java`

Classe finale avec constructeur privé et méthode statique :

```java
public final class PasswordGenerator {
    private static final String ALPHABET =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    private static final SecureRandom RANDOM = new SecureRandom();

    private PasswordGenerator() {}

    public static String generate(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}
```

**Couvre** : FR-002 (32 chars alphanumériques), SC-007 (vérification alphabet).

### C5 — `UserOnboardingService`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/service/UserOnboardingService.java`

Exposition :

```java
public record UserProvisioningRequest(
    String email,
    String rawPassword,
    String displayName,
    Currency currency,
    String timezone,
    boolean isAdmin,
    boolean passwordResetRequired
) {}

@Service
@RequiredArgsConstructor
@Transactional
public class UserOnboardingService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final CategoryService categoryService;
    private final AccountService accountService;
    private final PreferenceService preferenceService;

    public User provisionUser(UserProvisioningRequest request) {
        User user = User.builder()
            .email(request.email())
            .password(passwordEncoder.encode(request.rawPassword()))
            .name(request.displayName())
            .isAdmin(request.isAdmin())
            .passwordResetRequired(request.passwordResetRequired())
            .build();
        userRepository.save(user);
        categoryService.seedSystemCategories(user);
        accountService.createDefaultAccount(user, request.currency());
        preferenceService.createInitialPreference(user, request.currency(), request.timezone());
        return user;
    }
}
```

**Consommateurs** :
- `AcceptInviteService.acceptInvite` (refactor) — appelle `provisionUser` avec `isAdmin=false`, `passwordResetRequired=false`.
- `BootstrapSeedRunner.run` (nouveau) — appelle `provisionUser` avec `isAdmin=true`, `passwordResetRequired=true`.

**Couvre** : FR-002, FR-003, FR-012 (stockage `isAdmin` direct), Q-DIFF-05 (catégories système incluses pour compte fonctionnel dès reset).

### C6 — `BootstrapSeedRunner`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/runner/BootstrapSeedRunner.java`

```java
@Component
@Order(1)
@RequiredArgsConstructor
@Slf4j
public class BootstrapSeedRunner implements ApplicationRunner {
    private static final int PASSWORD_LENGTH = 32;

    private final UserRepository userRepository;
    private final UserOnboardingService userOnboardingService;
    private final BootstrapProperties bootstrapProperties;

    @Override
    public void run(ApplicationArguments args) {
        if (userRepository.count() > 0) return;

        String rawPassword = PasswordGenerator.generate(PASSWORD_LENGTH);
        userOnboardingService.provisionUser(new UserProvisioningRequest(
            bootstrapProperties.getEmail(),
            rawPassword,
            "Admin",
            Currency.EUR,
            "Europe/Paris",
            true,   // isAdmin
            true    // passwordResetRequired
        ));
        log.warn(buildBanner(bootstrapProperties.getEmail(), rawPassword));
    }

    private String buildBanner(String email, String password) {
        return """
            ================================================
             FIRST BOOT — Admin account created
             Email:    %s
             Password: %s
             CHANGE THESE CREDENTIALS IMMEDIATELY
            ================================================
            """.formatted(email, password);
    }
}
```

**Couvre** : FR-001, FR-002, FR-004, FR-005, FR-006, SC-002, SC-003.

**Note Q-DIFF-03 (format bannière)** : résolu ici — cadre `=` sur 48 chars, 5 lignes de contenu, text block Java 15. Cohérent avec le mock-up de la spec.

### C7 — `AdminSyncRunner`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/runner/AdminSyncRunner.java`

```java
@Component
@Order(2)
@RequiredArgsConstructor
@Slf4j
public class AdminSyncRunner implements ApplicationRunner {

    private final AdminEmailResolver adminEmailResolver;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        Set<String> adminEmails = adminEmailResolver.listAdminEmails();
        for (String email : adminEmails) {
            userRepository.findByEmail(email)
                .filter(user -> !user.isAdmin())
                .ifPresent(user -> {
                    user.setAdmin(true);
                    userRepository.save(user);
                    log.info("Admin promoted via ADMIN_EMAILS sync: {}", email);
                });
        }
    }
}
```

**Propriété clé** : promotion uniquement (`!user.isAdmin()` filtre), jamais rétrogradation.

**Couvre** : FR-012b, US-004 Scenario 2 et 3.

### C8 — Refactor `AdminAuthorizationFilter`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/config/AdminAuthorizationFilter.java`

**Modification** : remplacer la ligne `.map(u -> adminEmailResolver.isAdminEmail(u.getEmail()))` par `.map(User::isAdmin)`. Supprimer la dépendance `AdminEmailResolver` du constructeur.

**Couvre** : FR-012, SC-005.

### C9 — Refactor `UserService.toResponse`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/service/UserService.java`

**Modification** : remplacer `adminEmailResolver.isAdminEmail(user.getEmail())` (ligne 53) par `user.isAdmin()`. Supprimer la dépendance `AdminEmailResolver` du constructeur.

**Couvre** : FR-012 (cohérence front).

### C10 — Extension `JwtUtil`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/config/JwtUtil.java`

**Ajouts** :

```java
public String generateToken(String email, Map<String, Object> extraClaims) {
    var builder = Jwts.builder()
        .subject(email)
        .issuedAt(new Date())
        .expiration(new Date(System.currentTimeMillis() + expiration));
    extraClaims.forEach(builder::claim);
    return builder.signWith(key).compact();
}

public String generateToken(String email) {
    return generateToken(email, Map.of());
}

public Object extractClaim(String token, String claimName) {
    return extractClaims(token).get(claimName);
}
```

**Couvre** : FR-008 (claim JWT).

### C11 — `PasswordResetRequiredFilter`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/config/PasswordResetRequiredFilter.java`

```java
@Slf4j
@RequiredArgsConstructor
public class PasswordResetRequiredFilter extends OncePerRequestFilter {
    private static final Set<String> ALLOWED_PATHS = Set.of(
        "/auth/first-login-reset",
        "/auth/logout"
    );

    private final JwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            chain.doFilter(request, response);
            return;
        }

        String token = extractBearerToken(request);
        if (token == null) {
            chain.doFilter(request, response);
            return;
        }

        Object claim = jwtUtil.extractClaim(token, "mustResetCredentials");
        boolean mustReset = Boolean.TRUE.equals(claim);

        if (!mustReset) {
            chain.doFilter(request, response);
            return;
        }

        String path = request.getServletPath();
        if (ALLOWED_PATHS.contains(path)) {
            chain.doFilter(request, response);
            return;
        }

        log.info("Request blocked by password-reset gate: path={}", path);
        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(
            "{\"error\":\"PASSWORD_RESET_REQUIRED\"," +
            "\"message\":\"Credentials reset required before accessing this resource.\"}"
        );
    }

    private String extractBearerToken(HttpServletRequest request) {
        String h = request.getHeader("Authorization");
        return (h != null && h.startsWith("Bearer ")) ? h.substring(7) : null;
    }
}
```

**Enregistrement** (C12).

**Couvre** : FR-008, SC-004.

### C12 — `SecurityConfig`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/config/SecurityConfig.java`

**Modification** : enregistrer `PasswordResetRequiredFilter` comme bean et l'insérer dans `securityFilterChain` **après** `JwtFilter` et **avant** `AdminAuthorizationFilter`. Ordre final de la chaîne :

```
UsernamePasswordAuthenticationFilter → JwtFilter → PasswordResetRequiredFilter → AdminAuthorizationFilter
```

**Couvre** : FR-008 (gate effective).

### C13 — DTO `FirstLoginResetRequest`

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/dto/request/FirstLoginResetRequest.java`

```java
public record FirstLoginResetRequest(
    @NotBlank @Email @Size(max = 255) String email,
    @NotBlank @Size(min = 8, max = 100) String password,
    @NotBlank @Size(min = 1, max = 100) String displayName
) {}
```

**Résout Q-DIFF-04** : `displayName` est **obligatoire**, cohérent avec `AcceptInviteRequest` (principe d'homogénéité des contrats d'onboarding).

**Couvre** : FR-009 (Bean Validation).

### C14 — `AuthResponse` enrichi

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/dto/response/AuthResponse.java`

```java
public record AuthResponse(
    String token,
    String refreshToken,
    String email,
    String name,
    boolean mustResetCredentials
) {}
```

**Tous les consommateurs** (`AuthService.login`, `AcceptInviteService.acceptInvite`, `RefreshTokenService.refreshAccessToken`, `AuthController.firstLoginReset`) renseignent ce champ depuis `user.isPasswordResetRequired()`.

**Résout Q-DIFF-01** : toujours présent, default `false`.

**Couvre** : FR-007, RES-006.

### C15 — Endpoint `POST /api/auth/first-login-reset`

**Fichiers** : `api/src/main/java/fr/kksdev/budget/api/controller/AuthController.java` (ajout méthode) + logique dans un service dédié `FirstLoginResetService` ou inline dans `AuthService`.

**Décision plan** : inline dans `AuthService` (méthode `firstLoginReset(UUID userId, FirstLoginResetRequest req)`) — pas de nouveau service pour une seule méthode (YAGNI, principe III).

**Comportement de `AuthService.firstLoginReset`** :

```java
@Transactional
public AuthResponse firstLoginReset(UUID userId, FirstLoginResetRequest req) {
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new EntityNotFoundException("User not found"));

    if (!user.isPasswordResetRequired()) {
        throw new AccessDeniedException("Password reset not required");
    }

    if (passwordEncoder.matches(req.password(), user.getPassword())) {
        throw new PasswordUnchangedException();
    }

    user.setEmail(req.email());
    user.setPassword(passwordEncoder.encode(req.password()));
    user.setName(req.displayName());
    user.setPasswordResetRequired(false);
    userRepository.save(user);

    log.info("User reset credentials: userId={} newEmail={}", userId, req.email());

    String token = jwtUtil.generateToken(user.getEmail()); // sans claim mustReset
    String refreshToken = refreshTokenService.generateRefreshToken(user);
    return new AuthResponse(token, refreshToken, user.getEmail(), user.getName(), false);
}
```

**Controller** :

```java
@PostMapping("/first-login-reset")
public ResponseEntity<AuthResponse> firstLoginReset(
        @AuthenticationPrincipal UUID userId,
        @Valid @RequestBody FirstLoginResetRequest request) {
    return ResponseEntity.ok(authService.firstLoginReset(userId, request));
}
```

**Exception** : `PasswordUnchangedException extends RuntimeException` → mappée dans `GlobalExceptionHandler` vers `400 Bad Request` avec payload `{ error: "PASSWORD_UNCHANGED", message: "..." }`.

**Transaction atomique** : `@Transactional` sur la méthode service garantit le tout-ou-rien (FR-010).

**Résout Q-DIFF-02** : le nouveau JWT est retourné dans le body JSON (cohérent avec `login` et `accept-invite` existants — pas de cookie HttpOnly).

**Couvre** : FR-009, FR-010, FR-011, SC-004, SC-005.

### C16 — Émission du claim `mustResetCredentials` côté login

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/service/AuthService.java`

**Modification** de `AuthService.login` :

```java
Map<String, Object> extraClaims = user.isPasswordResetRequired()
    ? Map.of("mustResetCredentials", true)
    : Map.of();
String token = jwtUtil.generateToken(user.getEmail(), extraClaims);
...
return new AuthResponse(token, refreshToken, user.getEmail(), user.getName(),
                       user.isPasswordResetRequired());
```

Appliqué aussi à `RefreshTokenService.refreshAccessToken` pour préserver le claim lors d'un refresh pendant la fenêtre de reset.

**Couvre** : FR-007, FR-008.

### C17 — Modèles et service Auth Angular

**Fichiers** : `app/src/app/core/models/auth.model.ts`, `app/src/app/core/models/user.model.ts`, `app/src/app/core/services/auth.ts`

**`auth.model.ts`** — ajout :

```ts
export interface AuthResponse {
  token: string;
  refreshToken: string;
  email: string;
  name: string;
  mustResetCredentials: boolean;
}
```

**`user.model.ts`** — ajout :

```ts
export interface UserInfo {
  name: string;
  email: string;
  isAdmin?: boolean;
  mustResetCredentials: boolean;
}
```

**`auth.ts`** — ajouts :
- computed signal : `readonly mustResetCredentials = computed(() => this.currentUser()?.mustResetCredentials ?? false);`
- `saveAuth(response)` : persister `mustResetCredentials` dans `UserInfo` + localStorage.
- `restoreSession` : relire le champ.
- Nouvelle méthode : `firstLoginReset(payload): Observable<AuthResponse>` qui POST `/auth/first-login-reset` et appelle `saveAuth` sur la réponse.

**Couvre** : FR-013, FR-014, FR-015, RES-010.

### C18 — Guards Angular

**Fichiers** : `app/src/app/core/guards/password-reset.guard.ts`, `app/src/app/core/guards/not-password-reset.guard.ts`

**`passwordResetGuard`** :

```ts
export const passwordResetGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.mustResetCredentials()
    ? router.createUrlTree(['/first-login-reset'])
    : true;
};
```

**`notPasswordResetGuard`** (inverse) :

```ts
export const notPasswordResetGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.mustResetCredentials()
    ? true
    : router.createUrlTree(['/']);
};
```

**Routing** : ajout de `passwordResetGuard` sur toutes les routes protégées (après `authGuard`) dans `app.routes.ts`. La route `/first-login-reset` porte `[authGuard, notPasswordResetGuard]`.

**Couvre** : FR-014.

### C19 — Composant `FirstLoginResetComponent`

**Fichier** : `app/src/app/features/auth/first-login-reset/first-login-reset.component.ts` (+ html/scss/spec)

**Caractéristiques** :
- Standalone, `ChangeDetectionStrategy.OnPush`.
- `inject(AuthService)` + `inject(Router)`.
- Reactive form : `email`, `password`, `passwordConfirm` (validation côté client : égalité), `displayName`.
- Submit : `authService.firstLoginReset(payload).subscribe({ next: () => router.navigateByUrl('/'), error: (e) => setError(e) })`.
- UI : explication du reset forcé + formulaire sobre. Utilise les tokens DESIGN.md existants.

**Couvre** : FR-013, FR-015.

### C20 — Route et redirection post-login Angular

**Fichier** : `app/src/app/features/auth/auth.routes.ts` et composants de login.

**Modifications** :
- Ajout de la route : `{ path: 'first-login-reset', canActivate: [authGuard, notPasswordResetGuard], component: FirstLoginResetComponent }` sous `features/auth/` mais exposée en URL racine `/first-login-reset` via la configuration globale (éviter le préfixe `/auth/`).
- `LoginComponent` : après succès, checker `authService.mustResetCredentials()` → si true, `router.navigateByUrl('/first-login-reset')`. Sinon comportement actuel.

**Couvre** : FR-013, FR-014, FR-015.

### C21 — Documentation déploiement

**Fichier** : `docs/deployment.md`

**Modifications** : ajout d'une section "Premier démarrage sur instance vierge" avec les 5 étapes documentées dans FR-018. Exemple de bannière affichée, procédure de récupération via `docker compose logs`, recommandation de purge des logs si persistés externe.

**Couvre** : FR-018, SC-001, SC-006.

---

## Risques identifiés et mitigations

| # | Risque | Probabilité | Impact | Mitigation |
|---|--------|-------------|--------|------------|
| R-01 | Le refactor `AdminAuthorizationFilter` + `UserService.toResponse` introduit une régression sur les endpoints `/admin/*` existants livrés par KKS-231 / KKS-232 | Moyenne | Élevé | Tests d'intégration admin existants (AdminUserControllerIT, InvitationControllerIT) à relancer ; ajouter un test dédié `should_preserve_admin_access_when_email_removed_from_admin_emails` (SC-005) |
| R-02 | L'ordre `@Order(1)` / `@Order(2)` entre les deux `ApplicationRunner` n'est pas respecté → `AdminSyncRunner` tente de promouvoir un user pas encore seedé | Faible | Moyen | Tests d'intégration dédiés vérifiant l'ordre. Documentation inline. Alternative : fusionner les deux runners (complexifie le test, rejeté) |
| R-03 | Le claim `mustResetCredentials` stocké dans le JWT reste valide après reset côté serveur (JWT stateless) → risque qu'un ancien JWT donne encore accès à `first-login-reset` | Faible | Moyen | Double-check côté endpoint `first-login-reset` : vérifier `user.isPasswordResetRequired() == true` en DB (FR-010) → 403 sinon. Neutralise les JWT orphelins sans blocklist. Cas couvert par test `should_return_403_when_reset_already_done` |
| R-04 | Le champ `mustResetCredentials` en localStorage peut être modifié manuellement par un utilisateur côté navigateur → contournement du guard | Faible | Faible | Le backend reste autoritaire : si le JWT porte le claim `mustResetCredentials: true`, le filtre bloque de toute façon. Le localStorage n'influe que l'UX, pas la sécurité |
| R-05 | Introduction de `@ConfigurationProperties + @Validated` sans Jakarta Validation sur le classpath runtime | Très faible | Élevé | Vérifier `spring-boot-starter-validation` dans `pom.xml` — déjà présent dans le projet (vérifié au pre-commit) |
| R-06 | `BOOTSTRAP_EMAIL` défini par le self-hoster avec un email déjà utilisé lors d'un redéploiement partiel (DB non vide mais réinstallation app) | Faible | Bas | La condition `userRepository.count() == 0` protège : aucun seed si la DB contient des users. Si le self-hoster veut réinitialiser, il doit vider la DB explicitement |
| R-07 | Les tests d'intégration existants couvrant `AcceptInviteService` cassent après l'extraction de `UserOnboardingService` | Moyenne | Moyen | Migration contrôlée : les assertions métier restent identiques, seule l'orchestration interne change. Lancer `mvn test` avant merge. Pre-commit review systématique |

---

## Hors scope (explicites)

- **Reset admin en cas de perte de mot de passe ultérieure** (après le first-login-reset initial) : ticket séparé si besoin. La spec acte la limite.
- **UI de setup wizard multi-étapes** (à la Nextcloud) : un seul écran `/first-login-reset` suffit.
- **Notification externe du password initial** (email, webhook) : self-hosted ≠ SMTP garanti. Exclu par YAGNI.
- **Client Flutter** (FR-016) : aucune modification. Diff `feature/KKS-233` doit être vide sous `flutter/`.
- **Gestion de rotation des logs** persistés externe (Datadog, Loki) : responsabilité du self-hoster, documenté dans `docs/deployment.md`.
- **Blocklist JWT active** au moment du reset (RES-003, CL-002) : non implémentée. Le double-check DB + le claim JWT suffisent.

---

## Artefacts complémentaires

- [`data-model.md`](./data-model.md) — Modèle de données détaillé : extensions de `User`, migrations Flyway, contraintes.
- [`quickstart.md`](./quickstart.md) — Procédure pour tester localement le bootstrap sur DB vierge.
- [`research.md`](./research.md) — Décisions techniques (RES-001 à RES-012) référencées tout au long de ce plan.

---

## Couverture FR / SC

Vérification que chaque requirement est couvert par au moins un composant du plan :

| FR | Composant(s) |
|----|--------------|
| FR-001 | C6 `BootstrapSeedRunner` |
| FR-002 | C2, C4, C5, C6 |
| FR-003 | C5 `UserOnboardingService` (inclut catégories système) |
| FR-004 | C6 `buildBanner` |
| FR-005 | C6 (check `count()`) |
| FR-006 | C6 (check `count()` idempotent) |
| FR-007 | C14 `AuthResponse`, C16 login |
| FR-008 | C10 `JwtUtil`, C11 `PasswordResetRequiredFilter`, C12 `SecurityConfig`, C16 |
| FR-009 | C13 `FirstLoginResetRequest`, C15 endpoint |
| FR-010 | C15 `firstLoginReset` |
| FR-011 | C15 `BCryptPasswordEncoder.matches` + exception |
| FR-012 | C2, C5, C8 `AdminAuthorizationFilter`, C9 `UserService.toResponse` |
| FR-012a | C1 migrations |
| FR-012b | C7 `AdminSyncRunner` |
| FR-013 | C19 `FirstLoginResetComponent`, C20 route |
| FR-014 | C18 `passwordResetGuard`, C20 |
| FR-015 | C17 `AuthService.firstLoginReset`, C19 navigation |
| FR-016 | Aucun composant Flutter (vérification diff git) |
| FR-017 | C3 `BootstrapProperties` |
| FR-018 | C21 `docs/deployment.md` |

| SC | Vérification |
|----|--------------|
| SC-001 | Chronométrage manuel lors de la phase checklist (C21) |
| SC-002 | Test d'intégration `BootstrapSeedRunnerTest` |
| SC-003 | Test d'intégration `BootstrapSeedRunnerTest` (DB non vide) |
| SC-004 | Test d'intégration `PasswordResetRequiredFilterTest` + test controller |
| SC-005 | Test d'intégration `AdminSyncRunnerTest` |
| SC-006 | Checklist déploiement + démarrage app sans `BOOTSTRAP_EMAIL` |
| SC-007 | Test unitaire `PasswordGeneratorTest` |
