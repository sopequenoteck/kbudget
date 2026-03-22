# Data Model: Gestion des devises (multi-currency)

**Feature**: 030-multi-currency | **Date**: 2026-02-17

## Nouveau enum

### Currency

```java
package fr.kksdev.budget.api.enums;

public enum Currency {
    EUR("€", "Euro", 2),
    XOF("CFA", "Franc CFA (BCEAO)", 0),
    USD("$", "Dollar américain", 2),
    GBP("£", "Livre sterling", 2),
    CHF("CHF", "Franc suisse", 2),
    CAD("CA$", "Dollar canadien", 2),
    MAD("MAD", "Dirham marocain", 2);

    private final String symbol;
    private final String displayName;
    private final int decimalPlaces;
}
```

**Stockage DB** : `VARCHAR(3)`, `@Enumerated(EnumType.STRING)`

## Entités modifiées

### User (ajout)

| Champ | Type | Contraintes | Notes |
|-------|------|-------------|-------|
| `defaultCurrency` | `Currency` | `NOT NULL`, `DEFAULT EUR` | Devise par défaut pour pré-remplissage formulaires |

```
@Enumerated(EnumType.STRING)
@Column(name = "default_currency", nullable = false, length = 3)
@Builder.Default
private Currency defaultCurrency = Currency.EUR;
```

### Account (ajout)

| Champ | Type | Contraintes | Notes |
|-------|------|-------------|-------|
| `currency` | `Currency` | `NOT NULL`, `DEFAULT EUR` | Immuable après création (FR-002) |

```
@Enumerated(EnumType.STRING)
@Column(nullable = false, length = 3)
@Builder.Default
private Currency currency = Currency.EUR;
```

**Règle business** : `AccountService.updateAccount()` interdit la modification de `currency`.

### Debt (ajout)

| Champ | Type | Contraintes | Notes |
|-------|------|-------------|-------|
| `currency` | `Currency` | `NOT NULL`, `DEFAULT EUR` | Indépendant des comptes, modifiable |

```
@Enumerated(EnumType.STRING)
@Column(nullable = false, length = 3)
@Builder.Default
private Currency currency = Currency.EUR;
```

### Subscription (ajout)

| Champ | Type | Contraintes | Notes |
|-------|------|-------------|-------|
| `currency` | `Currency` | `NOT NULL`, `DEFAULT EUR` | Forcée depuis account si lié, sinon modifiable |

```
@Enumerated(EnumType.STRING)
@Column(nullable = false, length = 3)
@Builder.Default
private Currency currency = Currency.EUR;
```

**Règle business** : Si `account != null`, alors `currency = account.getCurrency()` (forcé par le service).

### Transaction (inchangé)

Pas de nouveau champ. La devise est déduite de `account.currency` via la relation existante.

## Migration Flyway V8

```sql
-- V8__add_currency_support.sql

-- Ajouter currency aux comptes (immuable après création)
ALTER TABLE accounts ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR';

-- Ajouter currency aux dettes
ALTER TABLE debts ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR';

-- Ajouter currency aux abonnements
ALTER TABLE subscriptions ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR';

-- Ajouter devise par défaut aux utilisateurs
ALTER TABLE users ADD COLUMN default_currency VARCHAR(3) NOT NULL DEFAULT 'EUR';
```

**Impact migration** : Zero-downtime. Toutes les colonnes ont une valeur par défaut. Les données existantes reçoivent EUR automatiquement (FR-012).

## Diagramme relations (extrait pertinent)

```
User 1──N Account
  │         │ currency (immuable)
  │         │
  │         ├──N Transaction (currency héritée de Account)
  │         └──N Subscription (currency forcée = Account.currency)
  │
  ├──N Debt (currency indépendante)
  │
  └── defaultCurrency (préférence)
        └── pré-remplit Account.currency, Debt.currency, Subscription.currency (si pas de compte)
```

## Règles de validation

| Règle | Entité | Enforcement |
|-------|--------|-------------|
| Currency obligatoire à la création | Account, Debt, Subscription | `@NotNull` sur request DTO + DB `NOT NULL` |
| Currency immuable | Account | `AccountService.updateAccount()` ignore ou rejette |
| Currency = account.currency si lié | Subscription | `SubscriptionService.create/update()` force la valeur |
| Transfer même devise uniquement | Account (transfer) | `AccountService.transfer()` compare les devises |
| DefaultCurrency valide | User | Enum validation automatique (`@NotNull Currency`) |
| Code ISO 3 chars | Tous | Garanti par l'enum (pas de String libre) |
