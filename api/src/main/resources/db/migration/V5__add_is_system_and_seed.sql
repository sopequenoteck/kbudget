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
