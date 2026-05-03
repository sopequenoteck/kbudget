# API Contract: Currency Dashboard

**Feature Branch**: `070-currency-dashboard`
**Date**: 2026-03-06
**Base path**: `/api`

## Nouveaux endpoints

### Exchange Rates CRUD

#### GET /exchange-rates

Liste tous les taux de conversion de l'utilisateur authentifie.

**Response**: `200 OK`

```json
[
  {
    "id": "uuid-1",
    "baseCurrency": "EUR",
    "targetCurrency": "XOF",
    "rate": 655.957000,
    "updatedAt": "2026-03-06T10:00:00"
  },
  {
    "id": "uuid-2",
    "baseCurrency": "EUR",
    "targetCurrency": "USD",
    "rate": 1.080000,
    "updatedAt": "2026-03-06T10:05:00"
  }
]
```

**Erreurs**:

| Code | Cas |
|------|-----|
| 401 | JWT absent ou invalide |

---

#### PUT /exchange-rates

Upsert d'un taux de conversion. Si la paire (base, target) existe, elle est mise a jour. Sinon, elle est creee.

**Request**:

```json
{
  "baseCurrency": "EUR",
  "targetCurrency": "XOF",
  "rate": 655.957
}
```

**Validation**:

| Champ | Regle | Message d'erreur |
|-------|-------|-----------------|
| baseCurrency | @NotNull, valeur valide de Currency | "Devise de base invalide" |
| targetCurrency | @NotNull, valeur valide de Currency | "Devise cible invalide" |
| baseCurrency != targetCurrency | Cross-field validation | "Les devises de base et cible doivent etre differentes" |
| rate | @NotNull, @DecimalMin("0.000001"), @Digits(integer=14, fraction=6) | "Le taux doit etre strictement positif avec max 6 decimales" — @DecimalMin("0.000001") car 6 decimales max = plus petite valeur representable > 0 |

**Response**: `200 OK`

```json
{
  "id": "uuid-1",
  "baseCurrency": "EUR",
  "targetCurrency": "XOF",
  "rate": 655.957000,
  "updatedAt": "2026-03-06T10:00:00"
}
```

**Erreurs**:

| Code | Cas |
|------|-----|
| 400 | Validation echouee (taux <= 0, meme devise, format invalide) |
| 401 | JWT absent ou invalide |

---

#### DELETE /exchange-rates/{baseCurrency}/{targetCurrency}

Supprime un taux de conversion par paire de devises.

**Path params**: `baseCurrency` (ex: EUR), `targetCurrency` (ex: XOF)

**Response**: `204 No Content`

**Erreurs**:

| Code | Cas |
|------|-----|
| 401 | JWT absent ou invalide |
| 404 | Taux non trouve pour cette paire |

---

## Endpoints modifies

### PUT /users/me/preferences

Ajout du champ optionnel `currencies`.

**Request** (champs existants + nouveau):

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "shopAccountId": "uuid-or-null",
  "includeShopInBalance": false,
  "currencies": ["EUR", "XOF", "USD"]
}
```

**Validation `currencies`**:

| Regle | Message d'erreur |
|-------|-----------------|
| Non null (si present) | "La liste de devises ne peut pas etre vide" |
| Min 1 element | "Au moins une devise requise" |
| Pas de doublons | "La liste de devises ne doit pas contenir de doublons" |
| Valeurs valides de Currency | "Devise invalide : {value}" |

**Comportement special** : Si `currencies[0]` change (nouvelle devise principale), le backend appelle `ExchangeRateService.rebaseRates()` pour inverser automatiquement tous les taux.

**Response**: `200 OK`

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "shopAccountId": null,
  "includeShopInBalance": false,
  "currencies": ["EUR", "XOF", "USD"]
}
```

---

### GET /users/me/preferences

Ajout du champ `currencies` dans la reponse.

**Response**: `200 OK`

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "shopAccountId": null,
  "includeShopInBalance": false,
  "currencies": ["EUR"]
}
```

---

### GET /users/me (modification)

Suppression du champ `defaultCurrency` de la reponse (remplace par `currencies` dans preferences).

**Response avant**:

```json
{
  "name": "Kelly",
  "email": "kelly@example.com",
  "defaultCurrency": "EUR"
}
```

**Response apres**:

```json
{
  "name": "Kelly",
  "email": "kelly@example.com"
}
```

**Note** : `PUT /users/me` perd le champ `defaultCurrency` dans la request. Le profil ne gere plus la devise (deplacee vers preferences).

---

### PUT /users/me (modification)

La request ne contient plus `defaultCurrency`. Si d'autres champs sont ajoutes a terme (name, etc.), ils seront ici. Pour l'instant, ce endpoint pourrait devenir minimal ou etre preserve pour de futures extensions.

**Request avant**:

```json
{
  "defaultCurrency": "EUR"
}
```

**Request apres** : A evaluer — potentiellement inutile si seul `defaultCurrency` etait modifiable. Conserver le endpoint avec un body vide ou optionnel pour future extension (name update).

---

## Endpoints inchanges

| Endpoint | Notes |
|----------|-------|
| GET /currencies | Liste les devises supportees — pas de changement |
| GET/POST/PUT/DELETE /accounts | Conservent le champ `currency` — pas de changement |
| GET/POST/PUT/DELETE /transactions | Pas de changement |
| GET/POST/PUT/DELETE /subscriptions | Pas de changement |
| GET/POST/PUT/DELETE /debts | Pas de changement |

## Flux client-serveur

### Chargement initial (dashboard)

```
1. GET /users/me/preferences → currencies, enabledFeatures, navOrder
2. GET /exchange-rates → tous les taux
3. GET /accounts → comptes avec currency
4. Client : calcul conversions localement
5. Client : affichage dashboard unifie
```

### Changement de devise principale (pill tap)

```
1. Client : reorder currencies en memoire
2. Client : recalcul via inversion locale (1/rate)
3. Debounce 2s
4. PUT /users/me/preferences { currencies: [newOrder] }
5. Backend : detecte changement currencies[0]
6. Backend : rebaseRates() — inverse tous les taux
7. Response 200 avec nouvelles preferences
8. GET /exchange-rates (optionnel — refresh taux inverses)
```

### Saisie d'un taux

```
1. Client : formulaire taux (base, target, rate)
2. PUT /exchange-rates { baseCurrency, targetCurrency, rate }
3. Response 200 avec taux cree/mis a jour
4. Client : rafraichit les taux locaux
5. Dashboard : recalcul automatique
```
