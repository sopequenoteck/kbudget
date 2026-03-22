# Data Model: 083-flutter-bank-accounts

## Entités

### Bank (nouveau modèle Freezed)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| code | String | non | Code unique banque (ex: "SG", "BNP", "OTHER") |
| name | String | non | Nom complet (ex: "Société Générale") |
| country | String | oui | Code pays ("FR", "TG") ou null pour International |
| brandColor | String | non | Couleur hex de la marque (ex: "#e2001a") |
| logoUrl | String | oui | URL relative du logo SVG côté serveur |

**Source** : `GET /api/banks` (liste statique de 29 banques)
**Sérialisation** : `@freezed` + `fromJson`/`toJson`

### Account (enrichi)

Champs ajoutés au modèle Freezed existant :

| Champ | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| bankCode | String | non | "OTHER" | Code banque associée |
| bankName | String | oui | null | Nom résolu (depuis API response) |
| bankCountry | String | oui | null | Pays résolu |
| bankBrandColor | String | oui | null | Couleur brand résolue |
| bankLogoUrl | String | oui | null | URL logo résolue |
| bankCustomName | String | oui | null | Nom banque personnalisé (si OTHER) |
| bankCustomLogo | String | oui | null | Logo custom en base64 data URI (si OTHER) |

### AccountRequest DTO (enrichi)

Champs ajoutés :

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| bankCode | String | oui | Code banque (envoyé au backend) |
| bankCustomName | String | oui | Nom custom (seulement si OTHER) |
| bankCustomLogo | String | oui | Logo custom base64 (seulement si OTHER) |

### AccountResponse DTO (enrichi)

Champs ajoutés (reçus du backend) :

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| bankCode | String | oui | Code banque |
| bankName | String | oui | Nom résolu par le backend |
| bankCountry | String | oui | Pays résolu |
| bankBrandColor | String | oui | Couleur brand résolue |
| bankLogoUrl | String | oui | URL logo résolue |
| bankCustomName | String | oui | Nom custom |
| bankCustomLogo | String | oui | Logo custom base64 |

### Table Drift `Accounts` (enrichie)

Colonnes ajoutées à la table SQLite :

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| bankCode | TextColumn | oui | Code banque |
| bankCustomName | TextColumn | oui | Nom custom |
| bankCustomLogo | TextColumn | oui | Logo custom base64 (TEXT) |

**Note** : Seuls `bankCode`, `bankCustomName` et `bankCustomLogo` sont persistés en Drift. Les champs résolus (`bankName`, `bankCountry`, `bankBrandColor`, `bankLogoUrl`) sont dérivés de l'API response et ne sont pas stockés localement (ils sont recalculés côté serveur).

## Relations

```
Bank (statique, mémoire)
  ↓ code → bankCode
Account (enrichi)
  ├── bankCode: String → résolution vers Bank
  ├── bankCustomName: String? → si bankCode == "OTHER"
  └── bankCustomLogo: String? → si bankCode == "OTHER"
```

## Résolution visuelle (AccountBankIcon)

```
bankCode ≠ "OTHER" et bankCode non vide ?
  → SvgPicture.asset('assets/banks/${bankCode.toLowerCase()}.svg', size)
  → Erreur ? → emoji fallback

bankCode == "OTHER" et bankCustomLogo non null ?
  → Image.memory(base64Decode(bankCustomLogo), size)
  → Erreur ? → emoji fallback

Sinon → Text(account.icone) emoji
```

## Groupement banques (BankSelectPicker)

| Groupe | Filtre pays | Label affiché |
|--------|-------------|---------------|
| France | country == "FR" | "France" |
| Afrique de l'Ouest | country == "TG" | "Afrique de l'Ouest" |
| International | country == null | "International" |
| Autre | code == "OTHER" (exclu des groupes, affiché séparément en bas) | "Autre / Personnalisé" |
