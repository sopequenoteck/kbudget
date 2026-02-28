-- 1. Categorie systeme "Boutique" pour chaque utilisateur existant
INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
SELECT gen_random_uuid(), 'Boutique', '🛍️', '#f59e0b', true, id
FROM users;

-- 2. FK product_id sur transactions
ALTER TABLE transactions ADD COLUMN product_id UUID;
ALTER TABLE transactions ADD CONSTRAINT fk_transaction_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL;
CREATE INDEX idx_transactions_product_id ON transactions(product_id);

-- 3. Preferences boutique sur user_preferences
ALTER TABLE user_preferences ADD COLUMN shop_account_id UUID;
ALTER TABLE user_preferences ADD COLUMN include_shop_in_balance BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE user_preferences ADD CONSTRAINT fk_preference_shop_account
    FOREIGN KEY (shop_account_id) REFERENCES accounts(id) ON DELETE SET NULL;
