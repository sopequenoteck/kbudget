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
  "note": null,
  "accountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890"
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
  "note": null,
  "account": {
    "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "nom": "Compte Principal",
    "icone": "🏦",
    "couleur": "#3b82f6"
  },
  "transferId": null
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
  "actif": true,
  "accountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890"
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
  "actif": true,
  "category": null,
  "account": {
    "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "nom": "Compte Principal",
    "icone": "🏦",
    "couleur": "#3b82f6"
  }
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
  "actif": true,
  "accountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890"
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
  "actif": true,
  "category": null,
  "account": {
    "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "nom": "Compte Principal",
    "icone": "🏦",
    "couleur": "#3b82f6"
  }
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
    "actif": true,
    "category": null,
    "account": {
      "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
      "nom": "Compte Principal",
      "icone": "🏦",
      "couleur": "#3b82f6"
    }
  },
  {
    "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
    "nom": "Spotify",
    "montant": 10.99,
    "frequence": "MENSUEL",
    "dateDebut": "2025-06-01",
    "actif": true,
    "category": null,
    "account": null
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

## Comptes

### Creer `POST /api/accounts`

Request :

```json
{
  "nom": "Livret A",
  "type": "EPARGNE",
  "soldeInitial": 1500.00,
  "icone": "🐷",
  "couleur": "#22c55e",
  "actif": true
}
```

Response `201` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-000000000001",
  "nom": "Livret A",
  "type": "EPARGNE",
  "soldeInitial": 1500.00,
  "solde": 1500.00,
  "icone": "🐷",
  "couleur": "#22c55e",
  "isDefault": false,
  "actif": true
}
```

### Lister `GET /api/accounts`

Response `200` :

```json
[
  {
    "id": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "nom": "Compte Principal",
    "type": "COURANT",
    "soldeInitial": 0.00,
    "solde": 1299.50,
    "icone": "🏦",
    "couleur": "#3b82f6",
    "isDefault": true,
    "actif": true
  },
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-000000000001",
    "nom": "Livret A",
    "type": "EPARGNE",
    "soldeInitial": 1500.00,
    "solde": 1500.00,
    "icone": "🐷",
    "couleur": "#22c55e",
    "isDefault": false,
    "actif": true
  }
]
```

### Virement `POST /api/accounts/transfer`

Request :

```json
{
  "fromAccountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
  "toAccountId": "a1b2c3d4-e5f6-7890-abcd-000000000001",
  "montant": 200.00,
  "note": "Epargne mensuelle"
}
```

Response `201` :

```json
{
  "transferId": "e5f6a7b8-c9d0-1234-efab-345678901234",
  "debitTransaction": {
    "id": "11111111-1111-1111-1111-111111111111",
    "montant": 200.00,
    "libelle": "Virement vers Livret A",
    "type": "DEPENSE",
    "date": "2026-02-15",
    "accountId": "f1a2b3c4-d5e6-7890-abcd-ef1234567890",
    "accountNom": "Compte Principal"
  },
  "creditTransaction": {
    "id": "22222222-2222-2222-2222-222222222222",
    "montant": 200.00,
    "libelle": "Virement depuis Compte Principal",
    "type": "RECETTE",
    "date": "2026-02-15",
    "accountId": "a1b2c3d4-e5f6-7890-abcd-000000000001",
    "accountNom": "Livret A"
  }
}
```

### Definir par defaut `PUT /api/accounts/{id}/default`

Response `200` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-000000000001",
  "nom": "Livret A",
  "type": "EPARGNE",
  "soldeInitial": 1500.00,
  "solde": 1700.00,
  "icone": "🐷",
  "couleur": "#22c55e",
  "isDefault": true,
  "actif": true
}
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

## Produits

### Creer `POST /api/products`

Request :

```json
{
  "nom": "T-shirt personnalise",
  "description": "T-shirt 100% coton, impression personnalisee",
  "icone": "👕",
  "imageUrl": "https://example.com/tshirt.jpg",
  "prixAchat": 8.50,
  "prixVente": 15.00,
  "stock": 25
}
```

Response `201` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "nom": "T-shirt personnalise",
  "description": "T-shirt 100% coton, impression personnalisee",
  "icone": "👕",
  "imageUrl": "https://example.com/tshirt.jpg",
  "prixAchat": 8.50,
  "prixVente": 15.00,
  "stock": 25,
  "totalVendu": 0,
  "actif": true,
  "createdAt": "2026-02-28T10:30:00",
  "updatedAt": "2026-02-28T10:30:00"
}
```

