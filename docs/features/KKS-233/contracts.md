# Contrats techniques — KKS-233 : Bootstrap du premier admin sur DB vide

> Date : 2026-04-22
> Issue : KKS-233
> Plan : [plan.md](./plan.md)
> Data-model : [data-model.md](./data-model.md)

---

## 1. Interfaces & Types

### 1.1 Entité `User` (modifiée)

> Réf : FR-002, FR-012, data-model §1

```java
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    private String name;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "disabled_at")
    private LocalDateTime disabledAt;

    @Column(name = "is_admin", nullable = false)
    private boolean isAdmin;                   // NOUVEAU — FR-012

    @Column(name = "password_reset_required", nullable = false)
    private boolean passwordResetRequired;     // NOUVEAU — FR-002
}
```

**Propriété Lombok `@Data`** génère les accesseurs `isAdmin()`, `setAdmin(boolean)`, `isPasswordResetRequired()`, `setPasswordResetRequired(boolean)`.

---

### 1.2 DTO `FirstLoginResetRequest` (nouveau)

> Réf : FR-009, FR-011

```java
public record FirstLoginResetRequest(
    @NotBlank
    @Email
    @Size(max = 255)
    String email,

    @NotBlank
    @Size(min = 8, max = 100)
    String password,

    @NotBlank
    @Size(min = 1, max = 100)
    String displayName
) {}
```

**Règles de validation** :
- `email` : obligatoire, format email syntaxique, 255 chars max.
- `password` : obligatoire, 8 à 100 chars (aligné sur `AcceptInviteRequest`).
- `displayName` : obligatoire, 1 à 100 chars (résolution Q-DIFF-04 : obligatoire, cohérent onboarding).

---

### 1.3 DTO `AuthResponse` (modifié)

> Réf : FR-007, RES-006, résolution Q-DIFF-01

```java
public record AuthResponse(
    String token,
    String refreshToken,
    String email,
    String name,
    boolean mustResetCredentials     // NOUVEAU — toujours présent, default false
) {}
```

**Compatibilité** : tous les consommateurs doivent être mis à jour (`AuthService.login`, `AcceptInviteService.acceptInvite`, `RefreshTokenService.refreshAccessToken`, `AuthService.firstLoginReset`).

---

### 1.4 `UserProvisioningRequest` (nouveau — record interne service)

> Réf : RES-001

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
```

**Usage** : paramètre d'entrée unique de `UserOnboardingService.provisionUser`.

---

### 1.5 Exception `PasswordUnchangedException` (nouvelle)

> Réf : FR-011

```java
public class PasswordUnchangedException extends RuntimeException {
    public PasswordUnchangedException() {
        super("Le nouveau mot de passe doit être différent de l'actuel.");
    }
}
```

Mappée dans `GlobalExceptionHandler` vers `400 Bad Request` avec payload `{ "error": "PASSWORD_UNCHANGED", "message": "..." }`.

---

### 1.6 `BootstrapProperties` (nouveau — config)

> Réf : FR-017, RES-005

```java
@Component
@ConfigurationProperties(prefix = "app.bootstrap")
@Validated
@Data
public class BootstrapProperties {

