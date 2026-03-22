# API Contracts: 057-backend-product-sales

**Base path**: `/api/products`
**Auth**: JWT Bearer token (toutes les routes)
**Pre-condition**: Feature `SHOP` activee dans les preferences utilisateur (sinon 403)

---

## POST /products/{id}/sell

Enregistre une vente unitaire du produit.

**Request**: Aucun body requis.

**Response 200**:
```json
{
  "id": "uuid",
  "nom": "string",
  "description": "string|null",
  "icone": "string|null",
  "imageUrl": "string|null",
  "prixAchat": 8.00,
  "prixVente": 15.00,
  "stock": 4,
  "totalVendu": 6,
  "actif": true,
  "createdAt": "2026-02-28T10:00:00",
  "updatedAt": "2026-02-28T14:30:00"
}
```

**Effets de bord**:
- `stock -= 1`
- `totalVendu += 1`
- Transaction RECETTE creee : montant = `prixVente`, libelle = `"Vente: {nom}"`, categorie = "Boutique" (systeme), compte = `shopAccountId`, productId = `{id}`

**Erreurs**:
| Code | Condition |
|------|-----------|
| 403 | Feature SHOP desactivee |
| 404 | Produit inexistant ou appartient a un autre utilisateur |
| 409 | Stock = 0 (message: "Stock insuffisant pour le produit {nom}") |
| 409 | Produit inactif (message: "Le produit {nom} est inactif") |

---

## POST /products/{id}/restock

Restock le produit avec la quantite specifiee.

**Request**:
```json
{
  "quantity": 5
}
```

| Champ | Type | Validation |
|-------|------|------------|
| `quantity` | Integer | `@NotNull @Positive` (> 0) |

**Response 200**:
```json
{
  "id": "uuid",
  "nom": "string",
  "stock": 8,
  "totalVendu": 5,
  ...
}
```

**Effets de bord**:
- `stock += quantity`
- Transaction DEPENSE creee : montant = `prixAchat * quantity`, libelle = `"Stock: {nom} x{quantity}"`, categorie = "Boutique" (systeme), compte = `shopAccountId`, productId = `{id}`

**Erreurs**:
| Code | Condition |
|------|-----------|
| 400 | Quantite manquante, nulle ou negative |
| 403 | Feature SHOP desactivee |
| 404 | Produit inexistant ou autre utilisateur |
| 409 | Produit inactif |

---

## GET /products/{id}/sales

Retourne l'historique des transactions de vente liees au produit.

**Query params**: Aucun.

**Response 200**:
```json
[
  {
    "id": "uuid",
    "montant": 15.00,
    "libelle": "Vente: Bracelet",
    "type": "RECETTE",
    "date": "2026-02-28",
    "category": { "id": "uuid", "nom": "Boutique", ... },
    "note": null,
    "account": { "id": "uuid", "nom": "Boutique" },
    "transferId": null,
    "productId": "uuid",
    "productName": "Bracelet"
  }
]
```

Triees par date decroissante. Liste vide si aucune vente.

**Erreurs**:
| Code | Condition |
|------|-----------|
| 403 | Feature SHOP desactivee |
| 404 | Produit inexistant ou autre utilisateur |

---

## Modifications sur endpoints existants

### GET /accounts (enrichi)

`AccountResponse` ajoute un champ `isShopAccount` (boolean).

```json
{
  "id": "uuid",
  "nom": "Boutique",
  "type": "COURANT",
  "soldeInitial": 0.00,
  "solde": 150.00,
  "icone": "🛍️",
  "couleur": "#f59e0b",
  "isDefault": false,
  "actif": true,
  "currency": "EUR",
  "isShopAccount": true
}
```

### DELETE /transactions/{id} (comportement enrichi)

Si la transaction supprimee a un `productId` non null :
- Type RECETTE (vente) : `product.stock += 1`, `product.totalVendu -= 1`
- Type DEPENSE (restock) : `product.stock -= N` (N = `montant / product.prixAchat`)

Le endpoint continue de retourner 204 No Content.

### GET /preferences (enrichi)

`UserPreferenceResponse` ajoute deux champs.

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "shopAccountId": "uuid|null",
  "includeShopInBalance": false
}
```

### PUT /preferences (enrichi)

`UserPreferenceRequest` accepte deux champs optionnels supplementaires.

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "shopAccountId": "uuid",
  "includeShopInBalance": true
}
```

Validation : si `shopAccountId` fourni, verifier que le compte existe et appartient a l'utilisateur.
