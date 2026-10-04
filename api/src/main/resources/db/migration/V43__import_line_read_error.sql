-- KKS-441 : une ligne illisible porte un code (INVALID_DATE, INVALID_AMOUNT,
-- UNREADABLE_LINE) et la valeur brute fautive, que les clients traduisent, au lieu
-- d'un texte francais ecrit par l'API. Additive : colonnes nullables, aucune donnee
-- existante modifiee ; status_message reste servi (en anglais pour les nouvelles lignes).
ALTER TABLE import_draft_lines ADD COLUMN read_error VARCHAR(30);
ALTER TABLE import_draft_lines ADD COLUMN read_error_value VARCHAR(500);
