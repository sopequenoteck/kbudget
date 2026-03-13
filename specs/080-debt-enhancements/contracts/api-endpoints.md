# API Contracts: 080-debt-enhancements

Base path: `/api`

## Endpoints

### POST /debts

Créer une dette.

**Request**: `DebtRequest`
```json
{
  "personne": "Paul",
  "montant": 200.00,
  "sens": "EMPRUNT",
  "date": "2026-03-10",
  "currency": "EUR",
  "categoryId": "uuid",
  "accountId": "uuid|null",
  "includeInBalance": false,
  "reminderDate": "2026-03-15|null",
  "reminderTime": "10:00|null",
  "rembourse": false
}
```

> **Note** : Le champ `rembourse` est ignoré côté serveur — le marquage est automatique quand le montant restant atteint zéro (FR-004).

**Response**: `201 Created` → `DebtResponse`

---

### GET /debts

Lister toutes les dettes de l'utilisateur.

**Query params**: `?rembourse=false` (optionnel, filtre dettes non remboursées)

**Response**: `200 OK` → `DebtResponse[]`

---

### GET /debts/{id}

Détail d'une dette.

**Response**: `200 OK` → `DebtResponse`

---

### PUT /debts/{id}

Modifier une dette.

**Request**: `DebtRequest` (même format que POST)

**Response**: `200 OK` → `DebtResponse`

**Erreurs**:
- `400` : taux de change indisponible lors d'une association tardive à un compte avec devise différente

---

### DELETE /debts/{id}

Supprimer une dette. Les transactions liées sont détachées (debt_id = null).

**Response**: `204 No Content`

---

### POST /debts/{id}/repay

Enregistrer un remboursement (partiel ou total).

**Request**: `DebtRepayRequest`
```json
{
  "accountId": "uuid",
  "amount": 50.00
}
```
- `amount` optionnel : si null, rembourse le montant restant total
- `amount` doit être > 0 et <= montantRestant

**Response**: `200 OK` → `DebtResponse` (avec montantRestant mis à jour)

**Erreurs**:
- `400` : montant > restant, dette déjà remboursée, compte inactif, montant = 0
- `404` : dette non trouvée

---

### GET /debts/{id}/payments

Historique des paiements d'une dette.

**Response**: `200 OK` → `DebtPaymentResponse[]`
```json
[
  {
    "id": "uuid",
    "amount": 50.00,
    "date": "2026-03-12",
    "accountName": "Compte Courant"
  }
]
```

---

### POST /debts/{id}/snooze

Reporter un rappel de dette.

**Request**: `DebtSnoozeRequest`
```json
{
  "reminderDate": "2026-03-20",
  "reminderTime": "14:00"
}
```
- `reminderDate` doit être futur ou présent

**Response**: `200 OK` → `DebtResponse`

**Erreurs**:
- `400` : aucun rappel existant sur la dette
- `404` : dette non trouvée

---

### GET /accounts/total-balance

Solde total agrégé par devise (comptes + dettes éligibles).

**Response**: `200 OK` → `TotalBalanceResponse`
```json
{
  "balances": [
    { "currency": "EUR", "amount": 1500.00 },
    { "currency": "USD", "amount": 200.00 }
  ]
}
```

**Logique d'agrégation**:
- Somme des soldes de tous les comptes actifs par devise
- \+ dettes de type PRET éligibles (remainingAmount)
- \- dettes de type EMPRUNT éligibles (remainingAmount)
- Éligible = dette avec compte OU includeInBalance = true

---

## DebtResponse (format commun)

```json
{
  "id": "uuid",
  "personne": "Paul",
  "montant": 200.00,
  "sens": "EMPRUNT",
  "date": "2026-03-10",
  "currency": "EUR",
  "currencyName": "Euro",
  "rembourse": false,
  "montantRestant": 150.00,
  "categoryId": "uuid",
  "categoryName": "Divers",
  "accountId": "uuid|null",
  "accountName": "Compte Courant|null",
  "includeInBalance": false,
  "dueDate": "2026-04-10|null",
  "reminderDate": "2026-03-15|null",
  "reminderTime": "10:00|null",
  "updatedAt": "2026-03-10T12:00:00"
}
```
