# Data Model: 068-angular-shop-module

**Date**: 2026-03-02 | **Branch**: `068-angular-shop-module`

## Entities

### Product (Angular interface)

Mappe directement `ProductResponse` du backend.

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | string (UUID) | non | Identifiant unique |
| nom | string | non | Nom du produit (max 100 car.) |
| description | string | oui | Description (max 500 car.) |
| icone | string | oui | Emoji representant le produit |
| imageUrl | string | oui | URL de l'image (max 500 car.) |
| prixAchat | number | non | Prix d'achat (> 0, 2 decimales) |
| prixVente | number | non | Prix de vente (> 0, 2 decimales) |
| stock | number | non | Stock actuel (>= 0) |
| totalVendu | number | non | Total d'unites vendues |
| actif | boolean | non | Produit actif ou desactive |
| createdAt | string (ISO) | non | Date de creation |
| updatedAt | string (ISO) | non | Date de derniere modification |

### ProductRequest (creation DTO)

| Champ | Type | Nullable | Validation |
|-------|------|----------|------------|
| nom | string | non | required, maxLength(100) |
| description | string | oui | maxLength(500) |
| icone | string | oui | — |
| imageUrl | string | oui | maxLength(500) |
| prixAchat | number | non | required, > 0, 2 decimales |
| prixVente | number | non | required, > 0, 2 decimales |
| stock | number | non | required, >= 0 |

### ProductUpdateRequest (modification DTO)

Identique a `ProductRequest` + :

| Champ | Type | Nullable | Validation |
|-------|------|----------|------------|
| actif | boolean | non | required |

### RestockRequest

| Champ | Type | Nullable | Validation |
|-------|------|----------|------------|
| quantity | number | non | required, >= 1 (entier positif) |

### SellRequest (vente N unites)

| Champ | Type | Nullable | Validation |
|-------|------|----------|------------|
| quantity | number | non | required, >= 1 (entier positif) |

## Relationships

```
Product ──(belongs to)──> User (implicite, filtre par JWT)
Product ──(generates)──> Transaction (via sell/restock, lien par productId)
Product ──(uses)──> Account "Boutique" (via shopAccountId dans UserPreference)
```

## Computed values (frontend only)

Calculees a partir des champs Product, jamais persistees :

| Valeur | Formule | Affichage |
|--------|---------|-----------|
| Marge unitaire | prixVente - prixAchat | Formulaire + Detail |
| Chiffre d'affaires | totalVendu × prixVente | Detail |
| Marge totale | totalVendu × (prixVente - prixAchat) | Detail |

## State management (Angular signals)

```
ShopList:
  products: signal<Product[]>     ← GET /products(?includeInactive=true)
  loading: signal<boolean>
  error: signal<boolean>
  filter: signal<'active' | 'inactive' | 'all'>  ← filtre local
  filteredProducts: computed()     ← derive de products + filter

ShopDetail:
  product: signal<Product | null>  ← GET /products/:id
  salesHistory: signal<Transaction[]> ← GET /products/:id/sales
  loading: signal<boolean>
```
