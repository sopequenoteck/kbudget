# Data Model: Flutter — Formulaire Transaction

**Feature**: `044-flutter-transaction-form` | **Date**: 2026-02-23

## Entités existantes (aucune modification)

### Transaction (Freezed — existant)

```
Transaction
├── id: String (required)
├── montant: double (required, > 0)
├── libelle: String (required, max 255)
├── type: TransactionType (required) — depense | recette | ajustement
├── date: DateTime (required)
├── note: String? (optional, max 500)
├── transferId: String? (optional — pour les virements entre comptes)
├── categoryId: String? (optional — FK → Category)
├── accountId: String? (optional — FK → Account)
└── updatedAt: DateTime? (optional)
```

### Account (Freezed — existant)

```
Account
├── id: String (required)
├── nom: String (required)
├── type: AccountType — courant | epargne | especes
├── soldeInitial: double (required)
├── icone: String (required — emoji)
├── couleur: String (required — hex color)
├── isDefault: bool (default: false)
├── currency: Currency (default: eur)
├── actif: bool (default: true)
├── solde: double (default: 0)
└── updatedAt: DateTime?
```

### Category (Freezed — existant)

```
Category
├── id: String (required)
├── nom: String (required)
├── icone: String (required — emoji)
├── couleur: String (required — hex color)
├── isSystem: bool (default: false)
└── updatedAt: DateTime?
```

## Relations

```
Transaction ──ManyToOne──▶ Account  (via accountId)
Transaction ──ManyToOne──▶ Category (via categoryId)
```

Les catégories sont type-agnostiques : une même catégorie peut être utilisée pour une Dépense ou une Recette.

## Enums existants

- **TransactionType**: `depense`, `recette`, `ajustement`
- **AccountType**: `courant`, `epargne`, `especes`
- **Currency**: `eur`, `usd`, `gbp`, ...

## Validation Rules (formulaire)

| Champ | Règle | Message d'erreur |
|-------|-------|------------------|
| libelle | Non vide, max 255 | "Champ requis" / "255 caractères max" |
| montant | Non vide, > 0 | "Champ requis" / "Le montant doit être positif" |
| date | Non null | "Champ requis" (toujours pré-remplie) |
| accountId | Non null | "Sélectionnez un compte" |
| categoryId | Non null | "Sélectionnez une catégorie" |
| note | Max 500 | "500 caractères max" |

## State transitions

```
[Création]
  Formulaire vide → Saisie → Validation → Soumission → Transaction créée

[Édition]
  Transaction existante → Pré-remplissage → Modification → Validation → Soumission → Transaction mise à jour

[Suppression]
  Mode édition → Bouton supprimer → Confirmation → Transaction supprimée
```

## Nouveaux modèles

Aucun nouveau modèle Freezed requis. Le formulaire utilise l'état local du widget (`TextEditingController` + variables `State`) et construit un objet `Transaction` existant à la soumission.
