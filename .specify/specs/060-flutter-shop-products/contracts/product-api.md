# API Contract: Product Endpoints

**Base path**: `/api/products`
**Auth**: JWT Bearer token (header `Authorization: Bearer <token>`)
**Content-Type**: `application/json`

## Endpoints utilisés par cette feature

### GET /products — Liste des produits actifs

**Scope**: FR-001, FR-011

**Response** `200 OK`:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nom": "Laptop Pro",
    "description": "Ordinateur portable haut de gamme",
    "icone": "💻",
    "imageUrl": null,
    "prixAchat": 1200.50,
    "prixVente": 1500.00,
    "stock": 5,
    "totalVendu": 12,
    "actif": true,
    "createdAt": "2026-02-15T10:30:00",
    "updatedAt": "2026-02-28T14:22:00"
  }
]
```

**Notes**:
- Retourne uniquement les produits actifs (`actif = true`) de l'utilisateur authentifié
- Triés par nom côté client (le backend ne garantit pas l'ordre)
- Lève `FeatureDisabledException` (403) si `Feature.SHOP` n'est pas activé

### GET /products/{id} — Détail d'un produit

**Scope**: FR-004 (navigation vers détail, hors scope immédiat)

**Response** `200 OK`: Même structure qu'un item de la liste.

**Erreurs**:
- `404 Not Found` — produit inexistant ou appartenant à un autre utilisateur

## Endpoints hors scope (référence)

Ces endpoints seront consommés par les features KKS-125 (détail) et formulaire :

| Endpoint | Méthode | Usage |
|----------|---------|-------|
| `POST /products` | Création | Formulaire création |
| `PUT /products/{id}` | Mise à jour | Formulaire édition |
| `DELETE /products/{id}` | Suppression | Écran détail |
| `POST /products/{id}/sell` | Enregistrer vente | Écran détail |
| `POST /products/{id}/restock` | Réapprovisionner | Écran détail |
| `GET /products/{id}/sales` | Historique ventes | Écran détail |
