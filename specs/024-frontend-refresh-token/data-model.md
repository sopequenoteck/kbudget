# Data Model: Frontend Refresh Token

**Feature**: 024-frontend-refresh-token
**Date**: 2026-02-13

## Entités Frontend (TypeScript)

### AuthResponse (modification)

Interface existante dans `app/src/app/core/models/auth.model.ts`.

| Champ | Type | Description | Statut |
|-------|------|-------------|--------|
| `token` | `string` | Access token JWT (courte durée) | Existant |
| `refreshToken` | `string` | Refresh token opaque (longue durée) | **AJOUT** |
| `email` | `string` | Email de l'utilisateur | Existant |
| `name` | `string` | Nom de l'utilisateur | Existant |

### localStorage Keys

| Clé | Contenu | Lifecycle |
|-----|---------|-----------|
| `budget_token` | Access token JWT | Set au login/register/refresh. Cleared au logout ou échec refresh |
| `budget_refresh_token` | Refresh token opaque | Set au login/register/refresh. Cleared au logout ou échec refresh |
| `budget_user` | JSON `{ name, email }` | Set au login/register. Cleared au logout |

### État interne de l'intercepteur

| Variable | Type | Description |
|----------|------|-------------|
| `isRefreshing` | `boolean` | `true` quand un refresh est en cours |
| `refreshSubject` | `BehaviorSubject<boolean>` | Émet `true` quand le refresh est terminé, permettant aux requêtes en attente de se rejouer |

## Transitions d'état

```
[Session active]
    │
    ├── Access token expire + requête API
    │   ├── Refresh token valide → POST /auth/refresh → [Session active] (nouveaux tokens)
    │   └── Refresh token invalide/expiré → [Déconnexion] → redirect /auth
    │
    ├── Utilisateur clique "Déconnexion"
    │   └── POST /auth/logout (fire-and-forget) → clear localStorage → [Déconnexion] → redirect /auth
    │
    └── Réouverture app (access token expiré)
        ├── Refresh token présent → POST /auth/refresh → [Session active]
        └── Refresh token absent/expiré → [Déconnexion] → redirect /auth
```

## Validation

- `refreshToken` : non-vide, opaque (pas de décodage côté frontend)
- `token` (access) : JWT décodable, champ `exp` vérifié pour déterminer l'expiration
