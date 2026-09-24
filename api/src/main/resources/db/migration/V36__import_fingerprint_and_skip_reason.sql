-- KKS-382 : une ligne deja importee est ecartee d'office au lieu de bloquer l'import.

-- Empreinte de la ligne de releve d'origine. Nulle pour les saisies manuelles
-- et les imports anterieurs, reconnus alors par date, montant et libelle.
ALTER TABLE transactions ADD COLUMN import_fingerprint VARCHAR(64);
CREATE INDEX idx_transactions_account_import_fingerprint
    ON transactions(account_id, import_fingerprint);

-- Raison d'un SKIPPED decide par l'import lui-meme (nulle si ignoree par l'utilisateur).
ALTER TABLE import_draft_lines ADD COLUMN skip_reason VARCHAR(30);

-- Sous-ensemble de skipped_count : les brouillons existants n'en ont aucune.
ALTER TABLE import_drafts ADD COLUMN already_imported_count INTEGER NOT NULL DEFAULT 0;
