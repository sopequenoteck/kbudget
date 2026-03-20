# API Contracts: 078-angular-debt-enhancements

Endpoints backend consommés par le frontend Angular. Tous sous `/api`, authentification JWT requise.

## Endpoints existants (enrichis)

### POST /debts
Création d'une dette avec les nouveaux champs.

**Request**: `DebtRequest` (voir data-model.md)
**Response**: `DebtResponse` (201 Created)

### PUT /debts/{id}
Mise à jour d'une dette.

**Request**: `DebtRequest`
**Response**: `DebtResponse` (200 OK)

### GET /debts/{id}
Détail d'une dette avec montant restant et compte associé.

**Response**: `DebtResponse` (200 OK)

### GET /debts?rembourse={boolean}
Liste des dettes avec filtre optionnel.

**Response**: `DebtResponse[]` (200 OK)

## Nouveaux endpoints (KKS-077)

### POST /debts/{id}/repay
Enregistre un remboursement (partiel ou total).

**Request**:
```json
{
  "accountId": "uuid",
  "amount": 200.00
}
```

**Response**: `DebtResponse` (200 OK) — dette mise à jour avec `montantRestant` recalculé, `rembourse` = true si soldé.

**Erreurs**:
- 404 : dette non trouvée
- 400 : montant > montantRestant, montant <= 0, compte inexistant/inactif

### GET /debts/{id}/payments
Historique des paiements d'une dette.

**Response**:
```json
[
  {
    "id": "uuid",
    "amount": 200.00,
    "date": "2026-03-10",
    "accountName": "Compte Courant"
  }
]
```

**Erreurs**: 404 (dette non trouvée)

### POST /debts/{id}/snooze
Report du rappel d'une dette.

**Request**:
```json
{
  "reminderDate": "2026-03-15",
  "reminderTime": "09:00"
}
```

**Response**: `DebtResponse` (200 OK) — avec `reminderDate` et `reminderTime` mis à jour.

**Erreurs**:
- 404 : dette non trouvée
- 400 : date dans le passé

### GET /accounts/total-balance
Patrimoine total agrégé par devise (comptes + dettes incluses).

**Response**:
```json
{
  "balances": [
    { "currency": "EUR", "amount": 2500.00 },
    { "currency": "XOF", "amount": 1639892.00 }
  ]
}
```

## DebtResponse complète

```json
{
  "id": "uuid",
  "personne": "Jean",
  "montant": 500.00,
  "sens": "EMPRUNT",
  "date": "2026-01-15",
  "dueDate": "2026-06-15",
  "currency": "EUR",
  "rembourse": false,
  "montantRestant": 300.00,
  "category": { "id": "uuid", "nom": "Personnel", "icone": "👤", "couleur": "#4f46e5", "isSystem": false },
  "account": { "id": "uuid", "nom": "Compte Courant", "icone": "🏦", "couleur": "#f59e0b", "currency": "EUR" },
  "includeInBalance": true,
  "reminderDate": "2026-03-20",
  "reminderTime": "09:00"
}
```
