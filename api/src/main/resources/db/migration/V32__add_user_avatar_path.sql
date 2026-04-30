ALTER TABLE users ADD COLUMN avatar_path VARCHAR(512) NULL;

COMMENT ON COLUMN users.avatar_path IS 'Chemin relatif vers l''avatar redimensionné (256x256 JPEG) stocké sur disque local. NULL si aucun avatar uploadé.';
