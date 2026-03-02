# API Contract: Products

**Base path**: `/api/products`
**Auth**: JWT Bearer token (toutes les routes)
**Pre-condition**: Feature SHOP activee dans UserPreference

## Endpoints

### GET /products

Liste les produits de l'utilisateur authentifie.

**Query params**:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| includeInactive | boolean | false | Si true, retourne aussi les produits inactifs |

**Response 200**:
```json
[
  {
    "id": "uuid",
    "nom": "string",
    "description": "string | null",
    "icone": "string | null",
    "imageUrl": "string | null",
    "prixAchat": 10.00,
    "prixVente": 15.00,
    "stock": 5,
    "totalVendu": 12,
    "actif": true,
    "createdAt": "2026-03-02T10:00:00",
    "updatedAt": "2026-03-02T10:00:00"
  }
]
```

Tri: `createdAt` decroissant.

---

### POST /products

Cree un nouveau produit.

**Request body** (`ProductRequest`):
```json
{
  "nom": "string (required, max 100)",
  "description": "string (optional, max 500)",
  "icone": "string (optional)",
  "imageUrl": "string (optional, max 500)",
  "prixAchat": 10.00,
  "prixVente": 15.00,
  "stock": 0
}
```

**Response 201**: `ProductResponse`

**Errors**: 400 (validation), 403 (feature disabled)

---

### GET /products/{id}

Retourne un produit par son ID (quel que soit son statut actif/inactif).

**Response 200**: `ProductResponse`

**Errors**: 404 (not found)

---

### PUT /products/{id}

Met a jour un produit (remplacement complet).

**Request body** (`ProductUpdateRequest`):
```json
{
  "nom": "string (required, max 100)",
  "description": "string (optional, max 500)",
  "icone": "string (optional)",
  "imageUrl": "string (optional, max 500)",
  "prixAchat": 10.00,
  "prixVente": 15.00,
  "stock": 5,
  "actif": true
}
```

**Response 200**: `ProductResponse`

**Errors**: 400 (validation), 404 (not found)

---

### DELETE /products/{id}

Supprime definitivement un produit (hard delete).

**Response 204**: No content

**Errors**: 404 (not found)

---

### POST /products/{id}/sell

Vend N unites du produit (defaut 1). Decremente stock de N, incremente totalVendu de N, cree une Transaction RECETTE (montant = prixVente x N).

**Request body** (optionnel, `SellRequest`):
```json
{
  "quantity": 1
}
```

Si body absent ou `quantity` absent, defaut a 1 unite.

**Response 200**: `ProductResponse` (mis a jour)

**Errors**: 400 (validation, quantity <= 0), 404 (not found), 409 (stock insuffisant ou produit inactif)

---

### POST /products/{id}/restock

Restocker N unites. Incremente stock, cree une Transaction DEPENSE (prixAchat × quantity).

**Request body** (`RestockRequest`):
```json
{
  "quantity": 10
}
```

**Response 200**: `ProductResponse` (mis a jour)

**Errors**: 400 (validation, quantity <= 0), 404 (not found)

---

### GET /products/{id}/sales

Historique des transactions liees au produit (ventes RECETTE + restocks DEPENSE).

**Response 200**:
```json
[
  {
    "id": "uuid",
    "montant": 15.00,
    "libelle": "Vente : Nom du produit",
    "type": "RECETTE",
    "date": "2026-03-02",
    "category": { "id": "uuid", "nom": "Boutique", "icone": "🏪", "couleur": "#...", "isSystem": true },
    "note": null,
    "account": { "id": "uuid", "nom": "Boutique", "icone": "🏪", "couleur": "#...", "currency": "EUR" },
    "transferId": null,
    "productId": "uuid",
    "productName": "Nom du produit"
  }
]
```

**Errors**: 404 (product not found)
