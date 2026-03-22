# API Client Contract: Flutter → Spring Boot Backend

**Date**: 2026-02-18
**Base URL**: `{serverUrl}/api` (configurable via `--dart-define`)

## Authentication

### POST /auth/login
**Request**:
```json
{
  "email": "string (required, email format)",
  "password": "string (required)"
}
```
**Response 200**:
```json
{
  "token": "string (JWT access token, 15min)",
  "refreshToken": "string (30 days)",
  "email": "string",
  "name": "string?"
}
```
**Errors**: 401 (invalid credentials)

### POST /auth/register
**Request**:
```json
{
  "email": "string (required, email format)",
  "password": "string (required, min 6 chars)",
  "name": "string? (max 100)"
}
```
**Response 201**: Same as login response
**Errors**: 409 (email already exists)

### POST /auth/refresh
**Request**:
```json
{
  "refreshToken": "string (required)"
}
```
**Response 200**: Same as login response (new tokens)
**Errors**: 401 (invalid/expired/revoked token)

### POST /auth/logout
**Request**:
```json
{
  "refreshToken": "string (required)"
}
```
**Response 204**: No content
**Errors**: 401 (invalid token)

---

## User

### GET /users/me
**Response 200**:
```json
{
  "name": "string?",
  "email": "string",
  "defaultCurrency": "string (enum name: EUR, XOF, ...)"
}
```

### PUT /users/me
**Request**:
```json
{
  "defaultCurrency": "string (required, enum name)"
}
```
**Response 200**: UserResponse

---

## Accounts

### GET /accounts
**Query**: `?includeInactive=false` (default)
**Response 200**: `AccountResponse[]`
```json
{
  "id": "uuid",
  "nom": "string",
  "type": "COURANT | EPARGNE | ESPECES",
  "soldeInitial": "decimal",
  "solde": "decimal (calculated)",
  "icone": "string (emoji)",
  "couleur": "string (hex)",
  "isDefault": "boolean",
  "actif": "boolean",
  "currency": "string (enum name)"
}
```

### POST /accounts
**Request**:
```json
{
  "nom": "string (required, 1-50)",
  "type": "COURANT | EPARGNE | ESPECES (required)",
  "soldeInitial": "decimal?",
  "icone": "string?",
  "couleur": "string? (hex pattern)",
  "actif": "boolean?",
  "currency": "string? (enum name)"
}
```
**Response 201**: AccountResponse

### PUT /accounts/{id}
**Request**: Same as POST
**Response 200**: AccountResponse

### DELETE /accounts/{id}
**Response 204**: No content

### POST /accounts/transfer
**Request**:
```json
{
  "fromAccountId": "uuid (required)",
  "toAccountId": "uuid (required)",
  "montant": "decimal (required, min 0.01)",
  "note": "string? (max 500)"
}
```
**Response 201**: TransferResponse

### PUT /accounts/{id}/default
**Response 200**: AccountResponse

---

## Categories

### GET /categories
**Response 200**: `CategoryResponse[]`
```json
{
  "id": "uuid",
  "nom": "string",
  "icone": "string",
  "couleur": "string (hex)",
  "isSystem": "boolean"
}
```

### POST /categories
**Request**:
```json
{
  "nom": "string (required, max 30)",
  "icone": "string (required, max 50)",
  "couleur": "string (required, max 7, hex)"
}
```
**Response 201**: CategoryResponse

### PUT /categories/{id}
**Request**: Same as POST
**Response 200**: CategoryResponse

### DELETE /categories/{id}
**Response 204**: No content

---

## Transactions

### GET /transactions
**Response 200**: `TransactionResponse[]`
```json
{
  "id": "uuid",
  "montant": "decimal",
  "libelle": "string",
  "type": "DEPENSE | RECETTE",
  "date": "YYYY-MM-DD",
  "category": "CategoryResponse?",
  "note": "string?",
  "account": { "id": "uuid", "nom": "string", "icone": "string", "couleur": "string", "currency": "string" },
  "transferId": "uuid?"
}
```

