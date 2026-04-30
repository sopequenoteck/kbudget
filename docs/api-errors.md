# Budget API — Contrat d'erreurs

Reference pour le frontend Angular : format des reponses d'erreur, codes HTTP et regles de validation.

## Format standard

Toutes les erreurs gerees par le `GlobalExceptionHandler` retournent un JSON avec 3 champs, toujours presents :

| Champ | Type | Description |
|-------|------|-------------|
| `timestamp` | string | Date/heure ISO-8601 sans timezone (`2026-02-07T14:30:25.123`) |
| `status` | number | Code HTTP numerique |
| `message` | string | Description lisible de l'erreur |

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 400,
  "message": "Description de l'erreur"
}
```

> **Note** : ce n'est pas un DTO typé — c'est un `Map<String, Object>` construit dans `GlobalExceptionHandler.errorBody()`.

## Codes d'erreur

### 400 Bad Request

Deux sources distinctes.

#### Erreur de validation (MethodArgumentNotValidException)

Declenchee quand un DTO annote `@Valid` echoue la validation Bean Validation. Le message concatene toutes les erreurs de champs avec `;` comme separateur.

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 400,
  "message": "montant: must be positive; libelle: must not be blank"
}
```

Format du message : `champ: contrainte; champ: contrainte; ...`

#### Erreur de logique metier (IllegalArgumentException)

Declenchee explicitement dans les services. Messages connus :

