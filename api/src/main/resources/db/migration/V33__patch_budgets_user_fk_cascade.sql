-- Recrée la FK budgets.user_id avec ON DELETE CASCADE
-- Nom généré par PostgreSQL lors de V17 : budgets_user_id_fkey
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_user_id_fkey;

ALTER TABLE budgets
    ADD CONSTRAINT fk_budgets_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;
