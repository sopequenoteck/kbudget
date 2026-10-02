-- KKS-385 : rapprocher une ligne de releve d'une saisie manuelle existante au lieu
-- de creer une transaction en double. Additive : colonnes nullables (sauf un
-- compteur avec defaut), aucune donnee existante modifiee, aucun comportement
-- change tant qu'un releve ne renseigne pas ces champs. Pas de cle etrangere,
-- comme duplicate_transaction_id : supprimer une transaction ne doit pas etre
-- bloque par un brouillon en attente, la confirmation reverifie la reference.

-- Date d'achat lue dans le libelle brut (paiement carte), nulle si le profil n'en declare pas.
-- La colonne date reste la date comptable.
ALTER TABLE import_draft_lines ADD COLUMN purchase_date DATE;

-- Transaction existante a laquelle la ligne est rapprochee : elle recoit l'empreinte
-- a la confirmation et aucune transaction n'est creee.
ALTER TABLE import_draft_lines ADD COLUMN matched_transaction_id UUID;

-- Plusieurs candidats : identifiants separes par des virgules, a trancher dans la revue.
-- Jamais interroge par candidat, lu et ecrit avec la ligne : une colonne texte evite
-- une table de jointure et un chargement par ligne.
ALTER TABLE import_draft_lines ADD COLUMN match_candidate_ids TEXT;

-- Abonnement auquel la transaction creee a la confirmation sera rattachee.
ALTER TABLE import_draft_lines ADD COLUMN subscription_id UUID;

-- Sous-ensemble de ready_count : les brouillons existants n'en ont aucune.
ALTER TABLE import_drafts ADD COLUMN matched_count INTEGER NOT NULL DEFAULT 0;

-- Cle commercant (MerchantKey) du libelle de releve de l'abonnement, apprise quand
-- une ligne est rapprochee d'un de ses paiements.
ALTER TABLE subscriptions ADD COLUMN statement_merchant_key VARCHAR(500);
