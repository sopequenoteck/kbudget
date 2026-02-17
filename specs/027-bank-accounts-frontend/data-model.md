# Data Model: Comptes bancaires — Frontend

**Branch**: `027-bank-accounts-frontend` | **Date**: 2026-02-16

## Fichier: `app/src/app/core/models/account.model.ts`

### Enums

#### AccountType

| Valeur | Description |
|--------|-------------|
| `COURANT` | Compte courant |
| `EPARGNE` | Compte epargne |
| `ESPECES` | Compte especes |

### Interfaces

#### Account (reponse API — lecture)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `string` | Non | UUID du compte |
| `nom` | `string` | Non | Nom du compte (max 50 car.) |
| `type` | `AccountType` | Non | Type de compte |
| `soldeInitial` | `number` | Non | Solde initial (fige apres creation) |
| `solde` | `number` | Non | Solde calcule (soldeInitial + transactions) |
| `icone` | `string` | Non | Emoji icone |
| `couleur` | `string` | Non | Couleur hex (#RRGGBB) |
| `isDefault` | `boolean` | Non | Compte par defaut |
| `actif` | `boolean` | Non | Compte actif |

#### AccountSummary (reference legere dans Transaction/Subscription)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `string` | Non | UUID du compte |
| `nom` | `string` | Non | Nom du compte |
| `icone` | `string` | Non | Emoji icone |
| `couleur` | `string` | Non | Couleur hex |

#### AccountRequest (creation/modification)

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `nom` | `string` | Oui | Nom du compte (1-50 car.) |
| `type` | `AccountType` | Oui | Type de compte |
| `soldeInitial` | `number` | Non (defaut 0) | Solde initial (creation uniquement) |
| `icone` | `string` | Non | Emoji icone (defaut selon type) |
| `couleur` | `string` | Non | Couleur hex (defaut selon type) |
| `actif` | `boolean` | Non (defaut true) | Statut actif |

#### TransferRequest (virement entre comptes)

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `fromAccountId` | `string` | Oui | UUID du compte source |
| `toAccountId` | `string` | Oui | UUID du compte destination |
| `montant` | `number` | Oui | Montant (min 0.01) |
| `note` | `string` | Non | Note optionnelle (max 500 car.) |

#### TransferResponse (resultat d'un virement)

| Champ | Type | Description |
|-------|------|-------------|
| `transferId` | `string` | UUID liant les deux transactions |
| `debitTransaction` | `TransactionRef` | Transaction de debit (source) |
| `creditTransaction` | `TransactionRef` | Transaction de credit (destination) |

#### TransactionRef (reference legere dans TransferResponse)

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `string` | UUID de la transaction |
| `montant` | `number` | Montant |
| `libelle` | `string` | Libelle genere ("Virement vers/depuis X") |
| `type` | `TransactionType` | DEPENSE ou RECETTE |
| `date` | `string` | Date ISO |
| `accountId` | `string` | UUID du compte |
| `accountNom` | `string` | Nom du compte |

## Modifications sur les modeles existants

### Transaction (ajouts)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| `account` | `AccountSummary` | Oui | Compte associe (null pour transactions pre-existantes) |
| `transferId` | `string` | Oui | UUID de virement (null si pas un virement) |

### TransactionRequest (ajout)

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `accountId` | `string` | Non | UUID du compte (optionnel pour retrocompatibilite) |

### Subscription (ajout)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| `account` | `AccountSummary` | Oui | Compte associe (optionnel) |

### SubscriptionRequest (ajout)

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `accountId` | `string` | Non | UUID du compte (optionnel) |

## Relations

```
Account 1 ←──── * Transaction (obligatoire, nullable pour legacy)
Account 1 ←──── * Subscription (optionnel)
Account 1 ←──── 1 User.defaultAccount
Transfer 1 ────→ 2 Transaction (via transferId partagé)
```

## Regles de validation frontend

- `AccountRequest.nom` : 1-50 caracteres, obligatoire
- `AccountRequest.type` : valeur de l'enum AccountType, obligatoire
- `AccountRequest.soldeInitial` : nombre, optionnel (defaut 0)
- `AccountRequest.couleur` : format `#RRGGBB` si fourni
- `TransferRequest.fromAccountId` !== `TransferRequest.toAccountId`
- `TransferRequest.montant` >= 0.01
- Compte par defaut non supprimable, non desactivable
- Compte avec transactions/abonnements non supprimable
