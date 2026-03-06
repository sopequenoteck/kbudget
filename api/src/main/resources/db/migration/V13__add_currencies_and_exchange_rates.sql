-- Ajout colonne currencies a user_preferences
ALTER TABLE user_preferences ADD COLUMN currencies VARCHAR(100) NOT NULL DEFAULT 'EUR';

-- Initialiser depuis users.default_currency
UPDATE user_preferences up
SET currencies = u.default_currency
FROM users u
WHERE up.user_id = u.id;

-- Table exchange_rates
CREATE TABLE exchange_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    base_currency VARCHAR(3) NOT NULL,
    target_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(20,6) NOT NULL CHECK (rate > 0),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, base_currency, target_currency),
    CHECK (base_currency != target_currency)
);

CREATE INDEX idx_exchange_rates_user ON exchange_rates(user_id);
