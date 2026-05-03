# Data Model: Virement entre comptes Angular

**Feature**: 066-angular-transfer-form
**Date**: 2026-03-01

## Entités frontend (interfaces TypeScript)

### TransferRequest

Requête envoyée au serveur pour effectuer un virement.

| Champ | Type | Requis | Validation | Description |
|-------|------|--------|------------|-------------|
| fromAccountId | string (UUID) | Oui | Non vide | ID du compte source |
| toAccountId | string (UUID) | Oui | Non vide, ≠ fromAccountId | ID du compte destination |
| montant | number | Oui | > 0 (min 0.01) | Montant du virement |
| note | string | Non | Max 500 caractères | Note descriptive optionnelle |

**Validation cross-champ** : `fromAccountId` ≠ `toAccountId` (validateur `differentAccountsValidator`).

### TransferResponse

Réponse du serveur après un virement réussi.

| Champ | Type | Description |
|-------|------|-------------|
| transferId | string (UUID) | Identifiant unique du virement (partagé par les 2 transactions) |
| debitTransaction | TransactionRef | Référence de la transaction de débit (compte source) |
| creditTransaction | TransactionRef | Référence de la transaction de crédit (compte destination) |

### TransactionRef

Référence minimale à une transaction créée par le virement.

| Champ | Type | Description |
|-------|------|-------------|
| id | string (UUID) | ID de la transaction |
| montant | number | Montant de la transaction |
| type | TransactionType | DEPENSE (débit) ou RECETTE (crédit) |

### Account (existant, utilisé dans le formulaire)

Seuls les comptes avec `actif = true` sont proposés dans les sélecteurs.

| Champ utilisé | Type | Description |
|---------------|------|-------------|
| id | string (UUID) | ID du compte |
| nom | string | Nom affiché dans le sélecteur |
| icone | string | Emoji affiché comme icône |
| soldeInitial | number | Utilisé pour afficher le solde dans le texte secondaire |

## Relations

```
TransferForm
  ├── uses → Account[] (comptes actifs, via AccountService.accounts signal)
  ├── sends → TransferRequest (POST /accounts/transfer)
  └── receives → TransferResponse
       ├── debitTransaction → TransactionRef (DEPENSE)
       └── creditTransaction → TransactionRef (RECETTE)
```

## Pas de nouvelles entités

Cette feature ne crée aucune nouvelle entité backend. Elle utilise les modèles existants (`Account`, `Transaction`) et les DTOs déjà définis (`TransferRequest`, `TransferResponse`).
