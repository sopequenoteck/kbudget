-- Add missing updated_at column to import_drafts (was added to V22 after initial apply)
ALTER TABLE import_drafts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
