# API Contracts: Account Endpoints

**Base URL**: `/api/accounts`
**Auth**: JWT Bearer token (obligatoire)

## Endpoints consommés par cette feature

### GET /accounts

Liste tous les comptes de l'utilisateur authentifié (actifs + inactifs).

**Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "nom": "Compte Principal",
    "type": "COURANT",
    "soldeInitial": 0.00,
    "solde": 1250.50,
    "icone": "🏦",
    "couleur": "#3b82f6",
    "isDefault": true,
    "actif": true,
    "currency": "EUR"
  }
]
```

### POST /accounts

Crée un nouveau compte.

**Request**:
```json
{
  "nom": "Épargne vacances",
  "type": "EPARGNE",
  "soldeInitial": 500.00,
  "icone": "🐷",
  "couleur": "#22c55e",
  "actif": true,
  "currency": "EUR"
}
```

**Response** `200 OK`: AccountResponse (même format que GET)

**Erreurs**:
- `400` : Validation (nom vide, > 50 car., couleur invalide)
- `409` : Nom déjà utilisé (case-insensitive, comptes actifs)

### PUT /accounts/{id}

Met à jour un compte existant. `soldeInitial` et `currency` ignorés.

**Request**: même format que POST (type ignoré)

**Response** `200 OK`: AccountResponse

**Erreurs**:
- `400` : Validation / tentative de désactiver le compte par défaut
- `404` : Compte non trouvé
- `409` : Nom déjà utilisé

### DELETE /accounts/{id}

Supprime physiquement un compte.

**Response** `204 No Content`

**Erreurs**:
- `400` : Compte par défaut / compte avec transactions ou abonnements liés
- `404` : Compte non trouvé

### PUT /accounts/{id}/default

Définit le compte comme compte par défaut.

**Request**: body vide

**Response** `200 OK`: AccountResponse (avec `isDefault: true`)

**Erreurs**:
- `400` : Compte inactif
- `404` : Compte non trouvé

### POST /accounts/{id}/adjust-balance

Ajuste le solde du compte en créant une transaction d'ajustement.

**Request**:
```json
{
  "newBalance": 1500.00
}
```

**Response** `200 OK`: AccountResponse (avec nouveau `solde`)

**Erreurs**:
- `404` : Compte non trouvé

**Note**: Si `newBalance` == `solde` actuel, l'API retourne le compte sans créer de transaction.
