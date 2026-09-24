-- KKS-383 : categorisation par l'historique et regles creees par la revue.

-- Origine de la categorie d'une ligne : RULE, HISTORY ou USER. Nulle sans categorie.
ALTER TABLE import_draft_lines ADD COLUMN category_source VARCHAR(20);

-- Les regles existantes ont toutes ete saisies par l'utilisateur.
ALTER TABLE category_rules ADD COLUMN origin VARCHAR(10) NOT NULL DEFAULT 'MANUAL';
