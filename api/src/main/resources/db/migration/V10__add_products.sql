CREATE TABLE products (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom          VARCHAR(100)   NOT NULL,
    description  VARCHAR(500),
    icone        VARCHAR(10),
    image_url    VARCHAR(500),
    prix_achat   NUMERIC(12, 2) NOT NULL,
    prix_vente   NUMERIC(12, 2) NOT NULL,
    stock        INTEGER        NOT NULL DEFAULT 0,
    total_vendu  INTEGER        NOT NULL DEFAULT 0,
    actif        BOOLEAN        NOT NULL DEFAULT true,
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP               DEFAULT CURRENT_TIMESTAMP,
    user_id      UUID           NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_products_user_id ON products(user_id);
CREATE INDEX idx_products_user_actif ON products(user_id, actif);
