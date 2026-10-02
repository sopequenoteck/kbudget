-- KKS-397 : notifications parametrees, texte construit par le client.

-- Nulle pour les notifications existantes (aucune migration de donnees) et pour
-- tout client qui n'exploite pas encore params : title/message restent servis
-- en anglais par le serveur, params porte les valeurs brutes a traduire.
ALTER TABLE notifications ADD COLUMN params JSONB;