    @NotBlank
    @Email
    private String email = "admin@localhost";
}
```

**Clé YAML** : `app.bootstrap.email`, liée à `${BOOTSTRAP_EMAIL:admin@localhost}`.

**Comportement au démarrage** : si `BOOTSTRAP_EMAIL` est défini et invalide, Spring Boot lève `ConfigurationPropertiesBindException` avec un message structuré → fail-fast.

---

### 1.7 Interface TypeScript `AuthResponse` (modifiée, Angular)

> Réf : FR-007

```ts
export interface AuthResponse {
  token: string;
  refreshToken: string;
  email: string;
  name: string;
  mustResetCredentials: boolean;   // NOUVEAU
}
```

### 1.8 Interface TypeScript `UserInfo` (modifiée, Angular)

> Réf : FR-014, RES-010

```ts
export interface UserInfo {
  name: string;
  email: string;
  isAdmin?: boolean;
  mustResetCredentials: boolean;   // NOUVEAU
}
```

### 1.9 Interface TypeScript `FirstLoginResetRequest` (nouvelle, Angular)

> Réf : FR-013

```ts
export interface FirstLoginResetRequest {
  email: string;
  password: string;
  displayName: string;
}
```

---

## 2. API Endpoints

### 2.1 `POST /api/auth/first-login-reset` (nouveau)

> Réf : FR-009, FR-010, FR-011, SC-004

**Summary** : Compléter le reset forcé des credentials pour un user avec `passwordResetRequired = true`.

**Auth** : JWT obligatoire (header `Authorization: Bearer <token>`) portant le claim `mustResetCredentials: true`.

**Request body** (`FirstLoginResetRequest`) :

```json
{
  "email": "kelly@exemple.com",
  "password": "NouveauMotDePasseFort!",
  "displayName": "Kelly"
}
```

**Responses** :

| Code | Cas | Payload |
|------|-----|---------|
| `200 OK` | Reset réussi | `AuthResponse` avec `mustResetCredentials: false` et un nouveau JWT |
| `400 Bad Request` | Validation Bean échouée | `{ error, message, fieldErrors: [...] }` |
| `400 Bad Request` | Nouveau password identique à l'actuel | `{ "error": "PASSWORD_UNCHANGED", "message": "Le nouveau mot de passe doit être différent de l'actuel." }` |
| `401 Unauthorized` | JWT invalide ou absent | vide |
| `403 Forbidden` | User authentifié mais `passwordResetRequired = false` en DB | `{ "error": "PASSWORD_RESET_NOT_REQUIRED", "message": "..." }` |
| `409 Conflict` | Email déjà utilisé par un autre user | `{ "error": "EMAIL_ALREADY_EXISTS", "message": "..." }` |

**Effets de bord** :
- `UPDATE users SET email = ?, password = ?, name = ?, password_reset_required = false WHERE id = ?`.
- Émission d'un nouveau JWT **sans** le claim `mustResetCredentials`.
- Émission d'un nouveau refresh token.
- Log INFO : `"User reset credentials: userId={} newEmail={}"`.
- Transaction `@Transactional` atomique : rollback complet en cas d'erreur.

---

### 2.2 `POST /api/auth/login` (modifié)

> Réf : FR-007

**Modification** : la réponse inclut désormais le champ `mustResetCredentials` (boolean, toujours présent). Le JWT émis porte le claim `mustResetCredentials: true` si et seulement si `user.passwordResetRequired == true`.

**Request body** : inchangé (`LoginRequest`).

**Responses** : inchangées en codes. Payload `AuthResponse` enrichi.

---

### 2.3 `POST /api/auth/accept-invite` (modifié)

> Réf : FR-007

**Modification** : la réponse inclut le champ `mustResetCredentials: false` (un user créé via invitation n'a jamais de flag actif).

---

### 2.4 `POST /api/auth/refresh` (modifié)

> Réf : FR-007, FR-008

**Modification** : le JWT retourné préserve le claim `mustResetCredentials` selon l'état actuel `user.passwordResetRequired` en DB. La réponse inclut `mustResetCredentials` actualisée.

---

### 2.5 `POST /api/auth/logout` (inchangé techniquement, mais allowlist)

> Réf : FR-008

**Ajout dans la spec** : cet endpoint est explicitement autorisé pour un JWT porteur du claim `mustResetCredentials: true`, afin de permettre à un user d'abandonner son reset sans être verrouillé.

---

## 3. Contrats services (Spring)

### 3.1 `UserOnboardingService` (nouveau)

> Réf : FR-002, FR-003, RES-001

**Package** : `fr.kksdev.budget.api.service`

**Méthode publique** :

```java
@Transactional
public User provisionUser(UserProvisioningRequest request);
```

**Comportement** :
- Crée un `User` avec les champs du `request` (password hashé via `PasswordEncoder`).
- Crée les entités satellites : categories système (`CategoryService.seedSystemCategories`), compte par défaut (`AccountService.createDefaultAccount`), preferences initiales (`PreferenceService.createInitialPreference`).
- Transaction atomique.

**Erreurs** :
- `DataIntegrityViolationException` si email déjà utilisé → à convertir en `ConflictException` côté appelant si nécessaire.

**Consommateurs** : `AcceptInviteService`, `BootstrapSeedRunner`.

---

### 3.2 `AuthService` — méthode `firstLoginReset` (nouvelle)

> Réf : FR-010, FR-011

**Signature** :

```java
@Transactional
public AuthResponse firstLoginReset(UUID userId, FirstLoginResetRequest request);
```

**Précondition** : le user authentifié (identifié par `userId`) doit avoir `passwordResetRequired == true` en DB.

**Comportement** :
1. Charger le user via `userRepository.findById(userId)` → `EntityNotFoundException` sinon.
2. Si `!user.isPasswordResetRequired()` → `AccessDeniedException` → 403.
3. Si `passwordEncoder.matches(request.password(), user.getPassword())` → `PasswordUnchangedException` → 400.
4. Vérifier unicité de l'email si changement → `ConflictException` → 409 sinon.
5. Mettre à jour `email`, `password` (hashé), `name`, `passwordResetRequired = false`.
6. Sauvegarder.
7. Générer un nouveau JWT (sans claim `mustResetCredentials`) et un nouveau refresh token.
8. Retourner `AuthResponse(token, refreshToken, email, name, false)`.
9. Logger INFO.

**Transaction** : `@Transactional` atomique.

---

### 3.3 `AuthService.login` (modifié)

> Réf : FR-007, FR-008

**Modification** : après validation des credentials, émettre le JWT avec claim additionnel si flag actif :

```java
Map<String, Object> extraClaims = user.isPasswordResetRequired()
    ? Map.of("mustResetCredentials", true)
    : Map.of();
