-- =============================================================
-- K-Budget — V24 (no-op)
-- =============================================================
-- Cette migration contenait initialement le seed des transactions
-- d'avril 2026. Le contenu a ete deplace dans R__dev_seed.sql pour
-- garantir l'idempotence sur reset de la DB dev : V24 est Versionnee
-- (one-shot), elle ne se rejoue pas apres un drop/recreate, ce qui
-- rendait les transactions d'avril perdues. R__dev_seed.sql est
-- Repeatable et tourne a chaque changement de checksum, apres que
-- user/comptes/categories existent.
--
-- Ne pas supprimer ce fichier : Flyway detecterait une migration
-- manquante. Le garder en no-op est la solution la plus safe.
-- =============================================================

SELECT 1;
