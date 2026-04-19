# Data Model — KKS-232 : Onboarding contrôlé

> Date : 2026-04-19
> Issue : KKS-232
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)

---

## Entités

### Invitation (nouvelle)

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | `BIGSERIAL` (Java `Long`) | PK | Identifiant interne. |
| `token` | `UUID` | UNIQUE NOT NULL, INDEX | Token public v4 transmis dans le lien. |
| `email` | `VARCHAR(255)` | NOT NULL | Email de l'invité, normalisé lowercase côté service. |
| `invited_by_user_id` | `UUID` | NOT NULL, FK → `users(id)` | Admin émetteur. |
| `expires_at` | `TIMESTAMP` | NOT NULL | `createdAt + 7 jours`. |
| `used_at` | `TIMESTAMP` | NULLABLE | Timestamp d'acceptation (=> `USED`). |
| `revoked_at` | `TIMESTAMP` | NULLABLE | Timestamp de révocation admin (=> `REVOKED`). |
| `created_at` | `TIMESTAMP` | NOT NULL DEFAULT NOW() | Posé par `@CreationTimestamp`. |

**Invariants** :
- `used_at` et `revoked_at` sont mutuellement exclusifs (un token utilisé ne peut pas être révoqué après, et inversement).
- `expires_at > created_at`.
- Le statut est dérivé (non stocké) :
  - `REVOKED` si `revoked_at IS NOT NULL`
  - sinon `USED` si `used_at IS NOT NULL`
  - sinon `EXPIRED` si `expires_at <= now`
  - sinon `ACTIVE`
- L'ordre de précédence REVOKED > USED > EXPIRED > ACTIVE évite les états ambigus.

### User (modifiée)

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | `UUID` | PK | Existant. |
| `email` | `VARCHAR(255)` | UNIQUE NOT NULL | Existant. |
| `password` | `VARCHAR` | NOT NULL | Existant. BCrypt. |
| `name` | `VARCHAR` | NULLABLE | Existant. |
| `created_at` | `TIMESTAMP` | NOT NULL | Existant. |
| **`disabled_at`** | `TIMESTAMP` | NULLABLE | **Ajout** — soft-disable. `NULL` = actif. |

**Invariants** :
- `disabled_at` est positionné via `PATCH /admin/users/:id/disable` et remis à `NULL` via `/enable`.
- Un user avec `disabled_at IS NOT NULL` ne peut plus s'authentifier (check dans `JwtFilter`).

## Relations

```
User (invitedBy)  --1:N-->  Invitation
```

| Relation | Type | Cardinalité | Contrainte |
|----------|------|-------------|------------|
| `invitation.invited_by_user_id` → `users.id` | FK | N:1 | `ON DELETE RESTRICT` (ne pas supprimer un user ayant émis des invitations). `ON UPDATE CASCADE`. |

## Contraintes globales

| # | Contrainte | Type | Entités concernées |
|---|-----------|------|-------------------|
| DC-001 | `invitation.token` est unique | Unicité | `invitation` |
| DC-002 | `invited_by_user_id` doit référencer un user existant et actif au moment de la création | FK + Business (vérif runtime) | `invitation` → `users` |
| DC-003 | Une invitation ne peut pas être à la fois `usedAt` et `revokedAt` | Business (vérif service) | `invitation` |
| DC-004 | `expires_at` doit valoir `created_at + 7 jours` à la création | Business (service) | `invitation` |
| DC-005 | Au moins un user avec `disabled_at IS NULL` dont l'email ∈ `ADMIN_EMAILS` doit rester à tout moment — enforcement dans `AdminUserService.disable` (garde-fou) | Business | `users` |
| DC-006 | Acceptation d'une invitation ne peut aboutir que si le status courant est `ACTIVE` | Business | `invitation` + `users` |

## Migrations

### V28 — Création de la table `invitation`

```sql
-- UP : V28__add_invitations.sql
CREATE TABLE invitation (
    id BIGSERIAL PRIMARY KEY,
    token UUID NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    invited_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    revoked_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invitation_token ON invitation(token);

-- DOWN (manuel si besoin)
-- DROP TABLE invitation;
```

### V29 — Ajout colonne `disabled_at` sur `users`

```sql
-- UP : V29__add_user_disabled_at.sql
ALTER TABLE users
    ADD COLUMN disabled_at TIMESTAMP NULL;

-- DOWN (manuel si besoin)
-- ALTER TABLE users DROP COLUMN disabled_at;
```

## Index

| Table | Colonnes | Type | Justification |
|-------|----------|------|---------------|
| `invitation` | `token` | B-tree (via UNIQUE) + index explicite | Lookup très fréquent par token public (`GET /auth/invitations/:token`, `POST /auth/accept-invite`). |
| `users` | `email` | B-tree (déjà UNIQUE existant) | Lookup dans `JwtFilter`, `AdminEmailResolver`, `AuthService.login`. Pas de changement. |
| `users` | `disabled_at` | Aucun | Cardinalité très faible (~16 lignes), pas d'intérêt. |