- `"Email deja utilise"` — inscription avec un email existant
- `"Email ou mot de passe incorrect"` — echec de connexion

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 400,
  "message": "Email deja utilise"
}
```

#### Password inchange lors du first-login-reset (KKS-233) ou du change-password (KKS-235)

`PasswordUnchangedException` — le nouveau password soumis est identique a celui en base (verification via `BCryptPasswordEncoder.matches`). Declenche par `POST /auth/first-login-reset` et `POST /api/users/me/password`. Format `ErrorResponse` :

```json
{
  "error": "PASSWORD_UNCHANGED",
  "message": "Le nouveau mot de passe doit être différent de l'actuel."
}
```

#### Format d'image invalide (KKS-235)

`InvalidImageFormatException` — declenchee dans `POST /api/users/me/avatar` quand le `Content-Type` ou la signature binaire ne correspond pas a `image/jpeg` ou `image/png`. Format `ErrorResponse` :

```json
{
  "error": "INVALID_IMAGE_FORMAT",
  "message": "Format d'image non supporté. Utilisez JPG ou PNG."
}
```

#### Confirmation requise (KKS-235)

`ConfirmationRequiredException` — declenchee dans `DELETE /api/users/me` quand le champ `confirmation` n'est pas exactement la chaine `SUPPRIMER`. Format `ErrorResponse` :

```json
{
  "error": "CONFIRMATION_REQUIRED",
  "message": "Vous devez confirmer la suppression en saisissant SUPPRIMER."
}
```

#### Format d'export invalide (KKS-235)

`InvalidExportFormatException` — declenchee dans `GET /api/users/me/export` quand le parametre `format` est absent ou autre que `json`/`csv`. Format `ErrorResponse` :

```json
{
  "error": "INVALID_EXPORT_FORMAT",
  "message": "Format d'export invalide. Utilisez 'json' ou 'csv'."
}
```

### 401 Unauthorized

Declenchee par les exceptions JWT dans `RefreshTokenService`. **Format different** du format standard — utilise le DTO `ErrorResponse` :

```json
{
  "error": "TOKEN_EXPIRED",
  "message": "Le refresh token a expire. Veuillez vous reconnecter."
}
```

| Exception | Code erreur | Message |
|-----------|-------------|---------|
| `TokenExpiredException` | `TOKEN_EXPIRED` | Le refresh token a expire. Veuillez vous reconnecter. |
| `TokenRevokedException` | `TOKEN_REVOKED` | Le refresh token a ete revoque. |
| `TokenReusedException` | `TOKEN_REUSE_DETECTED` | Reutilisation de token detectee. Tous vos tokens ont ete revoques par securite. |
| `TokenInvalidException` | `TOKEN_INVALID` | Refresh token invalide. |

#### Password incorrect (KKS-235)

`PasswordIncorrectException` — declenchee dans `POST /api/users/me/password` (verification du `currentPassword`) et `DELETE /api/users/me` (verification du `password` de confirmation). Format `ErrorResponse` :

```json
{
  "error": "PASSWORD_INCORRECT",
  "message": "Le mot de passe actuel est incorrect."
}
```

> **Attention** : ces erreurs ne suivent pas le format standard (`timestamp`/`status`/`message`). Elles retournent un objet `ErrorResponse` avec les champs `error` et `message` uniquement.

### 403 Forbidden

Trois sources distinctes.

#### Spring Security (access denied)

Declenchee quand le header `Authorization` est absent ou le token invalide sur une route protegee. Spring Security retourne son propre format ou un corps vide.

#### Feature desactivee (FeatureDisabledException)

Declenchee par le `GlobalExceptionHandler` quand une feature optionnelle est desactivee dans les preferences utilisateur (ex: DEBTS). Le corps suit le format standard (`timestamp`, `status: 403`, `message`).

#### Reset des credentials requis ou non requis (KKS-233)

Declenchees dans le flow `POST /auth/first-login-reset`. Le corps utilise le DTO `ErrorResponse` (`error` + `message`).

| Origine | Code erreur | Quand |
|---------|-------------|-------|
| `PasswordResetRequiredFilter` | `PASSWORD_RESET_REQUIRED` | JWT porte le claim `mustResetCredentials: true` et la requete cible un endpoint hors allowlist (`/auth/first-login-reset`, `/auth/logout`). Le user doit d'abord completer son reset. |
| `PasswordResetNotRequiredException` | `PASSWORD_RESET_NOT_REQUIRED` | Le user authentifie a deja `password_reset_required = false` en DB. Neutralise egalement les anciens JWT qui auraient le claim mais dont la DB est desynchronisee. |
| `LastAdminDeletionForbiddenException` | `LAST_ADMIN_DELETION_FORBIDDEN` | Le user authentifie tente de supprimer son compte (`DELETE /api/users/me`) alors qu'il est le dernier admin actif. Reponse au format `ErrorResponse`. Garde-fou symetrique a `LAST_ADMIN_CANNOT_BE_DISABLED` (409, desactivation par un autre admin). |

```json
{
  "error": "PASSWORD_RESET_REQUIRED",
  "message": "Credentials reset required before accessing this resource."
}
```

Routes publiques (pas de JWT requis) :

- `/auth/**`
- `/error`
- `/v3/api-docs/**`, `/swagger-ui/**`, `/swagger-ui.html`
- `/banks`, `/bank-logos/**`
- `/ws/**` (auth via StompAuthInterceptor)

### 404 Not Found

Declenchee via `EntityNotFoundException` quand :

- La ressource demandee n'existe pas
- La ressource existe mais n'appartient pas a l'utilisateur authentifie (meme comportement pour ne pas reveler l'existence de ressources d'autres utilisateurs)

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 404,
  "message": "Transaction not found"
}
```

#### Avatar absent (KKS-235)

`AvatarNotFoundException` — declenchee dans `GET /api/users/me/avatar` et `DELETE /api/users/me/avatar` quand le user n'a pas d'avatar configure (`users.avatar_path IS NULL`). Format `ErrorResponse` :

```json
{
  "error": "AVATAR_NOT_FOUND",
  "message": "Aucun avatar configuré pour cet utilisateur."
}
```

### 409 Conflict

Declenchee par `ConflictException` :
- Un brouillon d'import actif (PENDING) existe deja pour le compte cible
- Pattern de libelle de regle de categorisation deja existant pour l'utilisateur
- Tentative de desactivation du dernier admin actif (via `PATCH /api/admin/users/{id}/disable`)
- Email deja utilise par un autre utilisateur lors du `POST /auth/first-login-reset` (KKS-233, code `EMAIL_ALREADY_EXISTS`)

```json
{
  "timestamp": "2026-03-20T14:30:25",
  "status": 409,
  "message": "Un brouillon d'import actif existe deja pour ce compte"
}
```

Pour le garde-fou dernier admin, la reponse contient un champ `error` en plus pour permettre une distinction machine :

```json
{
  "timestamp": "2026-04-19T14:30:25",
  "status": 409,
  "error": "LAST_ADMIN_CANNOT_BE_DISABLED",
  "message": "Impossible de desactiver le dernier admin actif."
}
```

Le frontend (Angular + Flutter) distingue ce cas via `error === 'LAST_ADMIN_CANNOT_BE_DISABLED'` pour afficher un message specifique.

### 413 Payload Too Large

#### Avatar trop volumineux (KKS-235)

`FileTooLargeException` — declenchee dans `POST /api/users/me/avatar` quand le fichier depasse 2 Mo. Format `ErrorResponse` :

```json
{
  "error": "FILE_TOO_LARGE",
  "message": "L'image dépasse la taille maximale autorisée (2 Mo)."
}
```

### 422 Unprocessable Entity

Declenchee par `CsvProfileNotFoundException` :
- Le format CSV uploade ne correspond a aucun profil connu (ni registre ni custom)
- Utiliser `/imports/upload-with-mapping` avec un mapping manuel

```json
{
  "timestamp": "2026-03-20T14:30:25",
  "status": 422,
  "message": "Aucun profil d'import trouve pour le format CSV"
}
```

### 500 Internal Server Error

Declenchee par le handler generique `Exception`. Le message est toujours le meme — aucun detail technique n'est expose au client.

```json
{
  "timestamp": "2026-02-07T14:30:25.123456789",
  "status": 500,
  "message": "Une erreur interne est survenue"
}
```

## Regles de validation par endpoint

### POST /api/auth/register — **supprime** (KKS-232)

Route retiree. L'onboarding se fait via invitation admin (voir `POST /api/admin/invitations` puis `POST /api/auth/accept-invite`).

### POST /api/auth/accept-invite — `AcceptInviteRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `token` | `@NotNull`, UUID | oui |
| `password` | `@NotBlank`, `@Size(min=8, max=100)` | oui |
| `displayName` | `@NotBlank`, `@Size(max=100)` | oui |
| `currency` | Enum `Currency` (EUR, XOF, USD, GBP, CHF, CAD, MAD) | oui |
| `timezone` | Identifiant IANA valide | oui |

> `email` n'est **pas** dans le body — il vient de l'invitation (verrouille cote serveur, FR-015).

### POST /api/admin/invitations — `CreateInvitationRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `email` | `@NotBlank`, `@Email` | oui |

### POST /api/auth/login — `LoginRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `email` | `@NotBlank`, `@Email` | oui |
| `password` | `@NotBlank` | oui |

### POST/PUT /api/transactions — `TransactionRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `montant` | `@NotNull`, `@Positive` | oui |
| `libelle` | `@NotBlank`, `@Size(max=255)` | oui |
| `type` | `@NotNull`, enum `TransactionType` (DEPENSE, RECETTE) | oui |
| `date` | `@NotNull`, `LocalDate` | oui |
| `categorie` | `@Size(max=255)` | non |
| `note` | `@Size(max=500)` | non |

### POST/PUT /api/subscriptions — `SubscriptionRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `nom` | `@NotBlank`, `@Size(max=255)` | oui |
| `montant` | `@NotNull`, `@Positive` | oui |
| `frequence` | `@NotNull`, enum `Frequency` (MENSUEL, ANNUEL) | oui |
| `dateDebut` | `@NotNull`, `LocalDate` | oui |
| `actif` | `Boolean` | non |

### POST/PUT /api/debts — `DebtRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `personne` | `@NotBlank`, `@Size(max=255)` | oui |
| `montant` | `@NotNull`, `@Positive` | oui |
| `sens` | `@NotNull`, enum `DebtType` (EMPRUNT, PRET) | oui |
| `date` | `@NotNull`, `LocalDate` | oui |
| `rembourse` | `Boolean` | non |

### PUT /api/users/me — `UpdateProfileRequest` (KKS-235)

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `name` | `@NotBlank`, `@Size(max=100)` | oui |

> Seul le `name` est modifiable. L'email est en lecture seule (changement hors scope KKS-235).

### POST /api/users/me/password — `ChangePasswordRequest` (KKS-235)

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `currentPassword` | `@NotBlank` | oui |
| `newPassword` | `@NotBlank`, `@Size(min=12, max=100)` | oui |

Erreurs metier : `PASSWORD_INCORRECT` (401), `PASSWORD_UNCHANGED` (400).

### DELETE /api/users/me — `DeleteAccountRequest` (KKS-235)

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `password` | `@NotBlank` | oui |
| `confirmation` | `@NotBlank`, doit valoir exactement `SUPPRIMER` (case-sensitive) | oui |

Erreurs metier : `CONFIRMATION_REQUIRED` (400), `PASSWORD_INCORRECT` (401), `LAST_ADMIN_DELETION_FORBIDDEN` (403).

### POST /api/users/me/avatar — multipart (KKS-235)

| Champ | Contraintes |
|-------|-------------|
| `file` | type MIME `image/jpeg` ou `image/png`, taille ≤ 2 Mo |

Erreurs metier : `INVALID_IMAGE_FORMAT` (400), `FILE_TOO_LARGE` (413).

### PUT /api/users/me/preferences — `UserPreferenceRequest`

| Champ | Contraintes | Obligatoire |
|-------|-------------|:-----------:|
| `enabledFeatures` | `@NotNull`, `List<Feature>` (SUBSCRIPTIONS, DEBTS, BUDGETS) | oui |
| `navOrder` | `List<Feature>` — si fourni : doit contenir exactement les features activees, sans doublons | non |

Messages d'erreur metier (IllegalArgumentException → 400) :
- `"L'ordre de navigation ne doit pas contenir de doublons"`
- `"L'ordre de navigation doit contenir exactement les fonctionnalites activees"`

## Guide d'integration frontend

### Intercepteur HTTP Angular

L'intercepteur doit traiter les erreurs selon le code HTTP, pas le body (qui n'est pas garanti pour le 403).

```typescript
// Logique recommandee dans un HttpInterceptor Angular

switch (error.status) {
  case 400:
    // Parser error.error.message pour afficher a l'utilisateur
    // Si le message contient ";" → erreurs de validation multiples
    // Sinon → erreur metier directe
    break;

  case 401:
    // Format ErrorResponse : { error: string, message: string }
    // Utiliser error.error.error pour le code (TOKEN_EXPIRED, etc.)
    // TOKEN_REUSE_DETECTED → forcer deconnexion immediate
    // TOKEN_EXPIRED → tenter un refresh silencieux
    break;

  case 403:
    // Deux cas : Spring Security (pas de body fiable) ou FeatureDisabledException (format standard)
    // Si body present avec status 403 → feature desactivee
    // Sinon → rediriger vers login
    break;

  case 404:
    // Afficher "Ressource introuvable" ou rediriger
    break;

  case 500:
    // Afficher message generique, ne pas exposer error.error.message
    // (il dit toujours "Une erreur interne est survenue")
    break;
}
```

### Interfaces TypeScript

```typescript
// Format standard (400, 403 feature, 404, 409, 422, 500)
interface ApiError {
  timestamp: string;  // ISO-8601 sans timezone
  status: number;
  message: string;
}

// Format JWT (401)
interface TokenError {
  error: string;   // TOKEN_EXPIRED | TOKEN_REVOKED | TOKEN_REUSE_DETECTED | TOKEN_INVALID
  message: string;
}
```

### Distinction erreur de validation vs erreur metier (400)

Le message de validation contient des `;` et suit le pattern `champ: contrainte`. Un split sur `"; "` permet d'extraire les erreurs par champ :

```typescript
function parseValidationErrors(message: string): Map<string, string> {
  const errors = new Map<string, string>();
  message.split('; ').forEach(part => {
    const [field, ...rest] = part.split(': ');
    errors.set(field, rest.join(': '));
  });
  return errors;
}
```
