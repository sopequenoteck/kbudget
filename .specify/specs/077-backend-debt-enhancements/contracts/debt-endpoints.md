# API Contracts: Debt Enhancements

**Base path**: `/api/debts`

## Endpoints existants modifiés

### POST /debts — Créer une dette

**Request** (DebtRequest enrichi):
```json
{
  "personne": "Alice",
  "montant": 500.00,
  "sens": "EMPRUNT",
  "date": "2026-03-09",
  "categoryId": "uuid-category",
  "currency": "EUR",
  "accountId": "uuid-account",
  "includeInBalance": false,
  "reminderDate": "2026-03-15",
  "reminderTime": "14:00"
}
```

**Response** (201 — DebtResponse enrichi):
```json
{
  "id": "uuid-debt",
  "personne": "Alice",
  "montant": 500.00,
  "sens": "EMPRUNT",
  "date": "2026-03-09",
  "dueDate": null,
  "currency": "EUR",
  "rembourse": false,
  "montantRestant": 500.00,
  "category": { "id": "uuid", "nom": "Dette", "icone": "...", "couleur": "#..." },
  "account": { "id": "uuid-account", "nom": "Compte courant", "icone": "...", "couleur": "#...", "currency": "EUR" },
  "includeInBalance": false,
  "reminderDate": "2026-03-15",
  "reminderTime": "14:00:00"
}
```

**Règles**:
- Si `accountId` fourni → `currency` forcé à `account.currency` (ignore le champ `currency` du request)
- Si `accountId` null → `currency` = valeur du request ou devise principale utilisateur
- `includeInBalance` ignoré si `accountId` non null
- `reminderDate` et `reminderTime` doivent être fournis ensemble ou absents ensemble

### GET /debts — Lister les dettes

Inchangé dans l'interface. La réponse inclut les nouveaux champs (`account`, `includeInBalance`, `reminderDate`, `reminderTime`, `montantRestant`).

### GET /debts/{id} — Détail d'une dette

Inchangé dans l'interface. Réponse enrichie avec les nouveaux champs.

### PUT /debts/{id} — Modifier une dette

Request et réponse identiques à POST. Règles supplémentaires :
- Si `accountId` change vers un compte avec devise différente → conversion du montant via `ExchangeRateService`
- Si `accountId` passe de non-null à null → devise conservée (pas de reconversion)

### DELETE /debts/{id} — Supprimer une dette

Inchangé. Les transactions de remboursement sont conservées (`debt_id` mis à NULL par la FK `ON DELETE SET NULL`).

---

## Nouveaux endpoints

### POST /debts/{id}/repay — Rembourser une dette

**Request** (DebtRepayRequest):
```json
{
  "accountId": "uuid-account",
  "amount": 200.00
}
```

**Response** (200 — DebtResponse):
```json
{
  "id": "uuid-debt",
  "personne": "Alice",
  "montant": 500.00,
  "montantRestant": 300.00,
  "rembourse": false,
  "..."
}
```

**Règles**:
- `accountId` obligatoire, doit être un compte actif appartenant à l'utilisateur
- `amount` optionnel : si absent, rembourse la totalité du montant restant
- Si `amount > montantRestant` → 400 Bad Request
- Si dette déjà remboursée (`montantRestant = 0`) → 400 Bad Request
- Crée une Transaction avec :
  - `libelle` = `Remboursement - {personne}`
  - `type` = DEPENSE (si EMPRUNT) ou RECETTE (si PRET)
  - `category` = dette.category
  - `account` = compte source
  - `debt` = dette liée
  - `date` = aujourd'hui

**Erreurs**:
| Code | Condition |
|------|-----------|
| 400 | Montant dépasse le restant |
| 400 | Dette déjà remboursée |
| 400 | Compte inactif |
| 404 | Dette ou compte introuvable |

### GET /debts/{id}/payments — Historique des remboursements

**Response** (200 — List\<DebtPaymentResponse\>):
```json
[
  {
    "id": "uuid-transaction",
    "amount": 200.00,
    "date": "2026-03-10",
    "accountName": "Compte courant"
  }
]
```

**Règles**:
- Retourne toutes les transactions où `debt_id = {id}`
- Trié par date décroissante

### POST /debts/{id}/snooze — Reporter un rappel

**Request** (DebtSnoozeRequest):
```json
{
  "reminderDate": "2026-03-20",
  "reminderTime": "14:00"
}
```

**Response** (200 — DebtResponse):
```json
{
  "..."
  "reminderDate": "2026-03-20",
  "reminderTime": "14:00:00"
}
```

**Règles**:
- La dette DOIT avoir un rappel existant (sinon 400)
- `reminderDate` doit être >= aujourd'hui

**Erreurs**:
| Code | Condition |
|------|-----------|
| 400 | Pas de rappel existant |
| 400 | Date dans le passé |
| 404 | Dette introuvable |

---

## Nouvel endpoint Account

### GET /accounts/total-balance — Patrimoine total

**Response** (200 — TotalBalanceResponse):
```json
{
  "balances": [
    { "currency": "EUR", "amount": 15420.50 },
    { "currency": "USD", "amount": 2300.00 }
  ]
}
```

**Calcul**:
1. Pour chaque devise : somme des soldes (soldeInitial + transactions) de tous les comptes actifs
2. Ajustement par TOUTES les dettes non remboursées :
   - Dettes avec compte → automatiquement incluses
   - Dettes sans compte → incluses uniquement si `includeInBalance = true`
   - EMPRUNT → soustrait le montant restant
   - PRET → ajoute le montant restant
3. Groupé par devise, trié par devise principale en premier
