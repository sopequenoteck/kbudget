# Quickstart: 068-angular-shop-module

**Date**: 2026-03-02 | **Branch**: `068-angular-shop-module`

## Prerequisites

- Feature SHOP activee dans les preferences utilisateur (Settings > Fonctionnalites)
- Au moins un produit cree via l'API ou le formulaire
- Backend lance avec profil dev (`mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Frontend Angular lance (`cd app && ng serve`)

## Build & Run

```bash
# Backend (modification endpoint GET /products)
cd api && mvn clean compile

# Frontend Angular
cd app && ng serve
```

## Key files (a creer/modifier)

### Backend (modification mineure)

| Fichier | Action |
|---------|--------|
| `api/.../controller/ProductController.java` | Ajouter `@RequestParam includeInactive` sur `getAll()` |
| `api/.../service/ProductService.java` | Brancher logique includeInactive |
| `api/.../repository/ProductRepository.java` | Ajouter query method tous produits |

### Angular (creation module complet)

| Fichier | Action |
|---------|--------|
| `app/src/app/core/models/product.model.ts` | Creer (Product, ProductRequest, ProductUpdateRequest, RestockRequest) |
| `app/src/app/core/services/product.ts` | Creer (CRUD + sell + restock + getSalesHistory) |
| `app/src/app/core/services/modal.service.ts` | Modifier (+`'product'` dans ModalType) |
| `app/src/app/features/shop/shop.routes.ts` | Creer (routes /shop, /shop/:id) |
| `app/src/app/features/shop/shop-list/shop-list.ts` | Creer (+.html, .scss) |
| `app/src/app/features/shop/shop-list/shop-list.html` | Creer |
| `app/src/app/features/shop/shop-list/shop-list.scss` | Creer |
| `app/src/app/features/shop/shop-detail/shop-detail.ts` | Creer (+.html, .scss) |
| `app/src/app/features/shop/shop-detail/shop-detail.html` | Creer |
| `app/src/app/features/shop/shop-detail/shop-detail.scss` | Creer |
| `app/src/app/features/shop/components/product-form/product-form.ts` | Creer (+.html, .scss) |
| `app/src/app/features/shop/components/product-form/product-form.html` | Creer |
| `app/src/app/features/shop/components/product-form/product-form.scss` | Creer |
| `app/src/app/features/shop/components/restock-dialog/restock-dialog.ts` | Creer (+.html, .scss) |
| `app/src/app/app.routes.ts` | Modifier (loadComponent → loadChildren) |
| `app/src/app/shared/components/shell/shell.ts` | Modifier (+import, +handlers) |
| `app/src/app/shared/components/shell/shell.html` | Modifier (+@case 'product') |
| `app/src/app/shared/components/fab/fab.ts` | Modifier (+action product conditionnelle) |

### Fichier a supprimer

| Fichier | Raison |
|---------|--------|
| `app/src/app/features/shop/shop-placeholder.ts` | Remplace par ShopList |

## Verification

```bash
# Build Angular
cd app && ng build

# Tests
cd app && ng test

# Lint
cd app && ng lint

# Backend tests (si modification)
cd api && mvn test
```
