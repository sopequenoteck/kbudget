# Budget API — Exemples de requetes

Exemples de payloads (request/response) pour chaque endpoint. Toutes les routes (sauf auth) necessitent un header `Authorization: Bearer <token>`.

## Authentification

### Inscription `POST /api/auth/register`

Request :

```json
{
  "email": "user@example.com",
  "password": "secret123",
  "name": "Kelly",
  "currency": "XOF",
  "timezone": "Africa/Lome"
}
```

> `currency` et `timezone` sont optionnels. Defauts : `EUR` et `Europe/Paris`.

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

### Lister `GET /api/transactions?month=2&year=2026`

Parametres optionnels : `month` et `year` pour filtrer par mois.

Response `200` :

```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "montant": 42.50,
    "libelle": "Courses Carrefour",
    "type": "DEPENSE",
    "date": "2026-02-07",
    "category": { "id": "uuid", "nom": "Alimentation", "icone": "🛒", "couleur": "#4CAF50", "isSystem": false },
    "note": null,
    "account": { "id": "uuid", "nom": "Compte Principal", "icone": "🏦", "couleur": "#3b82f6" },
    "transferId": null,
    "debtId": null
  }
]
```

### Consulter `GET /api/transactions/{id}`

Response `200` : meme format qu'un element de la liste.

### Modifier `PUT /api/transactions/{id}`

Request : meme format que la creation.

Response `200` : la transaction mise a jour.

### Supprimer `DELETE /api/transactions/{id}`

Response `204` (corps vide).

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

### Consulter `GET /api/subscriptions/{id}`

Response `200` : meme format qu'un element de la liste.

### Supprimer `DELETE /api/subscriptions/{id}`

Response `204` (corps vide).

### Payer `POST /api/subscriptions/{id}/pay`

Response `201` :

```json
{
  "id": "uuid-transaction",
  "montant": 15.99,
  "date": "2026-03-30",
  "subscriptionName": "Netflix",
  "accountName": "Compte Principal"
}
```

### Historique paiements `GET /api/subscriptions/{id}/payments`

Response `200` :

```json
[
  {
    "id": "uuid-transaction",
    "montant": 15.99,
    "date": "2026-03-01",
    "subscriptionName": "Netflix",
    "accountName": "Compte Principal"
  }
]
```

### Cumul paiements `GET /api/subscriptions/{id}/payments/total`

Response `200` :

```json
{
  "total": 191.88
}
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
  "rembourse": false,
  "currency": "EUR",
  "accountId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "includeInBalance": true,
  "reminderDate": "2026-03-01",
  "reminderTime": "09:00"
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
  "dueDate": null,
  "currency": "EUR",
  "rembourse": false,
  "montantRestant": 50.00,
  "category": null,
  "account": { "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", "nom": "Compte Courant" },
  "includeInBalance": true,
  "reminderDate": "2026-03-01",
  "reminderTime": "09:00"
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
  "rembourse": true,
  "currency": "EUR",
  "accountId": null,
  "includeInBalance": false,
  "reminderDate": null,
  "reminderTime": null
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
  "dueDate": null,
  "currency": "EUR",
  "rembourse": true,
  "montantRestant": 0.00,
  "category": null,
  "account": null,
  "includeInBalance": false,
  "reminderDate": null,
  "reminderTime": null
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
    "dueDate": null,
    "currency": "EUR",
    "rembourse": false,
    "montantRestant": 30.00,
    "category": null,
    "account": { "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", "nom": "Compte Courant" },
    "includeInBalance": true,
    "reminderDate": "2026-03-01",
    "reminderTime": "09:00"
  }
]
```

### Rembourser `POST /api/debts/{id}/repay`

Request :

```json
{
  "accountId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "amount": 20.00
}
```

> `amount` optionnel — si omis, rembourse le montant restant (solde complet).

Response `200` : la dette mise a jour (meme format que ci-dessus, `montantRestant` recalcule, `rembourse: true` si solde).

### Historique paiements `GET /api/debts/{id}/payments`

Response `200` :

```json
[
  {
    "id": "f1a2b3c4-d5e6-7890-abcd-123456789012",
    "amount": 20.00,
    "date": "2026-02-15",
    "accountName": "Compte Courant"
  }
]
```

### Reporter le rappel `POST /api/debts/{id}/snooze`

Request :

```json
{
  "reminderDate": "2026-04-01",
  "reminderTime": "10:00"
}
```

Response `200` : la dette mise a jour avec les nouveaux `reminderDate` et `reminderTime`.

### Consulter `GET /api/debts/{id}`

Response `200` : meme format qu'un element de la liste.

