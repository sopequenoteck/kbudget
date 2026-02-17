# API Contracts: Comptes bancaires — Frontend

**Branch**: `027-bank-accounts-frontend` | **Date**: 2026-02-16

> Ces contrats decrivent les endpoints backend deja implementes que le frontend va consommer.
> Base URL: `/api`

## Endpoints Comptes

### GET /accounts

Liste tous les comptes de l'utilisateur authentifie.

**Query Parameters**:

| Param | Type | Defaut | Description |
|-------|------|--------|-------------|
| `includeInactive` | `boolean` | `false` | Inclure les comptes inactifs |

**Response** `200 OK`: `Account[]`

---

### GET /accounts/{id}

Recupere un compte par son ID.

**Response** `200 OK`: `Account`
**Response** `404 Not Found`: Compte introuvable

---

### POST /accounts

Cree un nouveau compte.

**Request Body**: `AccountRequest`
**Response** `201 Created`: `Account`
**Response** `400 Bad Request`: Validation error

---

### PUT /accounts/{id}

Modifie un compte existant. Le `soldeInitial` est ignore (fige apres creation).

**Request Body**: `AccountRequest`
**Response** `200 OK`: `Account`
**Response** `404 Not Found`: Compte introuvable

---

### DELETE /accounts/{id}

Supprime un compte.

**Response** `204 No Content`: Suppression reussie
**Response** `400 Bad Request`: Compte par defaut, ou a des transactions/abonnements
**Response** `404 Not Found`: Compte introuvable

---

### PUT /accounts/{id}/default

Definit un compte comme compte par defaut.

**Response** `200 OK`: `Account` (avec `isDefault: true`)
**Response** `404 Not Found`: Compte introuvable

---

### POST /accounts/transfer

Effectue un virement entre deux comptes.

**Request Body**: `TransferRequest`
**Response** `201 Created`: `TransferResponse`
**Response** `400 Bad Request`: Meme compte source/destination, compte inactif, montant invalide

## Endpoints modifies (Transaction/Subscription)

### Transactions

Les endpoints existants (`GET /transactions`, `POST /transactions`, `PUT /transactions/{id}`) acceptent et retournent desormais les champs `account` (dans la reponse) et `accountId` (dans la requete).

**Transaction Response** — champs ajoutes :

| Champ | Type | Description |
|-------|------|-------------|
| `account` | `AccountSummary \| null` | Compte associe |
| `transferId` | `string \| null` | UUID de virement |

**TransactionRequest** — champ ajoute :

| Champ | Type | Description |
|-------|------|-------------|
| `accountId` | `string?` | UUID du compte |

### Subscriptions

Les endpoints existants (`GET /subscriptions`, `POST /subscriptions`, `PUT /subscriptions/{id}`) acceptent et retournent desormais le champ `account` / `accountId`.

**Subscription Response** — champ ajoute :

| Champ | Type | Description |
|-------|------|-------------|
| `account` | `AccountSummary \| null` | Compte associe (optionnel) |

**SubscriptionRequest** — champ ajoute :

| Champ | Type | Description |
|-------|------|-------------|
| `accountId` | `string?` | UUID du compte (optionnel) |

## Gestion des erreurs

Toutes les erreurs API suivent le format Spring Boot standard :

```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Le compte par défaut ne peut pas être supprimé"
}
```

Le frontend DOIT extraire `message` et l'afficher a l'utilisateur (FR-014).

Codes d'erreur attendus :
- `400` : Validation (champs manquants, meme compte source/destination, compte par defaut non supprimable)
- `401` : JWT invalide/expire (gere par AuthInterceptor)
- `404` : Ressource introuvable
- `500` : Erreur serveur interne
