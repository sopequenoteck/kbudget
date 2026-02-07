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
  "email": "user@example.com",
  "name": "Kelly"
}
```

## Transactions

### Creer `POST /api/transactions`

Request :

```json
{
  "montant": 42.50,
  "libelle": "Courses Carrefour",
  "type": "DEPENSE",
  "date": "2026-02-07",
  "categorie": "Alimentation",
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
  "categorie": "Alimentation",
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
  "sens": "JE_DOIS",
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
  "sens": "JE_DOIS",
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
  "sens": "JE_DOIS",
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
  "sens": "JE_DOIS",
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
    "sens": "JE_DOIS",
    "date": "2026-02-01",
    "rembourse": false
  },
  {
    "id": "e5f6a7b8-c9d0-1234-efab-345678901234",
    "personne": "Marie",
    "montant": 25.00,
    "sens": "ON_ME_DOIT",
    "date": "2026-01-20",
    "rembourse": false
  }
]
```

## Valeurs des enums

| Enum | Valeurs |
|------|---------|
| `TransactionType` | `DEPENSE`, `RECETTE` |
| `Frequency` | `MENSUEL`, `ANNUEL` |
| `DebtType` | `JE_DOIS`, `ON_ME_DOIT` |

## Voir aussi

- [`api-errors.md`](api-errors.md) — Contrat d'erreurs HTTP et format des reponses d'erreur
- **Swagger UI** : [http://localhost:8080/api/swagger-ui.html](http://localhost:8080/api/swagger-ui.html) — Documentation interactive (quand l'app tourne)
