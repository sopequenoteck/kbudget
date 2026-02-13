# Quickstart: Refresh Token JWT Backend

**Feature**: 023-jwt-refresh-token

## Prérequis

- Java 21
- Maven
- PostgreSQL 15+ (local ou Docker)
- Variables d'environnement : `JWT_SECRET` (>= 256 bits, requis en prod)

## Lancer le backend

```bash
cd api && mvn spring-boot:run
```

Le serveur démarre sur `http://localhost:8080/api`.

## Tester les endpoints

### 1. Login (obtenir access + refresh token)

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"secret123"}'
```

Réponse :
```json
{
  "token": "<access_token>",
  "refreshToken": "<refresh_token>",
  "email": "user@example.com",
  "name": "John"
}
```

### 2. Refresh (renouveler les tokens)

```bash
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"<refresh_token>"}'
```

Réponse identique au login (nouveau couple de tokens).

### 3. Logout (révoquer le refresh token)

```bash
curl -X POST http://localhost:8080/api/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"<refresh_token>"}'
```

Réponse : 204 No Content.

### 4. Vérifier la révocation

```bash
# Tenter de réutiliser le token révoqué
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"<refresh_token_revoked>"}'
```

Réponse : 401 avec `"error": "TOKEN_REVOKED"`.

## Tests

```bash
cd api && mvn test
cd api && mvn test -Dtest=RefreshTokenServiceTest    # Service uniquement
cd api && mvn test -Dtest=AuthControllerRefreshTest   # Intégration endpoints
```

## Configuration

| Propriété | Valeur | Description |
|-----------|--------|-------------|
| `app.jwt.access-expiration` | `900000` (15 min) | Durée de vie access token |
| `app.jwt.refresh-expiration` | `2592000000` (30 jours) | Durée de vie refresh token |
| `app.jwt.secret` | env var | Clé HMAC-SHA (>= 256 bits) |

## Notes

- L'access token expire en 15 minutes (FR-008). Le frontend doit implémenter un intercepteur auto-refresh pour renouveler le token avant expiration (feature frontend séparée).
- Le refresh token est une chaîne opaque (pas un JWT). Il est vérifié côté serveur via lookup en base.
- La rotation est automatique : chaque refresh consomme l'ancien token et en génère un nouveau.
