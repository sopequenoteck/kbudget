ALTER TABLE transactions ADD COLUMN is_recurring BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE transactions ADD COLUMN frequency VARCHAR(20);
ALTER TABLE transactions ADD COLUMN next_occurrence DATE;
ALTER TABLE transactions ADD COLUMN recurring_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE transactions ADD COLUMN subscription_id UUID REFERENCES subscriptions(id);

CREATE INDEX idx_transactions_recurring_active
    ON transactions (user_id, next_occurrence)
    WHERE is_recurring = true AND recurring_active = true;

CREATE INDEX idx_transactions_subscription_id
    ON transactions (subscription_id)
    WHERE subscription_id IS NOT NULL;
