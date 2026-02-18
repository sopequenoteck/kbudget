# Data Model: 031-flutter-setup

**Date**: 2026-02-18
**Branch**: `031-flutter-setup`

## Vue d'ensemble

Le modele de donnees Flutter porte les entites du backend Spring Boot existant. Deux sources de verite coexistent selon le mode :
- **Mode local** : Drift (SQLite) sur l'appareil
- **Mode serveur** : API REST (PostgreSQL backend)

Les entites utilisent des UUID v4 comme identifiants dans les deux modes.

## Entites

### AppConfig (Flutter-only, local uniquement)

Configuration persistee de l'application. Stockee via `flutter_secure_storage` (pas Drift).

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| dataMode | DataMode enum | non | LOCAL ou SERVER |
| serverUrl | String | oui | URL du serveur (mode SERVER) |
| theme | AppTheme enum | non | LIGHT ou DARK |
| lockEnabled | bool | non | Verrouillage biometrique/PIN actif |
| lockMethod | LockMethod enum | oui | BIOMETRIC, PIN ou null |
| hashedPin | String | oui | PIN hashe (si lockMethod = PIN) |
| onboardingCompleted | bool | non | Onboarding termine |

**Enums Flutter-only** :
- `DataMode` : `local`, `server`
- `AppTheme` : `light`, `dark`
- `LockMethod` : `biometric`, `pin`

---

### User (mode serveur uniquement)

| Champ | Type | Nullable | Contraintes |
|-------|------|----------|-------------|
| id | UUID | non | PK |
| email | String | non | unique, max 255 |
| name | String | oui | max 255 |
| defaultCurrency | Currency | non | default EUR |

**Note** : pas de champ `password` cote Flutter (gere par le backend via JWT).

---

### Account

| Champ | Type | Nullable | Contraintes |
|-------|------|----------|-------------|
| id | UUID | non | PK |
| nom | String | non | max 50 |
| type | AccountType | non | COURANT, EPARGNE, ESPECES |
| soldeInitial | Decimal | non | |
| icone | String | non | max 10 (emoji) |
| couleur | String | non | max 7 (hex #RRGGBB) |
| isDefault | bool | non | default false |
| currency | Currency | non | default EUR |
| actif | bool | non | default true |
| updatedAt | DateTime | oui | |
| userId | UUID | non | FK → User |

---

### Transaction

| Champ | Type | Nullable | Contraintes |
|-------|------|----------|-------------|
| id | UUID | non | PK |
| montant | Decimal | non | > 0 |
| libelle | String | non | max 255 |
| type | TransactionType | non | DEPENSE, RECETTE |
| date | Date | non | |
| note | String | oui | max 500 |
| transferId | UUID | oui | UUID du transfert jumeau |
| updatedAt | DateTime | oui | |
| categoryId | UUID | oui | FK → Category |
| accountId | UUID | non | FK → Account |
| userId | UUID | non | FK → User |

---

### Category

| Champ | Type | Nullable | Contraintes |
|-------|------|----------|-------------|
| id | UUID | non | PK |
| nom | String | non | max 255 |
| icone | String | non | max 50 (emoji) |
| couleur | String | non | max 7 (hex) |
| isSystem | bool | non | default false |
| updatedAt | DateTime | oui | |
| userId | UUID | non | FK → User |

---

### Subscription

| Champ | Type | Nullable | Contraintes |
|-------|------|----------|-------------|
| id | UUID | non | PK |
| nom | String | non | max 255 |
| montant | Decimal | non | > 0 |
| frequence | Frequency | non | MENSUEL, ANNUEL |
| dateDebut | Date | non | |
| currency | Currency | non | default EUR |
| actif | bool | non | default true |
| updatedAt | DateTime | oui | |
| categoryId | UUID | oui | FK → Category |
| accountId | UUID | oui | FK → Account |
| userId | UUID | non | FK → User |

---

### Debt

| Champ | Type | Nullable | Contraintes |
|-------|------|----------|-------------|
| id | UUID | non | PK |
| personne | String | non | max 255 |
| montant | Decimal | non | > 0 |
| sens | DebtType | non | EMPRUNT, PRET |
| date | Date | non | |
| currency | Currency | non | default EUR |
| rembourse | bool | non | default false |
| updatedAt | DateTime | oui | |
| categoryId | UUID | oui | FK → Category |
| userId | UUID | non | FK → User |

---

## Enums (portage backend)

| Enum | Valeurs | Source backend |
|------|---------|----------------|
| TransactionType | DEPENSE, RECETTE | TransactionType.java |
| Frequency | MENSUEL, ANNUEL | Frequency.java |
| DebtType | EMPRUNT, PRET | DebtType.java |
| AccountType | COURANT, EPARGNE, ESPECES | AccountType.java |
| Currency | EUR, XOF, USD, GBP, CHF, CAD, MAD | Currency.java |

### Currency metadata

| Code | Symbole | Nom | Decimales |
|------|---------|-----|-----------|
| EUR | € | Euro | 2 |
| XOF | CFA | Franc CFA (BCEAO) | 0 |
| USD | $ | Dollar americain | 2 |
| GBP | £ | Livre sterling | 2 |
| CHF | CHF | Franc suisse | 2 |
| CAD | CA$ | Dollar canadien | 2 |
| MAD | MAD | Dirham marocain | 2 |

## Relations

```
User (1) ──→ (N) Account
User (1) ──→ (N) Transaction
User (1) ──→ (N) Category
User (1) ──→ (N) Subscription
User (1) ──→ (N) Debt

Account (1) ──→ (N) Transaction
Account (1) ──→ (N) Subscription

Category (1) ──→ (N) Transaction
Category (1) ──→ (N) Subscription
Category (1) ──→ (N) Debt
```

## Drift Schema (mode local)

Les tables Drift mirrored sur les entites ci-dessus. Une migration V1 cree toutes les tables. Le `userId` en mode local est un UUID fixe genere au setup (pas de multi-utilisateur local).

## API DTOs (mode serveur)

Les classes Dart correspondantes aux request/response DTOs du backend sont generees via `freezed` + `json_serializable`. Voir `contracts/` pour le mapping complet.
