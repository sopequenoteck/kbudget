CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    montant NUMERIC(19, 2) NOT NULL,
    libelle VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    categorie VARCHAR(255),
    note VARCHAR(255),
    user_id UUID NOT NULL,
    CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    montant NUMERIC(19, 2) NOT NULL,
    frequence VARCHAR(50) NOT NULL,
    date_debut DATE NOT NULL,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    user_id UUID NOT NULL,
    CONSTRAINT fk_subscriptions_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE debts (
    id UUID PRIMARY KEY,
    personne VARCHAR(255) NOT NULL,
    montant NUMERIC(19, 2) NOT NULL,
    sens VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    rembourse BOOLEAN NOT NULL DEFAULT FALSE,
    user_id UUID NOT NULL,
    CONSTRAINT fk_debts_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_transactions_user_id ON transactions (user_id);
CREATE INDEX idx_subscriptions_user_id ON subscriptions (user_id);
CREATE INDEX idx_debts_user_id ON debts (user_id);
