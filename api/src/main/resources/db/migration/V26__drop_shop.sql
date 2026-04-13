-- ============================================================
-- V26 — Extraction module shop
-- Supprime les tables, colonnes et données liées au module shop
-- ============================================================

-- 1. Supprimer la FK product_id sur transactions (créée par V11)
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS fk_transaction_product;
DROP INDEX IF EXISTS idx_transactions_product_id;
ALTER TABLE transactions DROP COLUMN IF EXISTS product_id;

-- 2. Supprimer les colonnes shop sur user_preferences (créées par V11)
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS fk_preference_shop_account;
ALTER TABLE user_preferences DROP COLUMN IF EXISTS shop_account_id;
ALTER TABLE user_preferences DROP COLUMN IF EXISTS include_shop_in_balance;

-- 3. Supprimer les tables shop (ordre FK : products d'abord car pas référencée par d'autres tables)
DROP TABLE IF EXISTS products;

-- 4. Nettoyer les catégories système "Boutique" créées par V11 pour les users existants
DELETE FROM categories WHERE nom = 'Boutique' AND is_system = true;

-- 5. Nettoyer la valeur SHOP de enabled_features et nav_order dans user_preferences
--    Format stocké : CSV (ex: "SUBSCRIPTIONS,DEBTS,SHOP,BUDGETS")
UPDATE user_preferences
SET enabled_features = TRIM(BOTH ',' FROM
        REGEXP_REPLACE(
            REGEXP_REPLACE(enabled_features, '(^|,)SHOP(,|$)', ',', 'g'),
            '^,|,$', '', 'g'
        ))
WHERE enabled_features LIKE '%SHOP%';

UPDATE user_preferences
SET nav_order = TRIM(BOTH ',' FROM
        REGEXP_REPLACE(
            REGEXP_REPLACE(nav_order, '(^|,)SHOP(,|$)', ',', 'g'),
            '^,|,$', '', 'g'
        ))
WHERE nav_order LIKE '%SHOP%';
