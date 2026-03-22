# Data Model: Refresh Token JWT Backend

**Feature**: 023-jwt-refresh-token | **Date**: 2026-02-13

## Entités

### RefreshToken (nouvelle)

| Champ | Type Java | Type SQL | Contraintes | Description |
|-------|-----------|----------|-------------|-------------|
| id | UUID | UUID | PK, auto-generated | Identifiant unique |
| token | String | VARCHAR(64) | NOT NULL, UNIQUE, INDEX | Valeur opaque (Base64url, 43 chars) |
| status | TokenStatus | VARCHAR(20) | NOT NULL, DEFAULT 'ACTIVE' | Statut du token |
| user | User | UUID FK → users(id) | NOT NULL, ON DELETE CASCADE | Utilisateur propriétaire |
| createdAt | LocalDateTime | TIMESTAMP | NOT NULL, DEFAULT NOW() | Date de création |
| expiresAt | LocalDateTime | TIMESTAMP | NOT NULL | Date d'expiration (createdAt + 30 jours) |

**Annotations JPA** :
- `@Entity`, `@Table(name = "refresh_tokens")`
- `@ManyToOne(fetch = FetchType.LAZY)`, `@JoinColumn(name = "user_id")`
- `@Enumerated(EnumType.STRING)` pour status
- Lombok : `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`

**Index** :
- `uq_refresh_tokens_token` (UNIQUE) sur `token`
- `idx_refresh_tokens_user_id` sur `user_id`
- `idx_refresh_tokens_status` sur `status`

### TokenStatus (nouvel enum)

| Valeur | Description | Transition depuis |
|--------|-------------|-------------------|
| ACTIVE | Token valide, utilisable | Création |
| CONSUMED | Token utilisé pour un refresh (remplacé) | ACTIVE |
| REVOKED | Token invalidé par logout ou détection de vol | ACTIVE |

**Note** : Le statut `expiré` n'est pas dans l'enum — il est déterminé dynamiquement en comparant `expiresAt` avec `now()`.

### User (existant, non modifié)

Aucune modification sur l'entité User. La relation est portée par RefreshToken (`@ManyToOne`).

## Diagramme de transitions d'état

```
                   ┌──────────┐
    Création ────▶ │  ACTIVE  │
                   └────┬─────┘
                        │
              ┌─────────┼──────────┐
              ▼                    ▼
       ┌────────────┐      ┌───────────┐
       │  CONSUMED  │      │  REVOKED  │
       └────────────┘      └───────────┘
       (rotation OK)       (logout ou
                            vol détecté)
```

## Migration Flyway

**Fichier** : `V6__add_refresh_tokens.sql`

```sql
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY,
    token VARCHAR(64) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    user_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX uq_refresh_tokens_token ON refresh_tokens (token);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_status ON refresh_tokens (status);
```

## Requêtes clés (RefreshTokenRepository)

| Méthode | Query | Usage |
|---------|-------|-------|
| `findByToken(String token)` | Lookup par valeur opaque | Refresh, logout |
| `findByUserAndStatus(User user, TokenStatus status)` | Tous les tokens actifs d'un user | Révocation en masse (vol détecté) |
| `deleteByExpiresAtBefore(LocalDateTime date)` | Nettoyage des tokens expirés | Maintenance |
