-- Debt enhancements: account association, balance inclusion, reminders
ALTER TABLE debts ADD COLUMN account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;
ALTER TABLE debts ADD COLUMN include_in_balance BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE debts ADD COLUMN reminder_date DATE;
ALTER TABLE debts ADD COLUMN reminder_time TIME;

CREATE INDEX idx_debts_account_id ON debts(account_id);
CREATE INDEX idx_debts_reminder ON debts(reminder_date, reminder_time) WHERE reminder_date IS NOT NULL;

-- Transaction → Debt link (repayments)
ALTER TABLE transactions ADD COLUMN debt_id UUID REFERENCES debts(id) ON DELETE SET NULL;

CREATE INDEX idx_transactions_debt_id ON transactions(debt_id);
