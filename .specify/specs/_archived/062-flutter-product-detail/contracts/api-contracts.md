# API Contracts: 062-flutter-product-detail

**Date**: 2026-03-01

## Endpoints consommes

Tous les endpoints sont sous le context path `/api` et necessitent un JWT valide (`Authorization: Bearer <token>`). La feature `SHOP` doit etre activee pour l'utilisateur.

### POST /products/{id}/sell

Vend une unite du produit (stock - 1, totalVendu + 1). Cree automatiquement une transaction RECETTE.

**Request**: Pas de body

**Response** `200 OK`:
```json
{
  "id": "uuid",
  "nom": "string",
  "description": "string?",
  "icone": "string?",
  "imageUrl": "string?",
  "prixAchat": 10.00,
  "prixVente": 15.00,
  "stock": 4,
  "totalVendu": 6,
  "actif": true,
  "createdAt": "2026-01-15T10:30:00",
  "updatedAt": "2026-03-01T14:22:00"
}
```

**Errors**:
- `404 Not Found` — produit inexistant ou n'appartient pas a l'utilisateur
- `409 Conflict` — stock = 0 ou produit inactif
- `403 Forbidden` — feature SHOP desactivee

### POST /products/{id}/restock

Ajoute du stock au produit (stock + quantity). Cree automatiquement une transaction DEPENSE (montant = prixAchat * quantity).

**Request**:
```json
{
  "quantity": 10
}
```

**Validation**: `quantity` doit etre > 0 (`@NotNull @Positive`)

**Response** `200 OK`: Meme format que `sell` ci-dessus (ProductResponse avec stock mis a jour)

**Errors**:
- `400 Bad Request` — quantity invalide (null, <= 0)
- `404 Not Found` — produit inexistant
- `409 Conflict` — produit inactif
- `403 Forbidden` — feature SHOP desactivee

### GET /products/{id}/sales

Historique des transactions liees au produit (ventes RECETTE + restocks DEPENSE), triees par date decroissante.

**Note**: Necessite un fix backend — actuellement filtre RECETTE uniquement. Le fix supprime le filtre Java dans `ProductService.getSalesHistory()`.

**Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "montant": 15.00,
    "libelle": "Vente: Casquette",
    "type": "RECETTE",
    "date": "2026-03-01",
    "category": {
      "id": "uuid",
      "nom": "Boutique",
      "icone": "🛍️",
      "couleur": "#f59e0b",
      "isSystem": true
    },
    "note": null,
    "account": {
      "id": "uuid",
      "nom": "Boutique",
      "icone": "🛍️",
      "couleur": "#f59e0b",
      "currency": "EUR"
    },
    "transferId": null,
    "productId": "uuid",
    "productName": "Casquette"
  },
  {
    "id": "uuid",
    "montant": 50.00,
    "libelle": "Stock: Casquette x5",
    "type": "DEPENSE",
    "date": "2026-02-28",
    "category": { "..." },
    "note": null,
    "account": { "..." },
    "transferId": null,
    "productId": "uuid",
    "productName": "Casquette"
  }
]
```

**Errors**:
- `404 Not Found` — produit inexistant
- `403 Forbidden` — feature SHOP desactivee

### GET /products/{id}

Consulter un produit (deja implemente, utilise pour le refresh si necessaire).

**Response** `200 OK`: Meme format ProductResponse.
