# API Contract: Debts (multi-currency)

## Modifications aux endpoints existants

### POST /api/debts — Créer une dette

**Request** (DebtRequest modifié) :
```json
{
  "personne": "Jean",
  "montant": 15000,
  "sens": "EMPRUNT",
  "date": "2026-02-17",
  "rembourse": false,
  "categoryId": "uuid-or-null",
  "currency": "XOF"           // NEW - optionnel, défaut = user.defaultCurrency
}
```

**Response** (DebtResponse modifié) :
```json
{
  "id": "uuid",
  "personne": "Jean",
  "montant": 15000,
  "sens": "EMPRUNT",
  "date": "2026-02-17",
  "rembourse": false,
  "category": { "id": "uuid", "nom": "Dette", "icone": "💰", "couleur": "#ef4444", "isSystem": true },
  "currency": "XOF"           // NEW
}
```

**Règles** :
- Si `currency` absent → `user.defaultCurrency`
- `currency` modifiable sur PUT (contrairement aux comptes)

### PUT /api/debts/{id} — Modifier une dette

**Request** : `currency` inclus et modifiable.

### GET /api/debts — Lister les dettes

**Response** : Chaque `DebtResponse` inclut `currency`.

### GET /api/debts/{id} — Détail dette

**Response** : `DebtResponse` avec `currency`.