String token = jwtUtil.generateToken(user.getEmail(), extraClaims);
return new AuthResponse(
    token, refreshToken, user.getEmail(), user.getName(),
    user.isPasswordResetRequired()
);
```

---

### 3.4 `AcceptInviteService.acceptInvite` (refactor)

> Réf : RES-001

**Modification** : déléguer la création du user aux dépendances via `UserOnboardingService.provisionUser` :

```java
User user = userOnboardingService.provisionUser(new UserProvisioningRequest(
    invitation.getEmail(),
    request.password(),
    request.displayName(),
    request.currency(),
    request.timezone(),
    false,  // isAdmin (accept-invite ne crée jamais d'admin par défaut)
    false   // passwordResetRequired (l'utilisateur définit déjà son mot de passe)
));
```

**Suite** : `invitationService.markUsed(invitation)`, génération JWT + refresh token (inchangés).

---

### 3.5 `UserService.toResponse` (refactor)

> Réf : FR-012

**Modification** : remplacer l'appel `adminEmailResolver.isAdminEmail(user.getEmail())` par `user.isAdmin()` :

```java
private UserResponse toResponse(User user) {
    return new UserResponse(
        user.getName(),
        user.getEmail(),
        user.isAdmin()
    );
}
```

Suppression de la dépendance `AdminEmailResolver` du constructeur `UserService`.

---

### 3.6 `JwtUtil` (extension)

> Réf : FR-008, RES-003

**Nouvelles méthodes** :

```java
public String generateToken(String email, Map<String, Object> extraClaims);
public Object extractClaim(String token, String claimName);
```

**Surcharge existante conservée** :

```java
public String generateToken(String email);   // équivalent à generateToken(email, Map.of())
```

**Contrat** :
- `generateToken(email, claims)` : les claims sont ajoutés avant `signWith`. Claims système (`sub`, `iat`, `exp`) ne doivent pas être surchargés.
- `extractClaim(token, name)` : retourne `null` si le claim est absent, sinon la valeur. Ne lève pas d'exception si le token est valide.

---

## 4. Contrats filtres HTTP (Spring Security)

### 4.1 `PasswordResetRequiredFilter` (nouveau)

> Réf : FR-008, RES-004

**Classe** : `fr.kksdev.budget.api.config.PasswordResetRequiredFilter extends OncePerRequestFilter`

**Position dans la chaîne** : après `JwtFilter`, avant `AdminAuthorizationFilter`.

**Allowlist de paths** (exact-match sur `request.getServletPath()`) :
- `/auth/first-login-reset`
- `/auth/logout`

**Algorithme** :

```
1. Si pas d'authentification dans le SecurityContext → laisse passer (401 natif si route protégée).
2. Extraire le Bearer token du header Authorization → si absent, laisse passer.
3. Extraire le claim "mustResetCredentials" du token.
4. Si claim != true → laisse passer.
5. Si claim == true et path ∈ allowlist → laisse passer.
6. Sinon → répond 403 Forbidden avec payload JSON `{"error":"PASSWORD_RESET_REQUIRED","message":"..."}`.
```

**Log** : INFO sur blocage (`"Request blocked by password-reset gate: path={}"`).

---

### 4.2 `AdminAuthorizationFilter` (refactor)

> Réf : FR-012

**Modification** : la résolution du statut admin bascule de dynamique à DB :

Avant :
```java
boolean isAdmin = userOpt.map(u -> adminEmailResolver.isAdminEmail(u.getEmail())).orElse(false);
```

Après :
```java
boolean isAdmin = userOpt.map(User::isAdmin).orElse(false);
```

Suppression de la dépendance `AdminEmailResolver` du constructeur.

---

## 5. Contrats runners (Spring)

### 5.1 `BootstrapSeedRunner` (nouveau)

> Réf : FR-001, FR-002, FR-004, FR-005, FR-006

**Classe** : `fr.kksdev.budget.api.runner.BootstrapSeedRunner implements ApplicationRunner`

**Annotations** :
- `@Component`
- `@Order(1)` — exécution avant `AdminSyncRunner`
- `@RequiredArgsConstructor`
- `@Slf4j`

**Dépendances** : `UserRepository`, `UserOnboardingService`, `BootstrapProperties`.

**Contrat de `run(ApplicationArguments args)`** :

```
1. Si userRepository.count() > 0 → return (aucun seed).
2. Générer un password aléatoire 32 chars via PasswordGenerator.generate(32).
3. Appeler userOnboardingService.provisionUser avec :
   - email = bootstrapProperties.getEmail()
   - rawPassword = <password généré>
   - displayName = "Admin"
   - currency = Currency.EUR
   - timezone = "Europe/Paris"
   - isAdmin = true
   - passwordResetRequired = true
