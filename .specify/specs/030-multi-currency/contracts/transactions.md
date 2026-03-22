# API Contract: Transactions (multi-currency)

## Modifications aux endpoints existants

### GET /api/transactions — Lister les transactions

**Response** : Chaque `TransactionResponse` contient un `AccountSummary` enrichi avec `currency`.

```json
{
  "id": "uuid",
  "montant": 15000,
  "libelle": "Courses marché",
  "type": "DEPENSE",
  "date": "2026-02-17",
  "category": { ... },
  "note": null,
  "account": {
    "id": "uuid",
    "nom": "Compte Togo",
    "icone": "🏦",
    "couleur": "#3b82f6",
    "currency": "XOF"         // NEW (via AccountSummary)
  },
  "transferId": null
}
```

**Note** : La transaction n'a pas de champ `currency` propre. La devise est déduite de `account.currency`.

### POST /api/transactions — Créer une transaction

**Request** : Inchangé (pas de champ currency). La devise est celle du compte cible.

### GET /api/transactions/summary — Résumé mensuel

**Breaking change** : La réponse passe de `MonthlySummary` (objet) à `List<MonthlySummary>` (tableau).

**Avant** :
```json
{
  "month": 2,
  "year": 2026,
  "totalRecettes": 3000,
  "totalDepenses": 2500,
  "solde": 500
}
```

**Après** :
```json
[
  {
    "currency": "EUR",
    "month": 2,
    "year": 2026,
    "totalRecettes": 3000.00,
    "totalDepenses": 2500.00,
    "solde": 500.00
  },
  {
    "currency": "XOF",
    "month": 2,
    "year": 2026,
    "totalRecettes": 500000,
    "totalDepenses": 300000,
    "solde": 200000
  }
]
```

**Règles** :
- Groupement par `account.currency` via JOIN
- Seules les devises avec au moins une transaction dans le mois apparaissent
- Ordre : devise par défaut de l'utilisateur en premier, puis alphabétique
