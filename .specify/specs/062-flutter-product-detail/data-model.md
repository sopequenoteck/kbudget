# Data Model: 062-flutter-product-detail

**Date**: 2026-03-01

## Entites existantes (pas de modification)

### Product (Freezed model — deja existant)

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | String | non | UUID |
| nom | String | non | Nom du produit (max 100) |
| description | String? | oui | Description (max 500) |
| icone | String? | oui | Emoji ou icone |
| imageUrl | String? | oui | Chemin local vers image |
| prixAchat | double | non | Prix d'achat unitaire |
| prixVente | double | non | Prix de vente unitaire |
| stock | int | non | Quantite en stock |
| totalVendu | int | non | Nombre total d'unites vendues |
| actif | bool | non | Produit actif (default true) |
| createdAt | DateTime? | oui | Date de creation |
| updatedAt | DateTime? | oui | Date de mise a jour |

**Stats derivees (calculees cote client)** :
- `margeUnitaire` = prixVente - prixAchat
- `chiffreAffaires` = totalVendu * prixVente
- `margeTotale` = totalVendu * (prixVente - prixAchat)

### Transaction (consommee en lecture seule via l'historique)

Le detail produit consomme `TransactionResponse` via `GET /products/{id}/sales`. Le model `Transaction` Freezed existant est reutilise.

| Champ | Type | Description |
|-------|------|-------------|
| id | String | UUID |
| montant | double | Montant (prixVente pour vente, prixAchat * qty pour restock) |
| libelle | String | "Vente: <nom>" ou "Stock: <nom> x<qty>" |
| type | TransactionType | RECETTE (vente) ou DEPENSE (restock) |
| date | DateTime | Date de la transaction |
| category | Category | Categorie "Boutique" (auto-creee) |
| account | Account | Compte boutique (auto-cree) |
| productId | String? | UUID du produit lie |
| productName | String? | Nom du produit |

## Nouvelles interfaces

### ProductRepository (extensions)

```
+sell(String id) → Future<Product>
+restock(String id, int quantity) → Future<Product>
+getSales(String id) → Future<List<Transaction>>
```

### ProductRemoteDataSource (extensions)

```
+sell(String id) → Future<ProductResponse>
+restock(String id, RestockRequest request) → Future<ProductResponse>
+getSales(String id) → Future<List<TransactionResponse>>
```

### RestockRequest (nouveau DTO — Freezed + json_serializable)

| Champ | Type | Contraintes |
|-------|------|-------------|
| quantity | int | > 0 |

## Relations

```
ProductListScreen ──tap──> ProductDetailScreen (via /shop/:id, extra: Product)
                              │
                              ├── affiche Product (watch productNotifierProvider)
                              ├── sell() → ProductNotifier.sellProduct(id)
                              ├── restock() → RestockDialog → ProductNotifier.restockProduct(id, qty)
                              ├── historique → productSalesProvider(id) (FutureProvider.family)
                              └── modifier → modalNotifierProvider.open(ModalType.product, entity: product)
```