### Supprimer `DELETE /api/debts/{id}`

Response `204` (corps vide).

### Solde total `GET /api/accounts/total-balance`

Response `200` :

```json
{
  "balances": [
    { "currency": "EUR", "amount": 3450.00 },
    { "currency": "XOF", "amount": 150000.00 }
  ]
}
```

> Agregation des soldes de tous les comptes actifs + dettes avec `includeInBalance=true`, par devise.

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
  "actif": true,
  "bankCode": "OTHER"
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
  "actif": true,
  "currency": "EUR",
  "bankCode": "OTHER",
  "bankName": "Autre",
  "bankCountry": null,
  "bankBrandColor": "#6b7280",
  "bankLogoUrl": "/api/bank-logos/other.svg",
  "bankCustomName": null,
  "bankCustomLogo": null
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
    "actif": true,
    "currency": "EUR",
    "bankCode": "OTHER",
    "bankName": "Autre",
    "bankCountry": null,
    "bankBrandColor": "#6b7280",
    "bankLogoUrl": "/api/bank-logos/other.svg",
    "bankCustomName": null,
    "bankCustomLogo": null
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
    "actif": true,
    "currency": "EUR",
    "bankCode": "OTHER",
    "bankName": "Autre",
    "bankCountry": null,
    "bankBrandColor": "#6b7280",
    "bankLogoUrl": "/api/bank-logos/other.svg",
    "bankCustomName": null,
    "bankCustomLogo": null
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

### Consulter `GET /api/accounts/{id}`

Response `200` : meme format qu'un element de la liste.

### Modifier `PUT /api/accounts/{id}`

Request : meme format que la creation.

Response `200` : le compte mis a jour.

### Supprimer `DELETE /api/accounts/{id}`

Response `204` (corps vide).

### Ajuster le solde `POST /api/accounts/{id}/adjust-balance`

Request :

```json
{
  "newBalance": 1500.00
}
```

Response `200` : le compte mis a jour avec le nouveau solde.

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
  "actif": true,
  "currency": "EUR",
  "bankCode": "OTHER",
  "bankName": "Autre",
  "bankCountry": null,
  "bankBrandColor": "#6b7280",
  "bankLogoUrl": "/api/bank-logos/other.svg",
  "bankCustomName": null,
  "bankCustomLogo": null
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

### Consulter `GET /api/categories/{id}`

Response `200` : meme format qu'un element de la liste.

### Modifier `PUT /api/categories/{id}`

Request : meme format que la creation.

Response `200` : la categorie mise a jour.

### Supprimer `DELETE /api/categories/{id}`

Response `204` (corps vide). Erreur `409` si categorie systeme.

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
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"],
  "currencies": ["EUR"]
}
```

### Mettre a jour `PUT /api/users/me/preferences`

Request (desactiver les dettes, navOrder auto-gere) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "BUDGETS"]
}
```

Response `200` :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "BUDGETS"],
  "navOrder": ["SUBSCRIPTIONS", "BUDGETS"],
  "currencies": ["EUR"]
}
```

Request (reordonner avec navOrder explicite + changer devise principale) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"],
  "navOrder": ["BUDGETS", "DEBTS", "SUBSCRIPTIONS"],
  "currencies": ["XOF", "EUR"]
}
```

