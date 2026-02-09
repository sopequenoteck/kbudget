-- Table categories
CREATE TABLE categories (
    id UUID PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    icone VARCHAR(50) NOT NULL,
    couleur VARCHAR(7) NOT NULL,
    updated_at TIMESTAMP,
    user_id UUID NOT NULL,
    CONSTRAINT fk_categories_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uq_categories_nom_user UNIQUE (nom, user_id)
);

CREATE INDEX idx_categories_user_id ON categories (user_id);

-- Transactions : remplacer categorie (String) par category_id (FK)
ALTER TABLE transactions DROP COLUMN categorie;
ALTER TABLE transactions ADD COLUMN category_id UUID;
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL;
CREATE INDEX idx_transactions_category_id ON transactions (category_id);

-- Subscriptions : ajouter category_id (FK)
ALTER TABLE subscriptions ADD COLUMN category_id UUID;
ALTER TABLE subscriptions ADD CONSTRAINT fk_subscriptions_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL;
CREATE INDEX idx_subscriptions_category_id ON subscriptions (category_id);

-- Debts : ajouter category_id (FK)
ALTER TABLE debts ADD COLUMN category_id UUID;
ALTER TABLE debts ADD CONSTRAINT fk_debts_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL;
CREATE INDEX idx_debts_category_id ON debts (category_id);
