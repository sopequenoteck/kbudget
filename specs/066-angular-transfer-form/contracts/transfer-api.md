# API Contract: Transfer

**Endpoint existant** — documenté ici pour référence frontend.

## POST /api/accounts/transfer

Effectue un virement atomique entre deux comptes de l'utilisateur authentifié.

### Request

**Headers**:
- `Authorization: Bearer <JWT>`
- `Content-Type: application/json`

**Body**:
```json
{
  "fromAccountId": "uuid",
  "toAccountId": "uuid",
  "montant": 150.00,
  "note": "Épargne mensuelle"
}
```

**Validation serveur**:
- `fromAccountId` : requis, UUID valide, compte existant et appartenant à l'utilisateur
- `toAccountId` : requis, UUID valide, compte existant et appartenant à l'utilisateur, ≠ fromAccountId
- `montant` : requis, >= 0.01
- `note` : optionnel, max 500 caractères

### Response — 200 OK

```json
{
  "transferId": "uuid",
  "debitTransaction": {
    "id": "uuid",
    "montant": 150.00,
    "type": "DEPENSE"
  },
  "creditTransaction": {
    "id": "uuid",
    "montant": 150.00,
    "type": "RECETTE"
  }
}
```

### Response — 400 Bad Request

Validation échouée (même compte, montant invalide, etc.).

```json
{
  "status": 400,
  "message": "Les comptes source et destination doivent être différents"
}
```

### Response — 404 Not Found

Compte introuvable ou n'appartenant pas à l'utilisateur.

```json
{
  "status": 404,
  "message": "Compte introuvable"
}
```

### Response — 401 Unauthorized

JWT absent ou expiré.
