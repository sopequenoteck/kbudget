-- ============================================================
-- V9: Add user_preferences table for feature toggles
-- ============================================================

CREATE TABLE user_preferences (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    enabled_features VARCHAR(255) NOT NULL DEFAULT 'SUBSCRIPTIONS,DEBTS,SHOP',
    nav_order        VARCHAR(255) NOT NULL DEFAULT 'SUBSCRIPTIONS,DEBTS,SHOP',
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialisation pour les utilisateurs existants
INSERT INTO user_preferences (id, user_id, enabled_features, nav_order)
SELECT gen_random_uuid(), id, 'SUBSCRIPTIONS,DEBTS,SHOP', 'SUBSCRIPTIONS,DEBTS,SHOP'
FROM users;
