# Data Model: Formulaire Subscription (modal)

**Feature**: 010-subscription-form | **Date**: 2026-02-09

## Entites utilisees (existantes)

### Subscription (lecture — mode edition)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | string (UUID) | Non | Identifiant unique |
| nom | string | Non | Nom de l'abonnement |
| montant | number | Non | Montant de l'abonnement |
| frequence | Frequency | Non | MENSUEL ou ANNUEL |
| dateDebut | string (ISO) | Non | Date de debut (YYYY-MM-DD) |
| actif | boolean | Non | Statut actif/inactif |
| category | Category | Oui | Categorie associee (objet complet) |

**Source**: `app/src/app/core/models/subscription.model.ts`

### SubscriptionRequest (ecriture — emission formulaire)

| Champ | Type | Requis | Validation |
|-------|------|--------|------------|
| nom | string | Oui | Non vide, max 255 caracteres |
| montant | number | Oui | > 0 |
| frequence | Frequency | Oui | MENSUEL ou ANNUEL |
| dateDebut | string (ISO) | Oui | Format YYYY-MM-DD |
| actif | boolean | Non | Defaut true |
| categoryId | string (UUID) | Non | UUID d'une categorie existante |

**Source**: `app/src/app/core/models/subscription.model.ts`

### Frequency (enum)

| Valeur | Description |
|--------|-------------|
| MENSUEL | Abonnement mensuel |
| ANNUEL | Abonnement annuel |

**Source**: `app/src/app/core/models/subscription.model.ts`

### Category (lecture — liste deroulante)

| Champ | Type | Description |
|-------|------|-------------|
| id | string (UUID) | Identifiant unique |
| nom | string | Nom de la categorie |
| icone | string | Emoji ou code icone |
| couleur | string | Code couleur hex |

**Source**: `app/src/app/core/models/category.model.ts`

## Mapping formulaire → SubscriptionRequest

| Champ formulaire | FormControl | Type HTML | Mapping vers DTO |
|------------------|-------------|-----------|------------------|
| Nom | `nom` | `<input type="text">` | `request.nom` |
| Montant | `montant` | `<input type="number">` | `request.montant` |
| Frequence | `frequence` | Toggle segmente (2 boutons) | `request.frequence` |
| Date de debut | `dateDebut` | `<input type="date">` | `request.dateDebut` (YYYY-MM-DD) |
| Actif | `actif` | `<input type="checkbox">` | `request.actif` |
| Categorie | `categoryId` | `<select>` | `request.categoryId` (UUID ou undefined) |

## Valeurs par defaut (mode creation)

| Champ | Valeur par defaut |
|-------|-------------------|
| nom | `''` (vide) |
| montant | `''` (vide, pas 0) |
| frequence | `Frequency.MENSUEL` |
| dateDebut | Date du jour (`new Date().toISOString().split('T')[0]`) |
| actif | `true` |
| categoryId | `''` (aucune categorie) |

## Pre-remplissage (mode edition)

Quand `subscription` input est non-null :

| Champ | Source | Transformation |
|-------|--------|----------------|
| nom | `subscription.nom` | Aucune |
| montant | `subscription.montant` | Aucune |
| frequence | `subscription.frequence` | Aucune |
| dateDebut | `subscription.dateDebut` | Aucune (deja YYYY-MM-DD) |
| actif | `subscription.actif` | Aucune |
| categoryId | `subscription.category?.id` | Extraction de l'ID depuis l'objet Category, ou `''` si null |
