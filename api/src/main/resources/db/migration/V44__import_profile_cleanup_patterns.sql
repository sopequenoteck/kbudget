-- KKS-442 : un profil d'import personnalise porte ses motifs de nettoyage du libelle
-- (tableau JSON de regex, ordre significatif), comme le profil du registre. Additive :
-- colonne nullable sans defaut, aucune donnee existante modifiee ; NULL se lit comme
-- une liste vide.
ALTER TABLE import_profiles ADD COLUMN cleanup_patterns JSONB;
