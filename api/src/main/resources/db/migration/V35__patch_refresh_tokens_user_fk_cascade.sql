-- refresh_tokens.user_id dispose déjà de ON DELETE CASCADE depuis V6 (CONSTRAINT fk_refresh_tokens_user).
-- Migration de vérification documentaire — aucune modification DDL requise.
-- Confirmé lors de l'audit KKS-235 (RES-009).
SELECT 1;