### Lister `GET /api/products`

Parametre optionnel : `?includeInactive=true` pour inclure les produits desactives (defaut `false`).

Response `200` (tries par date de creation decroissante) :

```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "nom": "T-shirt personnalise",
    "description": "T-shirt 100% coton",
    "icone": "👕",
    "imageUrl": null,
    "prixAchat": 8.50,
    "prixVente": 15.00,
    "stock": 25,
    "totalVendu": 3,
    "actif": true,
    "createdAt": "2026-02-28T10:30:00",
    "updatedAt": "2026-02-28T12:00:00"
  }
]
```

### Modifier `PUT /api/products/{id}`

Request (remplacement complet, champ `actif` obligatoire) :

```json
{
  "nom": "T-shirt personnalise v2",
  "description": "T-shirt bio",
  "icone": "👕",
  "imageUrl": "https://example.com/tshirt-v2.jpg",
  "prixAchat": 9.00,
  "prixVente": 18.00,
  "stock": 50,
  "actif": true
}
```

### Vendre `POST /api/products/{id}/sell`

Request (body optionnel, defaut `quantity: 1`) :

```json
{
  "quantity": 3
}
```

Response `200` : le produit mis a jour (stock decremente, totalVendu incremente).

### Supprimer `DELETE /api/products/{id}`

Response `204` (corps vide, suppression physique).

## Taux de conversion

### Lister `GET /api/exchange-rates`

Response `200` :

```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "baseCurrency": "EUR",
    "targetCurrency": "XOF",
    "rate": 655.957000,
    "updatedAt": "2026-03-06T10:00:00"
  }
]
```

### Creer ou mettre a jour `PUT /api/exchange-rates`

Request (upsert — cree ou met a jour le taux pour la paire) :

```json
{
  "baseCurrency": "EUR",
  "targetCurrency": "XOF",
  "rate": 655.957
}
```

Response `200` :

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "baseCurrency": "EUR",
  "targetCurrency": "XOF",
  "rate": 655.957000,
  "updatedAt": "2026-03-06T10:00:00"
}
```

### Supprimer `DELETE /api/exchange-rates/{baseCurrency}/{targetCurrency}`

Response `204` (corps vide).

## Preferences utilisateur

### Consulter `GET /api/users/me/preferences`

Response `200` (valeurs par defaut) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "shopAccountId": null,
  "includeShopInBalance": false,
  "currencies": ["EUR"]
}
```

### Mettre a jour `PUT /api/users/me/preferences`

Request (desactiver les dettes, navOrder auto-gere) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "SHOP"]
}
```

Response `200` :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "SHOP"],
  "shopAccountId": null,
  "includeShopInBalance": false,
  "currencies": ["EUR"]
}
```

Request (reordonner avec navOrder explicite + changer devise principale) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SHOP", "DEBTS", "SUBSCRIPTIONS"],
  "currencies": ["XOF", "EUR"]
}
```

Response `200` :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SHOP", "DEBTS", "SUBSCRIPTIONS"],
  "shopAccountId": null,
  "includeShopInBalance": false,
  "currencies": ["XOF", "EUR"]
}
```

## Budgets

### Creer `POST /api/budgets`

Request :

