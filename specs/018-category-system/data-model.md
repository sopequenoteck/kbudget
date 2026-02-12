# Data Model: Système de Catégories

**Feature**: 018-category-system | **Date**: 2026-02-12

## Entités

### Category (MODIFIER — existant)

| Champ | Type | Contraintes | Notes |
|-------|------|-------------|-------|
| id | UUID | PK, auto-generated | Existant |
| nom | VARCHAR(30) | NOT NULL | **MODIFIÉ** : max 30 chars (était 255) |
| icone | VARCHAR(50) | NOT NULL | Emoji (ex: 🛒). Existant |
| couleur | VARCHAR(7) | NOT NULL, pattern `#[0-9A-Fa-f]{6}` | Hex color. Existant |
| is_system | BOOLEAN | NOT NULL, DEFAULT FALSE | **NOUVEAU** |
| updated_at | TIMESTAMP | auto | Existant |
| user_id | UUID | FK → users(id), NOT NULL | Existant |

**Contraintes** :
- UNIQUE (LOWER(nom), user_id) — **MODIFIÉ** : case-insensitive (remplace `(nom, user_id)`)
- Si `is_system = true` : suppression et modification interdites (logique service)

### Transaction (existant — pas de modification structurelle)

| Champ concerné | Type | Notes |
|----------------|------|-------|
| category_id | UUID | FK → categories(id), nullable, ON DELETE SET NULL — déjà en place |

### Subscription (existant — pas de modification structurelle)

| Champ concerné | Type | Notes |
|----------------|------|-------|
| category_id | UUID | FK → categories(id), nullable, ON DELETE SET NULL — déjà en place |

**Comportement** : Si `categoryId` est null à la création, le backend attribue automatiquement la catégorie système "Abonnement".

### Debt (existant — pas de modification structurelle)

| Champ concerné | Type | Notes |
|----------------|------|-------|
| category_id | UUID | FK → categories(id), nullable, ON DELETE SET NULL — déjà en place |

**Comportement** : Si `categoryId` est null à la création, le backend attribue automatiquement la catégorie système "Dette".

## Relations

```
User 1──* Category (isolation par utilisateur, y compris catégories système)
Category 1──* Transaction (optionnel, ON DELETE SET NULL)
Category 1──* Subscription (optionnel, ON DELETE SET NULL — défaut: système "Abonnement")
Category 1──* Debt (optionnel, ON DELETE SET NULL — défaut: système "Dette")
```

## Catégories système (seed)

| Nom | Icone | Couleur | is_system |
|-----|-------|---------|-----------|
| Abonnement | 🔄 | #6366f1 | true |
| Dette | 💰 | #ef4444 | true |

Créées :
- **Nouveaux utilisateurs** : dans `AuthService.register()` via `categoryService.seedSystemCategories(user)`
- **Utilisateurs existants** : via migration Flyway V5 (`INSERT ... SELECT id FROM users`)

## Migration V5

**Fichier** : `V5__add_is_system_and_seed.sql`

```sql
-- 1. Tronquer les noms > 30 caractères (données existantes)
UPDATE categories SET nom = LEFT(nom, 30) WHERE LENGTH(nom) > 30;

-- 2. Réduire la taille du nom à 30 caractères
ALTER TABLE categories ALTER COLUMN nom TYPE VARCHAR(30);

-- 3. Ajouter colonne is_system
ALTER TABLE categories ADD COLUMN is_system BOOLEAN DEFAULT FALSE NOT NULL;

-- 4. Unicité case-insensitive (remplace la contrainte existante)
ALTER TABLE categories DROP CONSTRAINT uq_categories_nom_user;
CREATE UNIQUE INDEX uq_categories_nom_user ON categories (LOWER(nom), user_id);

-- 5. Seed catégories système pour les utilisateurs existants
INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
SELECT gen_random_uuid(), 'Abonnement', '🔄', '#6366f1', true, id FROM users;

INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
SELECT gen_random_uuid(), 'Dette', '💰', '#ef4444', true, id FROM users;

-- 6. Backfill : attribuer catégorie système aux abonnements/dettes sans catégorie
UPDATE subscriptions SET category_id = (
    SELECT id FROM categories WHERE nom = 'Abonnement' AND is_system = true AND user_id = subscriptions.user_id
) WHERE category_id IS NULL;

UPDATE debts SET category_id = (
    SELECT id FROM categories WHERE nom = 'Dette' AND is_system = true AND user_id = debts.user_id
) WHERE category_id IS NULL;
```

## Palette de couleurs prédéfinie

12 couleurs harmonieuses pour l'attribution aléatoire :

| Nom | Hex |
|-----|-----|
| Red | #ef4444 |
| Orange | #f97316 |
| Amber | #f59e0b |
| Lime | #84cc16 |
| Emerald | #22c55e |
| Teal | #14b8a6 |
| Cyan | #06b6d4 |
| Blue | #3b82f6 |
| Indigo | #6366f1 |
| Violet | #8b5cf6 |
| Rose | #ec4899 |
| Stone | #78716c |

## Modèles TypeScript (frontend)

### Category (modifier)

```typescript
export interface Category {
  id: string;
  nom: string;
  icone: string;
  couleur: string;
  isSystem: boolean;  // NOUVEAU
}

export interface CategoryRequest {
  nom: string;
  icone: string;
  couleur: string;
}
```
