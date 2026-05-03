# Data Model: 060-flutter-shop-products

**Date**: 2026-03-01

## Entités

### Product (Domaine Flutter — Freezed)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | String | non | UUID généré par le backend |
| nom | String | non | Nom du produit (max 100 car.) |
| description | String | oui | Description (max 500 car.) |
| icone | String | oui | Emoji icône |
| imageUrl | String | oui | URL image (max 500 car.) |
| prixAchat | double | non | Prix d'achat (> 0) |
| prixVente | double | non | Prix de vente (> 0) |
| stock | int | non | Stock restant (>= 0) |
| totalVendu | int | non | Nombre total de ventes |
| actif | bool | non | Statut actif/inactif |
| createdAt | DateTime | oui | Date de création |
| updatedAt | DateTime | oui | Dernière mise à jour |

### ProductListState (State Riverpod — Freezed)

| Champ | Type | Default | Description |
|-------|------|---------|-------------|
| items | List\<Product\> | [] | Produits paginés à afficher |
| isLoading | bool | false | État de chargement |
| error | String | null | Message d'erreur |
| currentPage | int | 0 | Page courante (pagination client) |
| hasMore | bool | true | Reste-t-il des pages ? |
| mutatingIds | Set\<String\> | {} | IDs en cours de mutation |

## DTOs (Remote — Freezed + json_serializable)

### ProductResponse (Server → Client)

| Champ JSON | Type Dart | Nullable |
|------------|-----------|----------|
| id | String | non |
| nom | String | non |
| description | String | oui |
| icone | String | oui |
| imageUrl | String | oui |
| prixAchat | double | non |
| prixVente | double | non |
| stock | int | non |
| totalVendu | int | non |
| actif | bool | non |
| createdAt | String | oui |
| updatedAt | String | oui |

### ProductRequest (Client → Server, création)

| Champ JSON | Type Dart | Nullable |
|------------|-----------|----------|
| nom | String | non |
| description | String | oui |
| icone | String | oui |
| imageUrl | String | oui |
| prixAchat | double | non |
| prixVente | double | non |
| stock | int | non |

### ProductUpdateRequest (Client → Server, mise à jour)

| Champ JSON | Type Dart | Nullable |
|------------|-----------|----------|
| nom | String | non |
| description | String | oui |
| icone | String | oui |
| imageUrl | String | oui |
| prixAchat | double | non |
| prixVente | double | non |
| stock | int | non |
| actif | bool | non |

## Relations

```
Product ──FK──→ User (isolation par utilisateur, gérée côté backend)
```

Pas de relations côté Flutter — le backend gère l'isolation par JWT (userId extrait du token).

## Mapping DTO → Domaine

| DTO (String) | Domaine (Dart) | Transformation |
|--------------|----------------|----------------|
| createdAt | DateTime? | `DateTime.parse(r.createdAt!)` si non null |
| updatedAt | DateTime? | `DateTime.parse(r.updatedAt!)` si non null |
| prixAchat | double | Direct (pas de conversion) |
| prixVente | double | Direct (pas de conversion) |

## Mapping Domaine → ListItem (UI)

| ListItem prop | Source | Exemple |
|---------------|--------|---------|
| icon | `product.icone ?? '📦'` | "💻" |
| iconBackgroundColor | `AppColors.amber100` (défaut) | - |
| title | `product.nom` | "Laptop Pro" |
| value | `AmountFormatter.format(product.prixVente)` | "1 500,00 €" |
| subtitle | `'Stock: ${product.stock}'` | "Stock: 12" |
| rightSubtitle | `product.stock == 0 ? 'Rupture' : '${product.totalVendu} ventes'` | "5 ventes" / "Rupture" |
| valueColor | null (couleur par défaut du thème) | - |
| onPressed | Navigation vers détail | - |

## Validation

Les validations sont gérées côté backend (Bean Validation). Côté Flutter, validation minimale dans le formulaire (hors scope de cette feature — formulaire = feature séparée).

## Stockage

- **Backend** : PostgreSQL, table `products` (Flyway V10)
- **Flutter** : Aucun stockage local — données toujours fraîches depuis l'API REST