4. Logger la bannière WARN via log.warn(buildBanner(email, rawPassword)).
```

**Idempotence** : garantie par la condition `count() == 0`. Un redémarrage après seed ne fait rien.

---

### 5.2 `AdminSyncRunner` (nouveau)

> Réf : FR-012b, US-004

**Classe** : `fr.kksdev.budget.api.runner.AdminSyncRunner implements ApplicationRunner`

**Annotations** : `@Component`, `@Order(2)`, `@RequiredArgsConstructor`, `@Slf4j`.

**Dépendances** : `AdminEmailResolver` (listAdminEmails), `UserRepository`.

**Contrat de `run(ApplicationArguments args)`** :

```
1. Charger la liste des emails admin via adminEmailResolver.listAdminEmails().
2. Pour chaque email :
   a. Charger le user via userRepository.findByEmail(email).
   b. Si user existe ET !user.isAdmin() → setAdmin(true), save, logger INFO.
   c. Si user existe ET user.isAdmin() → ne rien faire.
   d. Si user n'existe pas → ne rien faire (pas d'erreur).
3. Aucune opération de rétrogradation n'est effectuée.
```

**Transaction** : `@Transactional` sur la méthode `run` pour atomiser toutes les promotions.

**Idempotence** : garantie par le filtre `!user.isAdmin()`. Promouvoir deux fois est un no-op.

---

## 6. Contrats utilitaires

### 6.1 `PasswordGenerator` (nouveau)

> Réf : FR-002, SC-007

**Classe** : `fr.kksdev.budget.api.util.PasswordGenerator` — final, constructeur privé.

**Méthode publique** :

```java
public static String generate(int length);
```

**Contrat** :
- Retourne une chaîne de `length` caractères exactement.
- Chaque caractère ∈ `[A-Za-z0-9]` (62 symboles).
- Source d'entropie : `java.security.SecureRandom` (unique instance statique).
- Non déterministe.

**Précondition** : `length > 0` (pas de validation défensive, appelants contrôlés).

---

## 7. Contrats migrations Flyway

### 7.1 `V30__add_user_is_admin.sql`

> Réf : FR-012a

```sql
ALTER TABLE users
  ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE;
```

**Contrat** : l'existence de la colonne est une précondition pour le démarrage de l'application après déploiement (sinon `AdminAuthorizationFilter` lève une erreur JPA à la première requête).

### 7.2 `V31__add_user_password_reset_required.sql`

> Réf : FR-002

```sql
ALTER TABLE users
  ADD COLUMN password_reset_required BOOLEAN NOT NULL DEFAULT FALSE;
