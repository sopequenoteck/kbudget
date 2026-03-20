-- Budgets par catégorie
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    montant DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
    frequence VARCHAR(20) NOT NULL,
    seuil_notification INTEGER NOT NULL DEFAULT 80,
    actif BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMP,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    UNIQUE(category_id, user_id)
);

CREATE INDEX idx_budgets_user_id ON budgets(user_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);

-- Snapshots historiques (pas de FK vers budgets)
CREATE TABLE budget_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    montant_budget DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    taux_change DECIMAL(20, 6),
    montant_depense DECIMAL(12, 2) NOT NULL,
    mois VARCHAR(7) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    UNIQUE(mois, category_id, user_id)
);

CREATE INDEX idx_snapshots_user_id ON budget_snapshots(user_id);
CREATE INDEX idx_snapshots_category_id ON budget_snapshots(category_id);
CREATE INDEX idx_snapshots_mois ON budget_snapshots(mois);
