ALTER TABLE accounts ADD COLUMN bank_code VARCHAR(20) NOT NULL DEFAULT 'OTHER';
ALTER TABLE accounts ADD COLUMN bank_custom_name VARCHAR(100);
ALTER TABLE accounts ADD COLUMN bank_custom_logo TEXT;
