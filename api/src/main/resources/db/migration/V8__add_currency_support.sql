-- V8: Multi-currency support
-- Adds currency fields to accounts, debts, subscriptions and default_currency to users.
-- All existing data migrated to EUR (FR-012).

ALTER TABLE accounts ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR';

ALTER TABLE debts ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR';

ALTER TABLE subscriptions ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR';

ALTER TABLE users ADD COLUMN default_currency VARCHAR(3) NOT NULL DEFAULT 'EUR';
