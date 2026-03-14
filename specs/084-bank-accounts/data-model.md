# Data Model: Banques sur les comptes

**Date**: 2026-03-14
**Status**: Done (rétroactif)

## Entités

### Bank (constante embarquée, pas en BDD)

| Attribut | Type | Contraintes | Description |
|----------|------|-------------|-------------|
| code | String | PK, unique, majuscules | Identifiant banque (ex. "SG", "BNP", "OTHER") |
| name | String | Non null | Nom affiché (ex. "Société Générale") |
| country | String | Nullable | Code pays : "FR", "TG", null (international) |
| brandColor | String | Non null, format hex | Couleur brand (ex. "#e4002b") |
| logoUrl | String | Non null | Chemin relatif vers le logo SVG (ex. "/api/bank-logos/sg.svg") |

**29 banques** : 15 France + 12 Togo/UEMOA + 1 International (WISE) + 1 OTHER

### BankResolvedInfo (objet résolu côté service)

| Attribut | Type | Description |
|----------|------|-------------|
| bankCode | String | Code de la banque |
| bankName | String | Nom affiché (résolu : nom banque connue ou nom custom) |
| bankCountry | String | Code pays (nullable) |
| bankBrandColor | String | Couleur brand (nullable pour OTHER sans custom) |
| bankLogoUrl | String | URL logo (SVG banque ou data URI custom, nullable) |
| bankCustomName | String | Nom custom (nullable, seulement si OTHER) |
| bankCustomLogo | String | Logo custom base64 (nullable, seulement si OTHER) |

### Account (enrichissement — 3 nouvelles colonnes)

| Attribut | Type | Contraintes | Description |
|----------|------|-------------|-------------|
| bankCode | VARCHAR(20) | NOT NULL, DEFAULT 'OTHER' | Code banque sélectionnée |
| bankCustomName | VARCHAR(100) | Nullable | Nom custom (si bankCode = 'OTHER') |
| bankCustomLogo | TEXT | Nullable | Logo custom en base64 data URI (si bankCode = 'OTHER') |

## Migration Flyway V19

```sql
ALTER TABLE accounts ADD COLUMN bank_code VARCHAR(20) NOT NULL DEFAULT 'OTHER';
ALTER TABLE accounts ADD COLUMN bank_custom_name VARCHAR(100);
ALTER TABLE accounts ADD COLUMN bank_custom_logo TEXT;
```

Comptes existants : `bank_code = 'OTHER'` automatiquement (DEFAULT). Rétrocompatibilité totale.

## Migration Drift (Flutter) v2 → v3

```dart
// 3 colonnes ajoutées à la table Accounts
bankCode: text().nullable()
bankCustomName: text().nullable()
bankCustomLogo: text().nullable()
```

**Note** : `bankCode` est `nullable()` côté Drift (SQLite `addColumn` ne supporte pas `NOT NULL DEFAULT` en migration). Le mapper applique `?? 'OTHER'` à la lecture pour garantir la même sémantique que PostgreSQL (`NOT NULL DEFAULT 'OTHER'`).

## Relations

```
Bank (static) ─── resolvedBy ──→ BankService.resolveBank(account)
                                      │
Account ◄────── enriches ─────────────┘
  └── bankCode → lookup dans BankRegistry
  └── bankCustomName (si OTHER)
  └── bankCustomLogo (si OTHER)
```

## Règles métier

1. Si `bankCode` != 'OTHER' → logo et couleur proviennent du `BankRegistry` (champs `icone`/`couleur` du compte ignorés)
2. Si `bankCode` = 'OTHER' → utiliser `bankCustomName` (si fourni), `bankCustomLogo` (si fourni), sinon fallback sur `icone`/`couleur` existants
3. `icone` et `couleur` restent en base pour rétrocompatibilité mais ne sont utilisés qu'en fallback
4. La résolution se fait côté service (`BankService.resolveBank()`) — le client reçoit les 7 champs résolus dans `AccountResponse`
