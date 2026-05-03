# API Contracts: Auth Endpoints (Refresh Token)

**Feature**: 023-jwt-refresh-token | **Base path**: `/api/auth`

## Endpoints modifiés

### POST /auth/login (modifié)

**Changement** : la réponse inclut désormais `refreshToken`.

**Request** (inchangé) :
```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

**Response 200** :
```json
{
  "token": "eyJhbGciOiJIUzI1...",
  "refreshToken": "dGhpcyBpcyBhIGJhc2U2NHVybCBlbmNvZGVkIHRva2Vu...",
  "email": "user@example.com",
  "name": "John"
}
```

**Response 401** (inchangé) :
```json
{
  "error": "INVALID_CREDENTIALS",
  "message": "Email ou mot de passe incorrect"
}
```

### POST /auth/register (modifié)

**Changement** : la réponse inclut désormais `refreshToken`.

**Response 201** :
```json
{
  "token": "eyJhbGciOiJIUzI1...",
  "refreshToken": "dGhpcyBpcyBhIGJhc2U2NHVybCBlbmNvZGVkIHRva2Vu...",
  "email": "user@example.com",
  "name": "John"
}
```

---

## Nouveaux endpoints

### POST /auth/refresh

Renouvelle l'access token à partir d'un refresh token valide. Implémente la rotation : l'ancien refresh token est consommé, un nouveau est généré.

**Auth** : Aucune (endpoint public sous `/auth/**`)

**Request** :
```json
{
  "refreshToken": "dGhpcyBpcyBhIGJhc2U2NHVybCBlbmNvZGVkIHRva2Vu..."
}
```

**Response 200** (succès) :
```json
{
  "token": "eyJhbGciOiJIUzI1...",
  "refreshToken": "bmV3IHJlZnJlc2ggdG9rZW4gYmFzZTY0dXJs...",
  "email": "user@example.com",
  "name": "John"
}
```

**Response 401** (token expiré) :
```json
{
  "error": "TOKEN_EXPIRED",
  "message": "Le refresh token a expiré. Veuillez vous reconnecter."
}
```

**Response 401** (token révoqué) :
```json
{
  "error": "TOKEN_REVOKED",
  "message": "Le refresh token a été révoqué."
}
```

**Response 401** (réutilisation détectée — vol potentiel) :
```json
{
  "error": "TOKEN_REUSE_DETECTED",
  "message": "Réutilisation de token détectée. Tous vos tokens ont été révoqués par sécurité."
}
```

**Response 401** (token inconnu) :
```json
{
  "error": "TOKEN_INVALID",
  "message": "Refresh token invalide."
}
```

### POST /auth/logout

Révoque le refresh token fourni. L'utilisateur devra se reconnecter pour obtenir un nouveau couple de tokens.

**Auth** : Aucune (endpoint public sous `/auth/**`)

**Request** :
```json
{
  "refreshToken": "dGhpcyBpcyBhIGJhc2U2NHVybCBlbmNvZGVkIHRva2Vu..."
}
```

**Response 204** (succès) : No Content

**Response 400** (token invalide ou déjà révoqué) :
```json
{
  "error": "TOKEN_INVALID",
  "message": "Refresh token invalide ou déjà révoqué."
}
```

---

## DTOs

### Nouveaux

| DTO | Type | Champs |
|-----|------|--------|
| `RefreshRequest` | record | `@NotBlank String refreshToken` |
| `LogoutRequest` | record | `@NotBlank String refreshToken` |
| `ErrorResponse` | record | `String error, String message` |

### Modifiés

| DTO | Changement |
|-----|-----------|
| `AuthResponse` | Ajout champ `String refreshToken` |

---

## Codes d'erreur

| Code | HTTP | Contexte | Action client attendue |
|------|------|----------|----------------------|
| `TOKEN_EXPIRED` | 401 | Refresh token >30 jours | Rediriger vers login |
| `TOKEN_REVOKED` | 401 | Token invalidé par logout | Rediriger vers login |
| `TOKEN_REUSE_DETECTED` | 401 | Vol potentiel détecté | Rediriger vers login, alerter l'utilisateur |
| `TOKEN_INVALID` | 401 | Token inconnu/malformé | Rediriger vers login |
| `INVALID_CREDENTIALS` | 401 | Login échoué | Afficher erreur |
