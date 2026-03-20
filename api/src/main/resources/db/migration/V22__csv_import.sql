-- Import profiles (custom user profiles only, pre-configured are in ImportProfileRegistry)
CREATE TABLE import_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    separator VARCHAR(5) NOT NULL DEFAULT ',',
    date_format VARCHAR(20) NOT NULL DEFAULT 'dd/MM/yyyy',
    date_column VARCHAR(50) NOT NULL,
    amount_column VARCHAR(50),
    debit_column VARCHAR(50),
    credit_column VARCHAR(50),
    label_column VARCHAR(50) NOT NULL,
    encoding VARCHAR(20) NOT NULL DEFAULT 'UTF-8',
    decimal_separator VARCHAR(1) NOT NULL DEFAULT '.',
    skip_header_lines INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Import drafts (one active per account)
CREATE TABLE import_drafts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    file_name VARCHAR(255),
    total_lines INTEGER NOT NULL DEFAULT 0,
    ready_count INTEGER NOT NULL DEFAULT 0,
    review_count INTEGER NOT NULL DEFAULT 0,
    duplicate_count INTEGER NOT NULL DEFAULT 0,
    skipped_count INTEGER NOT NULL DEFAULT 0,
    profile_id UUID,
    profile_source VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    expires_at TIMESTAMP NOT NULL
);

-- Import draft lines
CREATE TABLE import_draft_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    draft_id UUID NOT NULL REFERENCES import_drafts(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    raw_label VARCHAR(500) NOT NULL,
    clean_label VARCHAR(500) NOT NULL,
    amount DECIMAL(19, 2) NOT NULL,
    date DATE NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'READY',
    status_message VARCHAR(500),
    category_id UUID REFERENCES categories(id),
    duplicate_transaction_id UUID,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Category rules for auto-categorization
CREATE TABLE category_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern VARCHAR(200) NOT NULL,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, pattern)
);

-- Import history (finalized imports)
CREATE TABLE import_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    transaction_count INTEGER NOT NULL,
    file_name VARCHAR(255),
    imported_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_import_drafts_user_account ON import_drafts(user_id, account_id);
CREATE INDEX idx_import_draft_lines_draft ON import_draft_lines(draft_id);
CREATE INDEX idx_category_rules_user ON category_rules(user_id);
CREATE INDEX idx_import_history_user ON import_history(user_id);
CREATE INDEX idx_import_profiles_user ON import_profiles(user_id);
