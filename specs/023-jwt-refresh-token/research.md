# Research: Refresh Token JWT Backend

**Feature**: 023-jwt-refresh-token | **Date**: 2026-02-13

## R1 — Stratégie de rotation des refresh tokens

**Decision**: Rotation obligatoire avec détection de réutilisation (Refresh Token Rotation + Reuse Detection)

**Rationale**: Chaque utilisation d'un refresh token le consomme (statut CONSUMED) et en génère un nouveau. Si un token CONSUMED est présenté, cela indique un vol potentiel — tous les tokens ACTIVE de l'utilisateur sont révoqués. C'est la recommandation OWASP et le pattern standard (Auth0, Okta).

**Alternatives considered**:
- Pas de rotation (refresh token réutilisable) — rejeté : un token volé reste exploitable indéfiniment
- Blacklist/whitelist sans rotation — rejeté : plus complexe, même résultat sécuritaire sans la détection de réutilisation

## R2 — Stockage du refresh token (opaque vs JWT)

**Decision**: Token opaque (SecureRandom 32 bytes, Base64url) stocké en base de données

**Rationale**: Le token opaque nécessite une vérification côté serveur (lookup DB), ce qui permet la révocation immédiate et le tracking des statuts. Un JWT refresh serait auto-suffisant mais ne permettrait pas la révocation sans blacklist.

**Alternatives considered**:
- JWT comme refresh token — rejeté : nécessite une blacklist pour la révocation, annule l'avantage du stateless
- UUID v4 — rejeté : 122 bits d'entropie vs 256 bits pour SecureRandom 32 bytes

## R3 — Format de la table refresh_tokens

**Decision**: Table dédiée `refresh_tokens` avec FK vers `users`, colonnes statut et expiration

**Rationale**: Table séparée (pas une colonne sur `users`) car un utilisateur peut avoir plusieurs tokens actifs (multi-device). Le statut est une colonne enum (ACTIVE, REVOKED, CONSUMED) plutôt qu'un booléen pour distinguer les raisons d'invalidation.

**Alternatives considered**:
- Colonne unique sur table users — rejeté : ne supporte pas multi-device
- Table de blacklist (stocker uniquement les révoqués) — rejeté : ne permet pas le tracking complet ni la détection de réutilisation

## R4 — Impact sur l'expiration de l'access token

**Decision**: Changer l'expiration de l'access token de 24h à 15 minutes (FR-008)

**Rationale**: La spec l'exige explicitement. Le refresh token (30 jours) compense la durée courte. Le changement est fait via configuration (`app.jwt.access-expiration`).

**Impact frontend**: L'app sera dégradée (re-login toutes les 15 min) tant que l'intercepteur auto-refresh frontend n'est pas implémenté. Cet impact est accepté car le frontend est hors périmètre (feature séparée à suivre).

**Alternatives considered**:
- Garder 24h temporairement — rejeté : non conforme à la spec, le backend doit être livré complet

## R5 — Endpoints publics vs authentifiés

**Decision**: Les endpoints `/auth/refresh` et `/auth/logout` sont sous le pattern `/auth/**` déjà configuré en `permitAll()` dans SecurityConfig. Pas de modification nécessaire.

**Rationale**: Le JwtFilter actuel passe au filtre suivant si aucun header Authorization n'est présent. Les routes `/auth/**` sont déjà permises. L'identification de l'utilisateur se fait via le refresh token (lookup DB) et non via l'access token.

**Alternatives considered**:
- Routes séparées hors `/auth/` avec configuration explicite — rejeté : inutile, `/auth/**` couvre déjà le cas

## R6 — Codes d'erreur différenciés

**Decision**: Utiliser HTTP 401 avec un champ `error` dans le body JSON pour différencier les raisons de rejet

**Rationale**: 401 est le code HTTP standard pour authentification échouée. Le champ `error` dans le body permet au frontend de distinguer les cas (afficher un message approprié ou forcer re-login).

**Codes d'erreur**:
| Code erreur | HTTP Status | Signification |
|-------------|-------------|---------------|
| `TOKEN_EXPIRED` | 401 | Refresh token expiré (>30 jours) |
| `TOKEN_REVOKED` | 401 | Refresh token révoqué (logout) |
| `TOKEN_REUSE_DETECTED` | 401 | Token déjà consommé (vol potentiel) |
| `TOKEN_INVALID` | 401 | Token inconnu ou malformé |

**Alternatives considered**:
- Codes HTTP différents (403, 400) — rejeté : 401 est sémantiquement correct pour tous les cas d'échec d'authentification
- Codes numériques custom — rejeté : les constantes string sont plus lisibles