### GET /transactions/summary
**Query**: `?month=X&year=Y`
**Response 200**: `MonthlySummaryResponse[]`
```json
{
  "month": "int",
  "year": "int",
  "totalRecettes": "decimal",
  "totalDepenses": "decimal",
  "solde": "decimal",
  "currency": "string"
}
```

### POST /transactions
**Request**:
```json
{
  "montant": "decimal (required, positive)",
  "libelle": "string (required, max 255)",
  "type": "DEPENSE | RECETTE (required)",
  "date": "YYYY-MM-DD (required)",
  "categoryId": "uuid?",
  "note": "string? (max 500)",
  "accountId": "uuid?"
}
```
**Response 201**: TransactionResponse

### PUT /transactions/{id}
**Request**: Same as POST
**Response 200**: TransactionResponse

### DELETE /transactions/{id}
**Response 204**: No content

---

## Subscriptions

### GET /subscriptions
**Query**: `?actif=true|false` (optional)
**Response 200**: `SubscriptionResponse[]`
```json
{
  "id": "uuid",
  "nom": "string",
  "montant": "decimal",
  "frequence": "MENSUEL | ANNUEL",
  "dateDebut": "YYYY-MM-DD",
  "actif": "boolean",
  "category": "CategoryResponse?",
  "account": "AccountSummary?",
  "currency": "string"
}
```

### POST /subscriptions
**Request**:
```json
{
  "nom": "string (required, max 255)",
  "montant": "decimal (required, positive)",
  "frequence": "MENSUEL | ANNUEL (required)",
  "dateDebut": "YYYY-MM-DD (required)",
  "actif": "boolean?",
  "categoryId": "uuid?",
  "accountId": "uuid?",
  "currency": "string?"
}
```
**Response 201**: SubscriptionResponse

### PUT /subscriptions/{id}
**Request**: Same as POST
**Response 200**: SubscriptionResponse

### DELETE /subscriptions/{id}
**Response 204**: No content

---

## Debts

### GET /debts
**Query**: `?rembourse=true|false` (optional)
**Response 200**: `DebtResponse[]`
```json
{
  "id": "uuid",
  "personne": "string",
  "montant": "decimal",
  "sens": "EMPRUNT | PRET",
  "date": "YYYY-MM-DD",
  "rembourse": "boolean",
  "category": "CategoryResponse?",
  "currency": "string"
}
```

### POST /debts
**Request**:
```json
{
  "personne": "string (required, max 255)",
  "montant": "decimal (required, positive)",
  "sens": "EMPRUNT | PRET (required)",
  "date": "YYYY-MM-DD (required)",
  "rembourse": "boolean?",
  "categoryId": "uuid?",
  "currency": "string?"
}
```
**Response 201**: DebtResponse

### PUT /debts/{id}
**Request**: Same as POST
**Response 200**: DebtResponse

### DELETE /debts/{id}
**Response 204**: No content

---

## Currencies

### GET /currencies (public, no auth)
**Response 200**: `CurrencyInfo[]`
```json
{
  "code": "string",
  "symbol": "string",
  "name": "string",
  "decimalPlaces": "int"
}
```

---

## Error Contract

Toutes les erreurs retournent :
```json
{
  "error": "string (type)",
  "message": "string (details)"
}
```

| Status | Usage |
|--------|-------|
| 400 | Validation error (Bean Validation) |
| 401 | Not authenticated / invalid token |
| 403 | Forbidden |
| 404 | Resource not found |
| 409 | Conflict (e.g., duplicate email) |
| 500 | Internal server error |

## Headers

- **Request**: `Authorization: Bearer {accessToken}` (sauf endpoints publics)
- **Request**: `Content-Type: application/json`
- **Response**: `Content-Type: application/json`

## JWT Flow (dio interceptor)

1. Chaque requete ajoute `Authorization: Bearer {accessToken}` via intercepteur
2. Si reponse 401 et refresh token disponible :
   a. Appel POST `/auth/refresh` avec le refresh token
   b. Si succes : stocker nouveaux tokens, rejouer la requete originale
   c. Si echec : deconnecter l'utilisateur, rediriger vers login
3. Les tokens sont stockes dans `flutter_secure_storage`
