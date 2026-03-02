# API Contract: Products

**Base Path**: `/api/products`
**Auth**: JWT Bearer Token (obligatoire)
**Feature Toggle**: `SHOP` (doit être activé dans les préférences utilisateur)

## Endpoints

### POST /products — Créer un produit

**Request**:
```json
{
  "nom": "T-shirt personnalisé",
  "description": "T-shirt 100% coton, impression personnalisée",
  "icone": "👕",
  "imageUrl": "https://example.com/tshirt.jpg",
  "prixAchat": 8.50,
  "prixVente": 15.00,
  "stock": 25
}
```

| Champ | Type | Obligatoire | Validation |
|-------|------|:-----------:|------------|
| nom | string | oui | Non vide, max 100 chars |
| description | string | non | Max 500 chars |
| icone | string | non | Emoji |
| imageUrl | string | non | Max 500 chars |
| prixAchat | number | oui | > 0, 2 décimales max |
| prixVente | number | oui | > 0, 2 décimales max |
| stock | integer | oui | >= 0 |

**Response 201 Created**:
```json
{
  "id": "a1b2c3d4-...",
  "nom": "T-shirt personnalisé",
  "description": "T-shirt 100% coton, impression personnalisée",
  "icone": "👕",
  "imageUrl": "https://example.com/tshirt.jpg",
  "prixAchat": 8.50,
  "prixVente": 15.00,
  "stock": 25,
  "totalVendu": 0,
  "actif": true,
  "createdAt": "2026-02-27T10:30:00",
  "updatedAt": "2026-02-27T10:30:00"
}
```

**Erreurs**:
- `400 Bad Request` — Validation échouée (champs invalides)
- `401 Unauthorized` — JWT manquant ou invalide
- `403 Forbidden` — Feature SHOP désactivée

---

### GET /products — Lister les produits actifs

**Response 200 OK**:
```json
[
  {
    "id": "a1b2c3d4-...",
    "nom": "T-shirt personnalisé",
    "description": "T-shirt 100% coton",
    "icone": "👕",
    "imageUrl": "https://example.com/tshirt.jpg",
    "prixAchat": 8.50,
    "prixVente": 15.00,
    "stock": 25,
    "totalVendu": 3,
    "actif": true,
    "createdAt": "2026-02-27T10:30:00",
    "updatedAt": "2026-02-27T12:00:00"
  }
]
```

**Notes**:
- Retourne uniquement les produits de l'utilisateur authentifié
- Filtre par `actif=true` par défaut
- Triés par `createdAt` décroissant

**Erreurs**:
- `401 Unauthorized` — JWT manquant ou invalide
- `403 Forbidden` — Feature SHOP désactivée

---

### GET /products/{id} — Consulter un produit

**Path Parameters**: `id` (UUID)

**Response 200 OK**: Même format que la réponse de création.

**Notes**:
- Retourne le produit même s'il est inactif (`actif=false`)
- Uniquement si le produit appartient à l'utilisateur authentifié

**Erreurs**:
- `401 Unauthorized` — JWT manquant ou invalide
- `403 Forbidden` — Feature SHOP désactivée
- `404 Not Found` — Produit inexistant ou appartenant à un autre utilisateur

---

### PUT /products/{id} — Modifier un produit

**Path Parameters**: `id` (UUID)

**Request**: Même format que la création, avec ajout du champ `actif` :
```json
{
  "nom": "T-shirt personnalisé v2",
  "description": "T-shirt bio",
  "icone": "👕",
  "imageUrl": "https://example.com/tshirt-v2.jpg",
  "prixAchat": 9.00,
  "prixVente": 18.00,
  "stock": 50,
  "actif": true
}
```

| Champ | Type | Obligatoire | Validation |
|-------|------|:-----------:|------------|
| nom | string | oui | Non vide, max 100 chars |
| description | string | non | Max 500 chars |
| icone | string | non | Emoji |
| imageUrl | string | non | Max 500 chars |
| prixAchat | number | oui | > 0, 2 décimales max |
| prixVente | number | oui | > 0, 2 décimales max |
| stock | integer | oui | >= 0 |
| actif | boolean | oui | Toggle de visibilité |

**Response 200 OK**: Même format que la réponse de création (avec valeurs mises à jour).

**Notes**:
- Remplacement complet (PUT) : tous les champs éditables requis
- `totalVendu`, `createdAt` ne sont pas modifiables par l'utilisateur
- `updatedAt` est actualisé automatiquement

**Erreurs**:
- `400 Bad Request` — Validation échouée
- `401 Unauthorized` — JWT manquant ou invalide
- `403 Forbidden` — Feature SHOP désactivée
- `404 Not Found` — Produit inexistant ou appartenant à un autre utilisateur

---

### DELETE /products/{id} — Supprimer un produit

**Path Parameters**: `id` (UUID)

**Response 204 No Content**: Corps vide.

**Notes**:
- Suppression physique (irréversible)
- Uniquement si le produit appartient à l'utilisateur authentifié

**Erreurs**:
- `401 Unauthorized` — JWT manquant ou invalide
- `403 Forbidden` — Feature SHOP désactivée
- `404 Not Found` — Produit inexistant ou appartenant à un autre utilisateur
