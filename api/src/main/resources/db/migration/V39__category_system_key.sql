-- KKS-395 : cle stable des categories systeme, traduite par le client.

-- Nulle pour une categorie utilisateur ; renseignee uniquement pour is_system = true.
ALTER TABLE categories ADD COLUMN system_key VARCHAR(20);

-- Backfill depuis le nom francais actuel. uq_categories_nom_user (LOWER(nom), user_id)
-- garantit au plus une categorie par nom et par utilisateur, systeme ou non : aucun
-- doublon de system_key ne peut donc apparaitre pour un meme utilisateur.
UPDATE categories SET system_key = 'SUBSCRIPTION' WHERE is_system = true AND LOWER(nom) = 'abonnement';
UPDATE categories SET system_key = 'DEBT' WHERE is_system = true AND LOWER(nom) = 'dette';
UPDATE categories SET system_key = 'TRANSFER' WHERE is_system = true AND LOWER(nom) = 'virement';
UPDATE categories SET system_key = 'ADJUSTMENT' WHERE is_system = true AND LOWER(nom) = 'ajustement';

CREATE UNIQUE INDEX uq_categories_system_key_user ON categories (user_id, system_key) WHERE system_key IS NOT NULL;
