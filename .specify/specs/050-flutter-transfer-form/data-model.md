# Data Model: Formulaire Virement

**Feature**: 050-flutter-transfer-form | **Date**: 2026-02-23

## Entités

### Transaction (existant — aucune modification)

Modèle domaine Freezed déjà défini dans `flutter/lib/src/domain/models/transaction.dart`.

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | String | Non | UUID unique |
| montant | double | Non | Montant de la transaction |
| libelle | String | Non | Libellé (auto-généré par le backend pour les virements) |
| type | TransactionType | Non | DEPENSE ou RECETTE |
| date | DateTime | Non | Date de la transaction |
| note | String? | Oui | Note libre (max 500 car.) |
| transferId | String? | Oui | UUID du virement. Non-null si la transaction fait partie d'un virement |
| categoryId | String? | Oui | FK vers Category |
| accountId | String? | Oui | FK vers Account |
| updatedAt | DateTime? | Oui | Dernière modification |

### Account (existant — aucune modification)

Modèle domaine Freezed déjà défini dans `flutter/lib/src/domain/models/account.dart`.
Seuls les comptes actifs (`actif == true`) sont proposés dans les sélecteurs du formulaire de virement.

## DTOs (nouveaux)

### TransferRequest (DTO de transport)

Envoyé au backend via POST `/accounts/transfer`.

| Champ | Type JSON | Validation backend | Description |
|-------|-----------|-------------------|-------------|
| fromAccountId | string (UUID) | @NotNull | ID du compte source |
| toAccountId | string (UUID) | @NotNull | ID du compte destination |
| montant | number | @NotNull, @DecimalMin("0.01") | Montant du virement |
| note | string? | @Size(max=500) | Note optionnelle |

### TransferResponse (DTO de transport)

Reçu du backend après POST `/accounts/transfer`.

| Champ | Type JSON | Description |
|-------|-----------|-------------|
| transferId | string (UUID) | Identifiant unique du virement (partagé par les 2 transactions) |
| debitTransaction | TransactionRef | Transaction de dépense créée sur le compte source |
| creditTransaction | TransactionRef | Transaction de recette créée sur le compte destination |

### TransactionRef (DTO imbriqué dans TransferResponse)

| Champ | Type JSON | Description |
|-------|-----------|-------------|
| id | string (UUID) | ID de la transaction créée |
| montant | number | Montant |
| libelle | string | Libellé auto-généré (ex: "Virement Courant → Épargne") |
| type | string | "DEPENSE" ou "RECETTE" |
| date | string (ISO date) | Date de la transaction |
| accountId | string (UUID) | ID du compte concerné |
| accountNom | string | Nom du compte (pour affichage) |

## Relations

```
TransferResponse 1──2 TransactionRef
Account 1──* Transaction (via accountId)
Transaction *──? Transfer (via transferId, nullable)
```

## Transitions d'état

### État du formulaire de virement

```
[Initial] → Ready (formulaire vide, prêt à saisir)

[Ready] → Submitting → Success (modal se ferme, transactions rafraîchies)
                     → Error (message affiché, formulaire reste rempli)

[Error] → Ready (utilisateur corrige et réessaie)
```

- **Ready** : Formulaire affiché avec champs vides (ou pré-remplis si contexte)
- **Submitting** : POST /accounts/transfer en cours (bouton disabled, indicateur chargement)
- **Success** : Modal fermée, `TransactionListNotifier.refresh()` appelé
- **Error** : Message d'erreur serveur affiché, champs conservés

## Mapping DTO → Domain

Le `TransferResponse` n'est pas mappé vers un modèle domaine — il est utilisé uniquement pour confirmer le succès de l'opération. Les transactions créées sont récupérées via le refresh de la liste des transactions (mécanisme existant).
