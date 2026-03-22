# Data Model: Formulaire Transaction (modal)

**Feature**: 009-transaction-form | **Date**: 2026-02-09

## Entités utilisées (existantes)

### Transaction (lecture — mode édition)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | string (UUID) | Non | Identifiant unique |
| montant | number | Non | Montant de la transaction |
| libelle | string | Non | Libellé descriptif (max 255) |
| type | TransactionType | Non | DEPENSE ou RECETTE |
| date | string (ISO) | Non | Date de la transaction (YYYY-MM-DD) |
| category | Category | Oui | Catégorie associée (objet complet) |
| note | string | Oui | Note optionnelle (max 500) |

**Source**: `app/src/app/core/models/transaction.model.ts`

### TransactionRequest (écriture — émission formulaire)

| Champ | Type | Requis | Validation |
|-------|------|--------|------------|
| montant | number | Oui | > 0 |
| libelle | string | Oui | Non vide, max 255 caractères |
| type | TransactionType | Oui | DEPENSE ou RECETTE |
| date | string (ISO) | Oui | Format YYYY-MM-DD |
| categoryId | string (UUID) | Non | UUID d'une catégorie existante |
| note | string | Non | Max 500 caractères |

**Source**: `app/src/app/core/models/transaction.model.ts`

### TransactionType (enum)

| Valeur | Description |
|--------|-------------|
| DEPENSE | Dépense (sortie d'argent) |
| RECETTE | Recette (entrée d'argent) |

**Source**: `app/src/app/core/models/transaction.model.ts`

### Category (lecture — liste déroulante)

| Champ | Type | Description |
|-------|------|-------------|
| id | string (UUID) | Identifiant unique |
| nom | string | Nom de la catégorie |
| icone | string | Emoji ou code icône |
| couleur | string | Code couleur hex |

**Source**: `app/src/app/core/models/category.model.ts`

## Mapping formulaire → TransactionRequest

| Champ formulaire | FormControl | Type HTML | Mapping vers DTO |
|------------------|-------------|-----------|------------------|
| Libellé | `libelle` | `<input type="text">` | `request.libelle` |
| Montant | `montant` | `<input type="number">` | `request.montant` |
| Type | `type` | Toggle segmenté (2 boutons) | `request.type` |
| Date | `date` | `<input type="date">` | `request.date` (YYYY-MM-DD) |
| Catégorie | `categoryId` | `<select>` | `request.categoryId` (UUID ou undefined) |
| Note | `note` | `<textarea>` | `request.note` (string ou undefined) |

## Valeurs par défaut (mode création)

| Champ | Valeur par défaut |
|-------|-------------------|
| libelle | `''` (vide) |
| montant | `''` (vide, pas 0) |
| type | `TransactionType.DEPENSE` |
| date | Date du jour (`new Date().toISOString().split('T')[0]`) |
| categoryId | `''` (aucune catégorie) |
| note | `''` (vide) |

## Pré-remplissage (mode édition)

Quand `transaction` input est non-null :

| Champ | Source | Transformation |
|-------|--------|----------------|
| libelle | `transaction.libelle` | Aucune |
| montant | `transaction.montant` | Aucune |
| type | `transaction.type` | Aucune |
| date | `transaction.date` | Aucune (déjà YYYY-MM-DD) |
| categoryId | `transaction.category?.id` | Extraction de l'ID depuis l'objet Category, ou `''` si null |
| note | `transaction.note` | `?? ''` (null → vide) |
