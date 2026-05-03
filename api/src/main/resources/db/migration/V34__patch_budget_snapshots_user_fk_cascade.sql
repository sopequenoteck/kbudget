-- Recrée la FK budget_snapshots.user_id avec ON DELETE CASCADE
-- Nom généré par PostgreSQL lors de V17 : budget_snapshots_user_id_fkey
ALTER TABLE budget_snapshots DROP CONSTRAINT IF EXISTS budget_snapshots_user_id_fkey;

ALTER TABLE budget_snapshots
    ADD CONSTRAINT fk_budget_snapshots_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;
