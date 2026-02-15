-- ============================================================
-- V7 : Comptes bancaires (accounts)
-- ============================================================

-- 1. Créer la table accounts
CREATE TABLE accounts (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    nom             VARCHAR(50)     NOT NULL,
    type            VARCHAR(20)     NOT NULL,
    solde_initial   NUMERIC(19, 2)  NOT NULL DEFAULT 0.00,
    icone           VARCHAR(10)     NOT NULL,
    couleur         VARCHAR(7)      NOT NULL,
    is_default      BOOLEAN         NOT NULL DEFAULT FALSE,
    actif           BOOLEAN         NOT NULL DEFAULT TRUE,
    updated_at      TIMESTAMP,
    user_id         UUID            NOT NULL REFERENCES users(id)
);

-- 2. Index sur user_id
CREATE INDEX idx_accounts_user_id ON accounts(user_id);

-- 3. Unicité case-insensitive du nom par utilisateur (comptes actifs uniquement)
CREATE UNIQUE INDEX uq_accounts_nom_user ON accounts(LOWER(nom), user_id) WHERE actif = true;

-- 4. Créer le compte par défaut pour chaque utilisateur existant
INSERT INTO accounts (id, nom, type, solde_initial, icone, couleur, is_default, actif, user_id)
SELECT gen_random_uuid(), 'Compte Principal', 'COURANT', 0.00, '🏦', '#3b82f6', true, true, id
FROM users;

-- 5. Ajouter catégorie système "Virement" pour chaque utilisateur existant
INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
SELECT gen_random_uuid(), 'Virement', '🔄', '#8b5cf6', true, id FROM users;

-- 6. Ajouter account_id (nullable d'abord) sur transactions
ALTER TABLE transactions ADD COLUMN account_id UUID;

-- 7. Rattacher transactions existantes au compte par défaut
UPDATE transactions SET account_id = (
    SELECT id FROM accounts
    WHERE is_default = true AND user_id = transactions.user_id
);

-- 8. Contrainte NOT NULL sur account_id
ALTER TABLE transactions ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_account
    FOREIGN KEY (account_id) REFERENCES accounts(id);

-- 9. Ajouter transfer_id sur transactions
ALTER TABLE transactions ADD COLUMN transfer_id UUID;

-- 10. Ajouter account_id (nullable) sur subscriptions
ALTER TABLE subscriptions ADD COLUMN account_id UUID;
ALTER TABLE subscriptions ADD CONSTRAINT fk_subscriptions_account
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL;

-- 11. Index
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_transfer_id ON transactions(transfer_id) WHERE transfer_id IS NOT NULL;
CREATE INDEX idx_subscriptions_account_id ON subscriptions(account_id);
