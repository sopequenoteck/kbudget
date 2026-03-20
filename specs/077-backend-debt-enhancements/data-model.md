# Data Model: Backend Debt Enhancements

**Feature**: 077-backend-debt-enhancements | **Date**: 2026-03-09

## Entités modifiées

### Debt (enrichie)

| Champ | Type | Nullable | Default | Nouveau | Notes |
|-------|------|----------|---------|---------|-------|
| id | UUID | NO | gen_random_uuid() | | PK |
| personne | String(255) | NO | | | |
| montant | BigDecimal(12,2) | NO | | | Montant initial |
| sens | DebtType | NO | | | EMPRUNT / PRET |
| date | LocalDate | NO | | | |
| dueDate | LocalDate | YES | NULL | | Ajouté en V16 |
| currency | Currency | NO | EUR | | Déjà existant |
| rembourse | Boolean | NO | false | | Calculé dynamiquement (FR-023) |
| **account** | **Account (FK)** | **YES** | **NULL** | **OUI** | **ManyToOne lazy, FK → accounts(id)** |
| **includeInBalance** | **Boolean** | **NO** | **false** | **OUI** | **Toggle patrimoine (dettes sans compte uniquement)** |
| **reminderDate** | **LocalDate** | **YES** | **NULL** | **OUI** | **Date du rappel** |
| **reminderTime** | **LocalTime** | **YES** | **NULL** | **OUI** | **Heure du rappel** |
| category | Category (FK) | YES | | | |
| user | User (FK) | NO | | | |
| updatedAt | LocalDateTime | YES | | | @UpdateTimestamp |

**Contraintes**:
- Si `account != null` → `currency` DOIT être forcé à `account.currency`
- `includeInBalance` pertinent uniquement si `account == null`
- `reminderDate` et `reminderTime` doivent être tous deux renseignés ou tous deux null

### Transaction (enrichie)

| Champ | Type | Nullable | Default | Nouveau | Notes |
|-------|------|----------|---------|---------|-------|
| ... | ... | ... | ... | | Champs existants inchangés |
| **debt** | **Debt (FK)** | **YES** | **NULL** | **OUI** | **ManyToOne lazy, FK → debts(id) ON DELETE SET NULL** |

**Relations**:
- `debt` : lien vers la dette remboursée. Plusieurs transactions peuvent pointer vers la même dette (remboursements partiels).

## Nouveaux DTOs

### DebtRepayRequest

| Champ | Type | Obligatoire | Validation | Notes |
|-------|------|-------------|------------|-------|
| accountId | UUID | OUI | @NotNull | Compte source du remboursement |
| amount | BigDecimal | NON | @Positive (si fourni) | Défaut = montant restant |

### DebtPaymentResponse

| Champ | Type | Notes |
|-------|------|-------|
| id | UUID | ID de la transaction de remboursement |
| amount | BigDecimal | Montant remboursé |
| date | LocalDate | Date du remboursement |
| accountName | String | Nom du compte source |

### DebtSnoozeRequest

| Champ | Type | Obligatoire | Validation |
|-------|------|-------------|------------|
| reminderDate | LocalDate | OUI | @NotNull, @FutureOrPresent |
| reminderTime | LocalTime | OUI | @NotNull |

### TotalBalanceResponse

| Champ | Type | Notes |
|-------|------|-------|
| balances | List\<CurrencyBalance\> | Patrimoine groupé par devise |

### CurrencyBalance

| Champ | Type | Notes |
|-------|------|-------|
| currency | Currency | Devise |
| amount | BigDecimal | Solde total dans cette devise |

## DTOs modifiés

### DebtRequest (enrichi)

| Champ | Modification |
|-------|-------------|
| accountId | **AJOUTÉ** — UUID nullable, compte associé |
| includeInBalance | **AJOUTÉ** — Boolean nullable, default false |
| reminderDate | **AJOUTÉ** — LocalDate nullable |
| reminderTime | **AJOUTÉ** — LocalTime nullable |

### DebtResponse (enrichi)

| Champ | Modification |
|-------|-------------|
| account | **AJOUTÉ** — AccountSummary nullable (id, nom, icone, couleur, currency) |
| includeInBalance | **AJOUTÉ** — Boolean |
| reminderDate | **AJOUTÉ** — LocalDate nullable |
| reminderTime | **AJOUTÉ** — LocalTime nullable |
| montantRestant | **AJOUTÉ** — BigDecimal (calculé dynamiquement) |
| dueDate | **AJOUTÉ** — LocalDate nullable (existant mais pas exposé) |

### TransactionResponse (enrichi)

| Champ | Modification |
|-------|-------------|
| debtId | **AJOUTÉ** — UUID nullable (ID de la dette liée) |

## Enums modifiés

### NotificationType

| Valeur | Modification |
|--------|-------------|
| DEBT_REMINDER | **AJOUTÉ** — Rappel personnalisé configurable |

## Migration Flyway V18

```sql
-- Debt enhancements
ALTER TABLE debts ADD COLUMN account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;
ALTER TABLE debts ADD COLUMN include_in_balance BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE debts ADD COLUMN reminder_date DATE;
ALTER TABLE debts ADD COLUMN reminder_time TIME;

CREATE INDEX idx_debts_account_id ON debts(account_id);
CREATE INDEX idx_debts_reminder ON debts(reminder_date, reminder_time) WHERE reminder_date IS NOT NULL;

-- Transaction → Debt link
ALTER TABLE transactions ADD COLUMN debt_id UUID REFERENCES debts(id) ON DELETE SET NULL;

CREATE INDEX idx_transactions_debt_id ON transactions(debt_id);

-- Backfill: devise principale utilisateur pour les dettes existantes
-- currencies est stocké en VARCHAR CSV (ex: "EUR,USD") via CurrencyListConverter
UPDATE debts SET currency = (
    SELECT COALESCE(SPLIT_PART(up.currencies, ',', 1), 'EUR')
    FROM user_preferences up WHERE up.user_id = debts.user_id
) WHERE currency = 'EUR';
```
