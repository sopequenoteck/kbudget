# Data Model: Améliorations dettes Flutter

**Feature**: 079-flutter-debt-enhancements | **Date**: 2026-03-13

## Entities

### Debt (enrichi)

Extension du model Freezed existant `domain/models/debt.dart`.

| Champ | Type | Nouveau | Défaut | Description |
|-------|------|---------|--------|-------------|
| id | String | non | required | UUID |
| personne | String | non | required | Nom du débiteur/créancier |
| montant | double | non | required | Montant initial de la dette |
| sens | DebtType | non | required | EMPRUNT ou PRET |
| date | DateTime | non | required | Date de la dette |
| currency | Currency | non | EUR | Devise |
| rembourse | bool | non | false | Statut remboursé |
| categoryId | String? | non | null | FK catégorie |
| updatedAt | DateTime? | non | null | Date de mise à jour |
| **accountId** | **String?** | **oui** | **null** | **FK compte bancaire associé** |
| **accountName** | **String?** | **oui** | **null** | **Nom du compte (dénormalisé pour affichage)** |
| **includeInBalance** | **bool** | **oui** | **false** | **Inclure dans le calcul patrimoine** |
| **dueDate** | **DateTime?** | **oui** | **null** | **Date d'échéance** |
| **reminderDate** | **DateTime?** | **oui** | **null** | **Date de rappel** |
| **reminderTime** | **String?** | **oui** | **null** | **Heure de rappel (format "HH:mm")** |
| **remainingAmount** | **double?** | **oui** | **null** | **Montant restant (calculé côté API)** |

### DebtPayment (nouveau)

Nouveau model Freezed `domain/models/debt_payment.dart`.

| Champ | Type | Description |
|-------|------|-------------|
| id | String | UUID du paiement (= transaction ID) |
| montant | double | Montant du remboursement |
| date | DateTime | Date du paiement |
| accountName | String? | Nom du compte source |

### Relationships

```
Debt 1 ──── * DebtPayment  (via API, pas de FK locale)
Debt * ──── 1 Account      (via accountId, nullable)
Debt * ──── 1 Category     (via categoryId, nullable)
```

## DTOs (enrichis)

### DebtRequest (Freezed, enrichi)

Champs ajoutés au DTO existant `data/remote/dtos/debt_dtos.dart` :

| Champ | Type | Description |
|-------|------|-------------|
| accountId | String? | Compte associé |
| currency | String? | Devise (masqué si compte sélectionné) |
| includeInBalance | bool | Inclure dans patrimoine |
| reminderDate | String? | Date rappel (ISO) |
| reminderTime | String? | Heure rappel "HH:mm" |
| dueDate | String? | Date d'échéance (ISO) |

### DebtResponse (Freezed, enrichi)

Champs ajoutés au DTO existant :

| Champ | Type | Description |
|-------|------|-------------|
| accountId | String? | Compte associé |
| accountName | String? | Nom du compte |
| includeInBalance | bool | Inclure dans patrimoine |
| dueDate | String? | Date d'échéance |
| reminderDate | String? | Date rappel |
| reminderTime | String? | Heure rappel |
| remainingAmount | double? | Montant restant (calculé API) |

### RepayRequest (nouveau)

| Champ | Type | Description |
|-------|------|-------------|
| accountId | String | Compte source (obligatoire) |
| amount | double? | Montant (null = montant restant total) |

### SnoozeRequest (nouveau)

| Champ | Type | Description |
|-------|------|-------------|
| reminderDate | String | Nouvelle date rappel (ISO) |
| reminderTime | String | Nouvelle heure rappel "HH:mm" |

### PaymentResponse (nouveau)

| Champ | Type | Description |
|-------|------|-------------|
| id | String | UUID transaction |
| montant | double | Montant du paiement |
| date | String | Date ISO |
| accountName | String? | Nom du compte source |

## State Transitions

```
Debt lifecycle:
  CREATED → EN_COURS (rembourse=false, remainingAmount=montant)
  EN_COURS → PARTIELLEMENT_REMBOURSE (remainingAmount > 0, remainingAmount < montant)
  PARTIELLEMENT_REMBOURSE → REMBOURSE (rembourse=true, remainingAmount=0)
  EN_COURS → REMBOURSE (remboursement total en une fois)
```

## Validation Rules

| Contexte | Règle |
|----------|-------|
| Formulaire — montant | > 0 |
| Formulaire — personne | Non vide, max 255 caractères |
| Formulaire — compte sélectionné | Currency forcée à celle du compte |
| Formulaire — rappel heure | Visible si date rappel sélectionnée, défaut "09:00" |
| Remboursement — montant | 0.01 ≤ montant ≤ remainingAmount |
| Remboursement — compte | Obligatoire (au moins 1 compte actif) |
| Snooze — date | Future obligatoire |
| Snooze — heure | Obligatoire |
