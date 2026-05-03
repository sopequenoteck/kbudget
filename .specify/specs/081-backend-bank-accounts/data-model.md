# Data Model: Banques sur les comptes — Backend

**Feature**: 081-backend-bank-accounts | **Date**: 2026-03-13

## Entités

### Bank (statique, en mémoire)

Registre statique — pas de table en base.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| code | String | PK logique, unique, max 20 | Identifiant unique (ex: "SG", "ECOBANK", "OTHER") |
| name | String | NOT NULL | Nom lisible (ex: "Société Générale") |
| country | String | nullable, 2 chars ISO | Pays d'origine ("FR", "TG", null pour OTHER) |
| brandColor | String | NOT NULL, format #RRGGBB | Couleur brand hexadécimale |
| logoUrl | String | NOT NULL | Path relatif vers le logo SVG (ex: "/api/bank-logos/sg.svg") |

**Stockage** : `BankRegistry` — `Map<String, Bank>` initialisée statiquement. 29 entrées.

### Account (enrichi) — table `accounts`

Colonnes ajoutées par la migration V19 :

| Colonne | Type SQL | Type Java | Contraintes | Description |
|---------|----------|-----------|-------------|-------------|
| bank_code | VARCHAR(20) | String | NOT NULL, DEFAULT 'OTHER' | Code de la banque associée |
| bank_custom_name | VARCHAR(100) | String | nullable | Nom personnalisé (si bank_code='OTHER') |
| bank_custom_logo | TEXT | String | nullable | Logo personnalisé en base64 data URI (si bank_code='OTHER') |

**Colonnes existantes préservées** : `icone`, `couleur` restent inchangés (rétrocompatibilité FR-009).

## Relations

```
Account *---1 Bank (via bank_code, résolution en mémoire, pas de FK SQL)
```

La relation est logique, pas physique : `bank_code` sur Account fait référence à `code` dans BankRegistry, mais il n'y a pas de contrainte FK en base (pas de table banks).

## Migration Flyway V19

```sql
-- V19__add_bank_to_accounts.sql

ALTER TABLE accounts ADD COLUMN bank_code VARCHAR(20) NOT NULL DEFAULT 'OTHER';
ALTER TABLE accounts ADD COLUMN bank_custom_name VARCHAR(100);
ALTER TABLE accounts ADD COLUMN bank_custom_logo TEXT;
```

**Rétrocompatibilité** : Le DEFAULT 'OTHER' assure que tous les comptes existants reçoivent automatiquement cette valeur. Aucune donnée perdue.

## Validation

| Champ | Règle | Niveau |
|-------|-------|--------|
| bankCode | Doit exister dans BankRegistry (ou null → default "OTHER") | Service |
| bankCustomName | Max 100 caractères | Bean Validation (@Size) |
| bankCustomLogo | Texte libre (pas de validation format backend) | Aucune |
| bankCode + bankCustomName/Logo | Si bankCode != "OTHER", les champs custom sont ignorés à la résolution | Service |

## Registre des 29 banques

### France (15)

| Code | Nom | Couleur |
|------|-----|---------|
| SG | Société Générale | #e2001a |
| BNP | BNP Paribas | #00915a |
| CA | Crédit Agricole | #006f4e |
| LCL | LCL | #0046a8 |
| CM | Crédit Mutuel | #005fa3 |
| CE | Caisse d'Épargne | #cf0544 |
| LBP | La Banque Postale | #003d7c |
| BP | Banque Populaire | #0055a4 |
| BOURSO | Boursorama | #ff6600 |
| FORTUNEO | Fortuneo | #58595b |
| HELLO | Hello Bank | #3a3a3a |
| N26 | N26 | #36a18b |
| REVOLUT | Revolut | #0075eb |
| HSBC_FR | HSBC France | #db0011 |
| BIA | BIA | #003366 |

### Togo / UEMOA (12)

| Code | Nom | Couleur |
|------|-----|---------|
| ECOBANK | Ecobank | #0033a0 |
| BOA | Bank of Africa | #e30613 |
| ORABANK | Orabank | #00a651 |
| CORIS | Coris Bank | #f7941d |
| BSIC | BSIC | #004a9f |
| UTB | UTB | #1a3c6e |
| SUNU | SUNU Bank | #0072bc |
| BDT | Banque de Développement du Togo | #006633 |
| NSIA | NSIA Banque | #003399 |
| BTCI | BTCI | #cc0033 |
| SGTO | Société Générale Togo | #e2001a |
| UBA | United Bank for Africa | #d32011 |

### International (1)

| Code | Nom | Couleur |
|------|-----|---------|
| WISE | Wise | #9fe870 |

### Spécial

| Code | Nom | Couleur |
|------|-----|---------|
| OTHER | Autre | #6b7280 |
