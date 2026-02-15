# Data Model: Comptes Bancaires

**Branch**: `026-bank-accounts` | **Date**: 2026-02-15

## Nouvelle entité : Account

```
Table: accounts
─────────────────────────────────────────────────────
id              UUID            PK, auto-generated
nom             VARCHAR(50)     NOT NULL
type            VARCHAR(20)     NOT NULL (COURANT, EPARGNE, ESPECES)
solde_initial   NUMERIC(19,2)   NOT NULL DEFAULT 0.00
icone           VARCHAR(10)     NOT NULL
couleur         VARCHAR(7)      NOT NULL
is_default      BOOLEAN         NOT NULL DEFAULT FALSE
actif           BOOLEAN         NOT NULL DEFAULT TRUE
updated_at      TIMESTAMP       auto-updated
user_id         UUID            FK → users, NOT NULL
─────────────────────────────────────────────────────

Contraintes:
  - UNIQUE INDEX (LOWER(nom), user_id) WHERE actif = true
  - INDEX (user_id)
  - FK user_id REFERENCES users(id)
```

### Entité JPA

```java
@Entity
@Table(name = "accounts")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Account {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 50)
    private String nom;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AccountType type;

    @Column(name = "solde_initial", nullable = false)
    private BigDecimal soldeInitial; // Figé après création (ignoré en PUT)

    @Column(nullable = false, length = 10)
    private String icone;

    @Column(nullable = false, length = 7)
    private String couleur;

    @Column(name = "is_default", nullable = false)
    @Builder.Default
    private Boolean isDefault = false;

    @Column(nullable = false)
    @Builder.Default
    private Boolean actif = true;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
```

## Nouvel enum : AccountType

```java
package fr.kksdev.budget.api.enums;

public enum AccountType {
    COURANT,
    EPARGNE,
    ESPECES
}
```

## Modification : Transaction (ajout de 2 champs)

```
Champs ajoutés à la table transactions:
─────────────────────────────────────────────────────
account_id      UUID            FK → accounts, NOT NULL
transfer_id     UUID            NULLABLE (null = transaction normale)
─────────────────────────────────────────────────────

Contraintes:
  - FK account_id REFERENCES accounts(id)
  - INDEX (account_id)
  - INDEX (transfer_id) WHERE transfer_id IS NOT NULL
```

### Modifications entité JPA Transaction

```java
// Ajouts au modèle Transaction existant :

@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "account_id", nullable = false)
private Account account;

@Column(name = "transfer_id")
private UUID transferId;
```

## Modification : Subscription (ajout de 1 champ)

```
Champ ajouté à la table subscriptions:
─────────────────────────────────────────────────────
account_id      UUID            FK → accounts, NULLABLE
─────────────────────────────────────────────────────

Contraintes:
  - FK account_id REFERENCES accounts(id) ON DELETE SET NULL
  - INDEX (account_id)
```

### Modification entité JPA Subscription

```java
// Ajout au modèle Subscription existant :

@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "account_id")
private Account account;
```

## Migration V7 — Séquence

```sql
-- 1. Créer la table accounts
CREATE TABLE accounts (...)

-- 2. Créer le compte par défaut pour chaque utilisateur existant
INSERT INTO accounts (id, nom, type, solde_initial, icone, couleur, is_default, actif, user_id)
SELECT gen_random_uuid(), 'Compte Principal', 'COURANT', 0.00, '🏦', '#3b82f6', true, true, id
FROM users;

-- 3. Ajouter catégorie système "Virement" pour chaque utilisateur existant
INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
SELECT gen_random_uuid(), 'Virement', '🔄', '#8b5cf6', true, id FROM users;

-- 4. Ajouter account_id (nullable d'abord) sur transactions
ALTER TABLE transactions ADD COLUMN account_id UUID;

-- 5. Rattacher transactions existantes au compte par défaut
UPDATE transactions SET account_id = (
    SELECT id FROM accounts
    WHERE is_default = true AND user_id = transactions.user_id
);

-- 6. Contrainte NOT NULL sur account_id
ALTER TABLE transactions ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_account
    FOREIGN KEY (account_id) REFERENCES accounts(id);

-- 7. Ajouter transfer_id sur transactions
ALTER TABLE transactions ADD COLUMN transfer_id UUID;

-- 8. Ajouter account_id (nullable) sur subscriptions
ALTER TABLE subscriptions ADD COLUMN account_id UUID;
ALTER TABLE subscriptions ADD CONSTRAINT fk_subscriptions_account
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL;

-- 9. Index
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE UNIQUE INDEX uq_accounts_nom_user ON accounts(LOWER(nom), user_id) WHERE actif = true;
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_transfer_id ON transactions(transfer_id) WHERE transfer_id IS NOT NULL;
CREATE INDEX idx_subscriptions_account_id ON subscriptions(account_id);
```

## Relations

```
User 1──* Account
User 1──* Transaction
User 1──* Subscription
User 1──* Category

Account 1──* Transaction (obligatoire)
Account 1──* Subscription (optionnel)

Transaction *──1 Category (optionnel)
Transaction.transferId ↔ Transaction.transferId (paire de virement)
```

## Règles métier sur le modèle

1. **soldeInitial figé** : Le champ `solde_initial` n'est pris en compte qu'à la création (POST). Ignoré dans les mises à jour (PUT). Corrections via transaction d'ajustement.
2. **Suppression cascade virements** : Supprimer une transaction avec `transfer_id` non-null supprime automatiquement la transaction liée (même `transfer_id`, `id` différent).
3. **Propagation modification virements** : Modifier le montant d'une transaction avec `transfer_id` non-null propage le nouveau montant à la transaction liée. Seul le montant est propagé.
