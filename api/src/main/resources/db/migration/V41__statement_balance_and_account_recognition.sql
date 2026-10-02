-- KKS-384 : le solde du releve fixe le solde d'ouverture, controle l'import et
-- permet de reconnaitre le compte. Additive : colonnes nullables, aucune donnee
-- existante modifiee, aucun comportement change tant qu'un releve ne les renseigne pas.

-- Association releve -> compte : cle du profil ("REGISTRY:<bankCode>" ou
-- "CUSTOM:<id du profil>") et 4 derniers chiffres du numero de compte. Le numero
-- complet n'est jamais stocke, ni en clair ni en empreinte.
ALTER TABLE accounts ADD COLUMN statement_profile_key VARCHAR(64);
ALTER TABLE accounts ADD COLUMN statement_account_suffix VARCHAR(4);

-- Ce que l'en-tete du releve a donne a l'upload, relu a la confirmation.
ALTER TABLE import_drafts ADD COLUMN statement_profile_key VARCHAR(64);
ALTER TABLE import_drafts ADD COLUMN statement_account_suffix VARCHAR(4);
ALTER TABLE import_drafts ADD COLUMN statement_balance NUMERIC(19, 2);
ALTER TABLE import_drafts ADD COLUMN statement_balance_date DATE;