Response `200` :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "BUDGETS"],
  "navOrder": ["BUDGETS", "DEBTS", "SUBSCRIPTIONS"],
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
  ],
  "unbudgetedItems": [
    {
      "categoryId": "uuid-category",
      "categoryNom": "Courses",
      "categoryIcone": "🛍️",
      "categoryCouleur": "#6b7280",
      "montantDepense": 45.00,
      "currency": "EUR"
    }
  ],
  "unbudgetedTotal": 45.00
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
  ],
  "unbudgetedItems": [
    {
      "categoryId": "uuid-category",
      "categoryNom": "Courses",
      "categoryIcone": "🛍️",
      "categoryCouleur": "#6b7280",
      "montantDepense": 52.30,
      "currency": "EUR"
    }
  ],
  "unbudgetedTotal": 52.30
}
```

## Banques

### Lister `GET /api/banks`

Endpoint public (pas de token requis). Retourne les 29 banques supportees, triees par pays (FR, TG, International) puis par nom.

Response `200` :

```json
[
  {
    "code": "BIA",
    "name": "BIA",
    "country": "FR",
    "brandColor": "#003366",
    "logoUrl": "/api/bank-logos/bia.svg"
  },
  {
    "code": "BNP",
    "name": "BNP Paribas",
    "country": "FR",
    "brandColor": "#00915a",
    "logoUrl": "/api/bank-logos/bnp.svg"
  },
  {
    "code": "ECOBANK",
    "name": "Ecobank",
    "country": "TG",
    "brandColor": "#0033a0",
    "logoUrl": "/api/bank-logos/ecobank.svg"
  },
  {
    "code": "OTHER",
    "name": "Autre",
    "country": null,
    "brandColor": "#6b7280",
    "logoUrl": "/api/bank-logos/other.svg"
  }
]
```

> 29 entrees au total. Extraits ci-dessus pour illustration.

## Transactions recurrentes

### Creer `POST /api/transactions/recurring`

Request :

```json
{
  "montant": 950.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "categoryId": "uuid-category",
  "accountId": "uuid-account",
  "note": null
}
```

Response `201` :

```json
{
  "id": "uuid",
  "montant": 950.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "recurringActive": true,
  "category": { "id": "uuid", "nom": "Logement", "icone": "🏠", "couleur": "#ef4444", "isSystem": false },
  "account": { "id": "uuid", "nom": "Compte Principal", "icone": "🏦", "couleur": "#3b82f6" }
}
```

### Lister les actives `GET /api/transactions/recurring`

Response `200` : liste de `RecurringTransactionResponse`.

### Valider une occurrence `POST /api/transactions/recurring/{id}/validate`

Cree la transaction pour l'occurrence courante et avance `nextOccurrence`.

Response `201` : `TransactionResponse` (la transaction creee).

### Passer une occurrence `PATCH /api/transactions/recurring/{id}/skip`

Avance `nextOccurrence` sans creer de transaction.

Response `200` : `RecurringTransactionResponse` mise a jour.

### Desactiver `PATCH /api/transactions/recurring/{id}/deactivate`

Response `200` : `RecurringTransactionResponse` avec `recurringActive: false`.

## Notifications

### Lister `GET /api/notifications?page=0&size=20&unread=true`

Parametres optionnels : `page` (defaut 0), `size` (defaut 20, max 100), `unread` (filtre optionnel).

Response `200` :

```json
{
  "content": [
    {
      "id": "uuid",
      "type": "SUBSCRIPTION_DUE",
      "title": "Echeance abonnement",
      "message": "Netflix arrive a echeance dans 3 jours",
      "entityType": "SUBSCRIPTION",
      "entityId": "uuid-subscription",
      "read": false,
      "readAt": null,
      "createdAt": "2026-03-27T08:00:00"
    }
  ],
  "number": 0,
  "size": 20,
  "totalElements": 5,
  "totalPages": 1
}
```

### Compteur non lues `GET /api/notifications/unread-count`

Response `200` :

```json
{
  "count": 3
}
```

### Marquer comme lue `PUT /api/notifications/{id}/read`

Response `200` : `NotificationResponse` avec `read: true` et `readAt` renseigne.

### Tout marquer comme lu `PUT /api/notifications/read-all`

Response `204` (corps vide).

### Supprimer `DELETE /api/notifications/{id}`

Response `204` (corps vide).

### Tout supprimer `DELETE /api/notifications`

Response `204` (corps vide).

## Profil utilisateur

### Consulter `GET /api/users/me`

Response `200` :

```json
{
  "name": "Kelly",
  "email": "user@example.com"
}
```

### Modifier `PUT /api/users/me`

Request :

```json
{
  "name": "Kelly K."
}
```

Response `200` :

```json
{
  "name": "Kelly K.",
  "email": "user@example.com"
}
```

## Devises

### Lister `GET /api/currencies`

Response `200` :

```json
[
  {
    "code": "EUR",
    "symbol": "€",
    "name": "Euro",
    "decimalPlaces": 2
  },
  {
    "code": "XOF",
    "symbol": "CFA",
    "name": "Franc CFA",
    "decimalPlaces": 0
  }
]
```

## Valeurs des enums

| Enum | Valeurs |
|------|---------|
| `TransactionType` | `DEPENSE`, `RECETTE` |
| `Frequency` | `HEBDOMADAIRE`, `MENSUEL`, `ANNUEL` |
| `DebtType` | `EMPRUNT`, `PRET` |
| `TokenStatus` | `ACTIVE`, `CONSUMED`, `REVOKED` |
| `AccountType` | `COURANT`, `EPARGNE`, `ESPECES` |
| `Feature` | `SUBSCRIPTIONS`, `DEBTS`, `BUDGETS` |
| `Currency` | `EUR`, `XOF`, `USD`, `GBP`, `CHF`, `CAD`, `MAD` |


## Import CSV

### Upload CSV `POST /api/imports/upload`

Request (multipart/form-data) :

| Champ | Type | Description |
|-------|------|-------------|
| `file` | File | Fichier CSV (max 5 Mo) |
| `accountId` | UUID | Compte cible |

Response `201` :

```json
{
  "id": "91afe691-...",
  "accountId": "36eace5f-...",
  "accountName": "Compte Principal",
  "status": "PENDING",
  "fileName": "releve_mars.csv",
  "totalLines": 160,
  "readyCount": 153,
  "reviewCount": 0,
  "duplicateCount": 7,
  "skippedCount": 0,
  "profileName": "Societe Generale",
  "profileSource": "REGISTRY",
  "createdAt": "2026-03-20T14:30:00",
  "expiresAt": "2026-03-27T14:30:00",
  "lines": [
    {
      "id": "uuid",
      "lineNumber": 1,
      "rawLabel": "CARTE X3855 16/03 UEP*SUPER U 101607535098170IOPD",
      "cleanLabel": "SUPER U",
      "amount": 17.32,
      "date": "2026-03-16",
      "transactionType": "DEPENSE",
      "status": "READY",
      "statusMessage": null,
      "categoryId": null,
      "categoryName": null,
      "duplicateTransactionId": null,
      "suggestRule": false
    }
  ]
}
```

Erreur `409` : brouillon actif existant pour ce compte.
Erreur `422` : format CSV non reconnu (utiliser `/imports/upload-with-mapping`).

### Confirmer import `POST /api/imports/drafts/{draftId}/confirm`

Response `200` :

```json
{
  "importedCount": 153,
  "skippedCount": 7,
  "historyId": "uuid"
}
```

Erreur `400` : lignes NEEDS_REVIEW ou DUPLICATE non resolues.

### Mettre a jour une ligne `PUT /api/imports/drafts/{draftId}/lines/{lineId}`

Request :

```json
{
  "categoryId": "uuid-categorie",
  "status": "READY"
}
```

### Actions groupees `PUT /api/imports/drafts/{draftId}/lines/batch`

Request :

```json
{
  "lineIds": ["uuid1", "uuid2", "uuid3"],
  "categoryId": "uuid-categorie",
  "status": "READY"
}
```

### Regles de categorisation `POST /api/imports/rules`

Request :

```json
{
  "pattern": "CARREFOUR",
  "categoryId": "uuid-categorie"
}
```

Response `201` :

```json
{
  "id": "uuid",
  "pattern": "CARREFOUR",
  "categoryId": "uuid-categorie",
  "categoryName": "Courses",
  "categoryIcon": "shopping-cart",
  "createdAt": "2026-03-20T14:30:00"
}
```

### Lister les regles `GET /api/imports/rules`

### Supprimer une regle `DELETE /api/imports/rules/{ruleId}` — `204`

### Preview CSV `POST /api/imports/preview`

Request (multipart/form-data) : `file` + optionnel `separator`, `encoding`, `skipHeaderLines`

Response `200` :

```json
{
  "headers": ["Date de l'operation", "Libelle", "Detail de l'ecriture", "Montant de l'operation", "Devise"],
  "rows": [["17/03/2026", "COTISATION MENSUEL", "COTISATION MENSUELLE SOBRIO", "-15,90", "EUR"]],
  "detectedSeparator": ";",
  "detectedEncoding": "ISO-8859-1",
  "totalRows": 160
}
```

### Upload avec mapping `POST /api/imports/upload-with-mapping`

Request (multipart/form-data) : `file`, `accountId`, `mapping` (JSON string)

### Consulter un brouillon `GET /api/imports/drafts/{draftId}`

Response `200` : meme format que la reponse de l'upload (avec toutes les lignes).

### Supprimer un brouillon `DELETE /api/imports/drafts/{draftId}`

Response `204` (corps vide).

### Modifier une regle `PUT /api/imports/rules/{ruleId}`

Request : meme format que la creation (`pattern`, `categoryId`).

Response `200` : la regle mise a jour.

### Lister brouillons `GET /api/imports/drafts` — liste des brouillons PENDING

### Historique `GET /api/imports/history?page=0&size=20` — imports finalises pagines

### Profils `GET /api/imports/profiles` — profils pre-configures + personnalises

### Supprimer profil `DELETE /api/imports/profiles/{profileId}` — `204`

## Voir aussi

- [`api-errors.md`](api-errors.md) — Contrat d'erreurs HTTP et format des reponses d'erreur
- **Swagger UI** : [http://localhost:8080/api/swagger-ui.html](http://localhost:8080/api/swagger-ui.html) — Documentation interactive (quand l'app tourne)