```

---

## 8. Contrats frontend (Angular)

### 8.1 Service `AuthService` — méthode `firstLoginReset` (nouvelle)

> Réf : FR-015

```ts
firstLoginReset(payload: FirstLoginResetRequest): Observable<AuthResponse>;
```

**Comportement** :
- POST sur `/auth/first-login-reset` avec le payload.
- En cas de succès : appelle `saveAuth(response)` (remplacement du JWT, du refresh token et du `UserInfo` persisté).
- En cas d'erreur : propage l'erreur au caller.

### 8.2 Service `AuthService` — computed `mustResetCredentials` (nouveau)

> Réf : FR-014

```ts
readonly mustResetCredentials = computed(() =>
  this.currentUser()?.mustResetCredentials ?? false
);
```

### 8.3 Service `AuthService.saveAuth` (modifié)

> Réf : RES-010

**Modification** : inclure `mustResetCredentials` dans le `UserInfo` persisté en `localStorage` et dans le signal `currentUser`.

---

### 8.4 Guard `passwordResetGuard` (nouveau)

> Réf : FR-014

```ts
export const passwordResetGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.mustResetCredentials()
    ? router.createUrlTree(['/first-login-reset'])
    : true;
};
```

**Usage** : appliqué **après** `authGuard` sur chaque route protégée.

### 8.5 Guard `notPasswordResetGuard` (nouveau)

> Réf : FR-014

```ts
export const notPasswordResetGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.mustResetCredentials()
    ? true
    : router.createUrlTree(['/']);
};
```

**Usage** : appliqué sur la route `/first-login-reset` uniquement.

---

### 8.6 Composant `FirstLoginResetComponent` (nouveau)

> Réf : FR-013, FR-015

**Sélecteur** : `app-first-login-reset`

**Annotations** :
- `standalone: true`
- `changeDetection: ChangeDetectionStrategy.OnPush`

**Inputs** : aucun.

**Outputs** : aucun (navigation gérée en interne après succès).

**État interne** (signals) :
- `isSubmitting: WritableSignal<boolean>` — désactive le bouton pendant la requête.
- `errorMessage: WritableSignal<string | null>` — affiche l'erreur API.

**Form** : `ReactiveForm` ou Signals-based form avec quatre contrôles :
- `email` : `Validators.required`, `Validators.email`.
- `password` : `Validators.required`, `Validators.minLength(8)`, `Validators.maxLength(100)`.
- `passwordConfirm` : `Validators.required`, validator custom d'égalité avec `password`.
- `displayName` : `Validators.required`, `Validators.maxLength(100)`.

**Submit handler** :
```ts
onSubmit() {
  if (form.invalid) return;
  isSubmitting.set(true);
  authService.firstLoginReset({
    email: form.value.email,
    password: form.value.password,
    displayName: form.value.displayName
  }).subscribe({
    next: () => router.navigateByUrl('/'),
    error: (err) => {
      errorMessage.set(mapError(err));
      isSubmitting.set(false);
    }
  });
}
```

---

### 8.7 Configuration des routes (modifiée)

> Réf : FR-013, FR-014

**Ajout** dans `app.routes.ts` (racine) :

```ts
{
  path: 'first-login-reset',
  canActivate: [authGuard, notPasswordResetGuard],
  loadComponent: () =>
    import('./features/auth/first-login-reset/first-login-reset.component')
      .then(m => m.FirstLoginResetComponent)
}
```

**Modification** : appliquer `passwordResetGuard` sur toutes les routes protégées après `authGuard` :

```ts
{
  path: '',
  canActivate: [authGuard, passwordResetGuard],
  children: [ /* routes protégées */ ]
}
```

---

## 9. Synthèse

| Catégorie | Nombre |
|-----------|--------|
| Entités modifiées | 1 (`User`) |
| DTO Request nouveaux | 1 (`FirstLoginResetRequest`) |
| DTO Response modifiés | 1 (`AuthResponse`) |
| Records internes nouveaux | 1 (`UserProvisioningRequest`) |
| Exceptions nouvelles | 1 (`PasswordUnchangedException`) |
| Config nouvelles | 1 (`BootstrapProperties`) |
| Interfaces TypeScript modifiées | 2 (`AuthResponse`, `UserInfo`) |
| Interfaces TypeScript nouvelles | 1 (`FirstLoginResetRequest`) |
| Endpoints REST nouveaux | 1 (`POST /api/auth/first-login-reset`) |
| Endpoints REST impactés (réponse enrichie) | 3 (`login`, `accept-invite`, `refresh`) |
| Services Spring nouveaux | 1 (`UserOnboardingService`) |
| Méthodes services nouvelles | 1 (`AuthService.firstLoginReset`) |
| Services Spring refactorés | 3 (`AuthService.login`, `AcceptInviteService.acceptInvite`, `UserService.toResponse`) |
| Filtres HTTP nouveaux | 1 (`PasswordResetRequiredFilter`) |
| Filtres HTTP refactorés | 1 (`AdminAuthorizationFilter`) |
| Extensions `JwtUtil` | 2 méthodes (`generateToken(email, claims)`, `extractClaim`) |
| Runners Spring nouveaux | 2 (`BootstrapSeedRunner`, `AdminSyncRunner`) |
| Utilitaires nouveaux | 1 (`PasswordGenerator`) |
| Migrations Flyway | 2 (V30, V31) |
| Guards Angular nouveaux | 2 (`passwordResetGuard`, `notPasswordResetGuard`) |
| Composants Angular nouveaux | 1 (`FirstLoginResetComponent`) |
| Services Angular modifiés | 1 (`AuthService`) |
