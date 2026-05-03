# Data Model: 080-debt-enhancements

## Entity Changes

### Debt (enrichie)

| Champ | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| id | UUID | Non | auto | PK |
| personne | VARCHAR(255) | Non | — | Nom du créancier/débiteur |
| montant | DECIMAL | Non | — | Montant initial (positif) |
| sens | ENUM(EMPRUNT, PRET) | Non | — | Direction de la dette |
| date | DATE | Non | — | Date de création |
| currency | ENUM(Currency) | Non | EUR | Devise (forcée par le compte si associé) |
| rembourse | BOOLEAN | Non | false | Auto-true quand remainingAmount = 0 |
| due_date | DATE | Oui | null | Date d'échéance optionnelle |
| category_id | UUID | Oui | null | FK → categories |
| **account_id** | **UUID** | **Oui** | **null** | **FK → accounts, ON DELETE SET NULL** (NOUVEAU V18) |
| **include_in_balance** | **BOOLEAN** | **Non** | **false** | **Toggle patrimoine** (NOUVEAU V18) |
| **reminder_date** | **DATE** | **Oui** | **null** | **Date rappel** (NOUVEAU V18) |
| **reminder_time** | **TIME** | **Oui** | **null** | **Heure rappel** (NOUVEAU V18) |
| updated_at | TIMESTAMP | Oui | auto | |
| user_id | UUID | Non | — | FK → users |

### Transaction (enrichie)

| Champ | Type | Nullable | Notes |
|-------|------|----------|-------|
| **debt_id** | **UUID** | **Oui** | **FK → debts, ON DELETE SET NULL** (NOUVEAU V18) |

Tous les autres champs existants inchangés.

### Notification (existante, pas de changement de schéma)

Nouveau type utilisé : `DEBT_REMINDER` (enum NotificationType).

## Relations

```
User 1──* Debt
User 1──* Account
User 1──* Transaction
User 1──* Notification

Debt *──1 Account (optionnel, ON DELETE SET NULL)
Debt *──1 Category (optionnel)
Debt 1──* Transaction (via debt_id, ON DELETE SET NULL)

Transaction *──1 Account (existant)
Transaction *──1 Debt (optionnel, nouveau)
```

## Calculs dérivés (non persistés)

| Valeur | Calcul | Utilisation |
|--------|--------|-------------|
| `montantRestant` | `dette.montant - SUM(transactions.montant WHERE debt_id = dette.id)` | DebtResponse, UI progress bar |
| `progressPercent` | `((montant - montantRestant) / montant) * 100` | UI (Angular computed, Flutter widget) |
| `totalBalance` | `SUM(comptes.solde) + SUM(dettes éligibles par devise)` | TotalBalanceResponse |

## Règles métier

1. **Forçage devise** : Si `account_id` non null → `currency = account.currency` (ignoré du request)
2. **includeInBalance** : Si `account_id` non null → toujours false (inclusion via le compte)
3. **Remboursement** : Crée une Transaction de type DEPENSE (EMPRUNT) ou RECETTE (PRET)
4. **Auto-remboursé** : `rembourse = true` quand `montantRestant <= 0`
5. **Rappels XOR** : `reminderDate` et `reminderTime` doivent être fournis ensemble ou pas du tout
6. **Snooze** : Requiert un rappel existant (reject sinon)
7. **Conversion** : Association tardive à un compte avec devise différente → conversion via taux de change
8. **Suppression compte** : `account_id` mis à null (ON DELETE SET NULL)
9. **Suppression dette** : Transactions liées détachées (`debt_id = null`) et annotées

## Migration Flyway V18

```sql
-- Debt enhancements
ALTER TABLE debts ADD COLUMN account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;
ALTER TABLE debts ADD COLUMN include_in_balance BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE debts ADD COLUMN reminder_date DATE;
ALTER TABLE debts ADD COLUMN reminder_time TIME;
CREATE INDEX idx_debts_account_id ON debts(account_id);
CREATE INDEX idx_debts_reminder ON debts(reminder_date, reminder_time) WHERE reminder_date IS NOT NULL;

-- Repayment tracking
ALTER TABLE transactions ADD COLUMN debt_id UUID REFERENCES debts(id) ON DELETE SET NULL;
CREATE INDEX idx_transactions_debt_id ON transactions(debt_id);
```

## Index

| Index | Table | Colonnes | Condition |
|-------|-------|----------|-----------|
| `idx_debts_account_id` | debts | account_id | — |
| `idx_debts_reminder` | debts | reminder_date, reminder_time | WHERE reminder_date IS NOT NULL |
| `idx_transactions_debt_id` | transactions | debt_id | — |