```json
{
  "categoryId": "uuid-category",
  "montant": 400.00,
  "frequence": "MENSUEL",
  "currency": "EUR",
  "seuilNotification": 80
}
```

Response `200` :

```json
{
  "id": "uuid-budget",
  "montant": 400.00,
  "currency": "EUR",
  "frequence": "MENSUEL",
  "seuilNotification": 80,
  "actif": true,
  "category": {
    "id": "uuid-category",
    "nom": "Alimentation",
    "icone": "🛒",
    "couleur": "#f59e0b",
    "isSystem": false
  },
  "spent": 0.00,
  "updatedAt": "2026-03-08T10:00:00"
}
```

### Lister `GET /api/budgets`

Response `200` :

```json
[
  {
    "id": "uuid-budget",
    "montant": 400.00,
    "currency": "EUR",
    "frequence": "MENSUEL",
    "seuilNotification": 80,
    "actif": true,
    "category": { "id": "uuid", "nom": "Alimentation", "icone": "🛒", "couleur": "#f59e0b", "isSystem": false },
    "spent": 320.50,
    "updatedAt": "2026-03-08T10:00:00"
  }
]
```

### Consulter `GET /api/budgets/{id}`

Response `200` : meme format qu'un element de la liste.

### Modifier `PUT /api/budgets/{id}`

Request : meme format que la creation (tous les champs optionnels sauf `categoryId`).

### Supprimer `DELETE /api/budgets/{id}`

Response `204` (pas de corps).

### Vue mensuelle `GET /api/budgets/overview`

Response `200` :

```json
{
  "month": "2026-03",
  "totalBudget": 1500.00,
  "totalSpent": 980.50,
  "percentage": 65.37,
  "currency": "EUR",
  "items": [
    {
      "budgetId": "uuid-budget",
      "categoryId": "uuid-category",
      "categoryNom": "Alimentation",
      "categoryIcone": "🛒",
      "categoryCouleur": "#f59e0b",
      "montantBudget": 400.00,
      "montantBudgetNormalise": 400.00,
      "currency": "EUR",
      "montantDepense": 320.50,
      "percentage": 80.13,
      "frequence": "MENSUEL"
    }
  ]
}
```

### Historique `GET /api/budgets/history?month=2026-02`

Response `200` :

```json
{
  "month": "2026-02",
  "totalBudget": 1500.00,
  "totalSpent": 1200.00,
  "percentage": 80.00,
  "currency": "EUR",
  "items": [
    {
      "categoryId": "uuid-category",
      "categoryNom": "Alimentation",
      "categoryIcone": "🛒",
      "categoryCouleur": "#f59e0b",
      "montantBudget": 400.00,
      "currency": "EUR",
      "tauxChange": null,
      "montantDepense": 380.00,
      "percentage": 95.00,
      "createdAt": "2026-03-01T00:00:00"
    }
  ]
}
```

## Valeurs des enums

| Enum | Valeurs |
|------|---------|
| `TransactionType` | `DEPENSE`, `RECETTE` |
| `Frequency` | `HEBDOMADAIRE`, `MENSUEL`, `ANNUEL` |
| `DebtType` | `EMPRUNT`, `PRET` |
| `TokenStatus` | `ACTIVE`, `CONSUMED`, `REVOKED` |
| `AccountType` | `COURANT`, `EPARGNE`, `ESPECES` |
| `Feature` | `SUBSCRIPTIONS`, `DEBTS`, `SHOP`, `BUDGETS` |
| `Currency` | `EUR`, `XOF`, `USD`, `GBP`, `CHF`, `CAD`, `MAD` |

## Voir aussi

- [`api-errors.md`](api-errors.md) — Contrat d'erreurs HTTP et format des reponses d'erreur
- **Swagger UI** : [http://localhost:8080/api/swagger-ui.html](http://localhost:8080/api/swagger-ui.html) — Documentation interactive (quand l'app tourne)
