# Data Model: 056-backend-product-crud

**Date**: 2026-02-27

## Entities

### Product

| Champ | Type Java | Type SQL | Contraintes | Notes |
|-------|-----------|----------|-------------|-------|
| id | UUID | UUID | PK, DEFAULT gen_random_uuid() | Auto-généré |
| nom | String | VARCHAR(100) | NOT NULL | @NotBlank @Size(max=100) |
| description | String | VARCHAR(500) | NULLABLE | @Size(max=500) |
| icone | String | VARCHAR(10) | NULLABLE | Emoji, optionnel |
| imageUrl | String | VARCHAR(500) | NULLABLE | @Size(max=500) |
| prixAchat | BigDecimal | NUMERIC(12,2) | NOT NULL | @NotNull @Positive |
| prixVente | BigDecimal | NUMERIC(12,2) | NOT NULL | @NotNull @Positive |
| stock | Integer | INTEGER | NOT NULL, DEFAULT 0 | @NotNull @Min(0) |
| totalVendu | Integer | INTEGER | NOT NULL, DEFAULT 0 | Non modifiable par l'utilisateur |
| actif | Boolean | BOOLEAN | NOT NULL, DEFAULT true | Toggle de visibilité |
| createdAt | LocalDateTime | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Non modifiable |
| updatedAt | LocalDateTime | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | @UpdateTimestamp |
| user | User (FK) | UUID | NOT NULL, FK → users(id) ON DELETE CASCADE | Isolation données |

### Relationships

```
User (1) ──────< Product (*)
  │                  │
  │                  ├── id (UUID, PK)
  │                  ├── nom (VARCHAR 100, NOT NULL)
  │                  ├── description (VARCHAR 500, NULLABLE)
  │                  ├── icone (VARCHAR 10, NULLABLE)
  │                  ├── image_url (VARCHAR 500, NULLABLE)
  │                  ├── prix_achat (NUMERIC 12,2, NOT NULL)
  │                  ├── prix_vente (NUMERIC 12,2, NOT NULL)
  │                  ├── stock (INTEGER, NOT NULL, DEFAULT 0)
  │                  ├── total_vendu (INTEGER, NOT NULL, DEFAULT 0)
  │                  ├── actif (BOOLEAN, NOT NULL, DEFAULT true)
  │                  ├── created_at (TIMESTAMP, NOT NULL)
  │                  ├── updated_at (TIMESTAMP)
  │                  └── user_id (UUID, FK → users)
  │
  └── id (UUID, PK)
```

### Identity & Uniqueness

- **PK**: `id` (UUID, auto-generated)
- **Pas de contrainte d'unicité** sur `nom` (doublons autorisés)
- **FK**: `user_id` → `users(id)` avec `ON DELETE CASCADE`

### State Transitions

```
[Création] ──→ actif=true, totalVendu=0
                │
                ├── PUT (actif=false) ──→ Inactif (invisible dans la liste, accessible par ID)
                │                            │
                │                            └── PUT (actif=true) ──→ Actif (visible dans la liste)
                │
                └── DELETE ──→ [Supprimé physiquement] (irréversible)
```

### Validation Rules

| Champ | Règle | Annotation Bean Validation |
|-------|-------|---------------------------|
| nom | Non vide, max 100 chars | `@NotBlank @Size(max = 100)` |
| description | Optionnel, max 500 chars | `@Size(max = 500)` |
| icone | Optionnel | - |
| imageUrl | Optionnel, max 500 chars | `@Size(max = 500)` |
| prixAchat | Positif strict | `@NotNull @Positive` |
| prixVente | Positif strict | `@NotNull @Positive` |
| stock | >= 0 | `@NotNull @Min(0)` |
| actif | Requis dans PUT | `@NotNull` |

## Flyway Migration

**Version**: V10__add_products.sql

```sql
CREATE TABLE products (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom          VARCHAR(100)   NOT NULL,
    description  VARCHAR(500),
    icone        VARCHAR(10),
    image_url    VARCHAR(500),
    prix_achat   NUMERIC(12, 2) NOT NULL,
    prix_vente   NUMERIC(12, 2) NOT NULL,
    stock        INTEGER        NOT NULL DEFAULT 0,
    total_vendu  INTEGER        NOT NULL DEFAULT 0,
    actif        BOOLEAN        NOT NULL DEFAULT true,
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP               DEFAULT CURRENT_TIMESTAMP,
    user_id      UUID           NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_products_user_id ON products(user_id);
CREATE INDEX idx_products_user_actif ON products(user_id, actif);
```
