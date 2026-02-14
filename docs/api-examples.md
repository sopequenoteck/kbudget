# Budget API — Exemples de requetes

Exemples de payloads (request/response) pour chaque endpoint. Toutes les routes (sauf auth) necessitent un header `Authorization: Bearer <token>`.

## Authentification

### Inscription `POST /api/auth/register`

Request :

```json
{
  "email": "user@example.com",
  "password": "secret123",
  "name": "Kelly"
}
```

Response `200` :

```json
{
  "token": "eyJhbGciOi...",
  "refreshToken": "a1b2c3d4e5f6...",
  "email": "user@example.com",
  "name": "Kelly"
}
```

### Connexion `POST /api/auth/login`

Request :

```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

Response `200` :

```json
{
  "token": "eyJhbGciOi...",
  "refreshToken": "a1b2c3d4e5f6...",
  "email": "user@example.com",
  "name": "Kelly"
}
```

### Renouvellement `POST /api/auth/refresh`

Request :

```json
{
  "refreshToken": "a1b2c3d4e5f6..."
}
```

Response `200` :

```json
{
  "token": "eyJhbGciOi...(nouveau)...",
  "refreshToken": "f6e5d4c3b2a1...(nouveau)...",
  "email": "user@example.com",
  "name": "Kelly"
}
```

### Deconnexion `POST /api/auth/logout`

Request :

```json
{
  "refreshToken": "a1b2c3d4e5f6..."
}
```

Response `200` : (corps vide)

## Transactions

### Creer `POST /api/transactions`

Request :

```json
{
  "montant": 42.50,
  "libelle": "Courses Carrefour",
  "type": "DEPENSE",
  "date": "2026-02-07",
  "categoryId": "c1d2e3f4-a5b6-7890-cdef-123456789abc",
  "note": null
}
```

Response `200` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "montant": 42.50,
  "libelle": "Courses Carrefour",
  "type": "DEPENSE",
  "date": "2026-02-07",
  "category": {
    "id": "c1d2e3f4-a5b6-7890-cdef-123456789abc",
    "nom": "Alimentation",
    "icone": "🛒",
    "couleur": "#4CAF50",
    "isSystem": false
  },
  "note": null
}
```

### Bilan mensuel `GET /api/transactions/summary?month=2&year=2026`

Response `200` :

```json
{
  "month": 2,
  "year": 2026,
  "totalRecettes": 2500.00,
  "totalDepenses": 1200.50,
  "solde": 1299.50
}
```

## Abonnements

### Creer `POST /api/subscriptions`

Request :

```json
{
  "nom": "Netflix",
  "montant": 13.49,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-15",
  "actif": true
}
```

Response `200` :

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "nom": "Netflix",
  "montant": 13.49,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-15",
  "actif": true
}
```

### Modifier `PUT /api/subscriptions/{id}`

Request :

```json
{
  "nom": "Netflix",
  "montant": 15.99,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-15",
  "actif": true
}
```

Response `200` :

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "nom": "Netflix",
  "montant": 15.99,
  "frequence": "MENSUEL",
  "dateDebut": "2026-01-15",
  "actif": true
}
```

### Lister `GET /api/subscriptions?actif=true`

Response `200` :

```json
[
  {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "nom": "Netflix",
    "montant": 15.99,
    "frequence": "MENSUEL",
    "dateDebut": "2026-01-15",
    "actif": true
  },
  {
    "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
    "nom": "Spotify",
    "montant": 10.99,
    "frequence": "MENSUEL",
    "dateDebut": "2025-06-01",
    "actif": true
  }
]
```

## Dettes

### Creer `POST /api/debts`

Request :

```json
{
  "personne": "Thomas",
  "montant": 50.00,
  "sens": "EMPRUNT",
  "date": "2026-02-01",
  "rembourse": false
}
```

Response `200` :

```json
{
  "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
  "personne": "Thomas",
  "montant": 50.00,
  "sens": "EMPRUNT",
  "date": "2026-02-01",
  "rembourse": false
}
```

### Modifier `PUT /api/debts/{id}`

Request :

```json
{
  "personne": "Thomas",
  "montant": 50.00,
  "sens": "EMPRUNT",
  "date": "2026-02-01",
  "rembourse": true
}
```

Response `200` :

```json
{
  "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
  "personne": "Thomas",
  "montant": 50.00,
  "sens": "EMPRUNT",
  "date": "2026-02-01",
  "rembourse": true
}
```

### Lister `GET /api/debts?rembourse=false`

Response `200` :

```json
[
  {
    "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
    "personne": "Thomas",
    "montant": 50.00,
    "sens": "EMPRUNT",
    "date": "2026-02-01",
    "rembourse": false
  },
  {
    "id": "e5f6a7b8-c9d0-1234-efab-345678901234",
    "personne": "Marie",
    "montant": 25.00,
    "sens": "PRET",
    "date": "2026-01-20",
    "rembourse": false
  }
]
```

## Categories

### Creer `POST /api/categories`

Request :

```json
{
  "nom": "Alimentation",
  "icone": "🛒",
  "couleur": "#4CAF50"
}
```

Response `200` :

```json
{
  "id": "c1d2e3f4-a5b6-7890-cdef-123456789abc",
  "nom": "Alimentation",
  "icone": "🛒",
  "couleur": "#4CAF50",
  "isSystem": false
}
```

### Lister `GET /api/categories`

Response `200` :

```json
[
  {
    "id": "c1d2e3f4-a5b6-7890-cdef-123456789abc",
    "nom": "Alimentation",
    "icone": "🛒",
    "couleur": "#4CAF50",
    "isSystem": false
  },
  {
    "id": "d2e3f4a5-b6c7-8901-defa-234567890bcd",
    "nom": "Transport",
    "icone": "🚗",
    "couleur": "#2196F3",
    "isSystem": true
  }
]
```

## Valeurs des enums

| Enum | Valeurs |
|------|---------|
| `TransactionType` | `DEPENSE`, `RECETTE` |
| `Frequency` | `MENSUEL`, `ANNUEL` |
| `DebtType` | `EMPRUNT`, `PRET` |
| `TokenStatus` | `ACTIVE`, `CONSUMED`, `REVOKED` |

## Voir aussi

- [`api-errors.md`](api-errors.md) — Contrat d'erreurs HTTP et format des reponses d'erreur
- **Swagger UI** : [http://localhost:8080/api/swagger-ui.html](http://localhost:8080/api/swagger-ui.html) — Documentation interactive (quand l'app tourne)
