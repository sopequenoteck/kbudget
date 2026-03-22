# Quickstart: 062-flutter-product-detail

**Date**: 2026-03-01

## Prerequisites

- Flutter >= 3.27 installe
- Backend API en cours d'execution (profil dev) avec feature SHOP activee
- Branche `062-flutter-product-detail` checked out

## Setup

```bash
cd flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Developpement

```bash
# Lancer l'app
cd flutter && flutter run

# Tests unitaires
cd flutter && flutter test test/src/features/shop/

# Analyse statique
cd flutter && flutter analyze
```

## Backend (fix historique)

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## Fichiers a creer/modifier

### Nouveaux fichiers
1. `flutter/lib/src/features/shop/presentation/product_detail_screen.dart`
2. `flutter/lib/src/features/shop/presentation/widgets/restock_dialog.dart`

### Fichiers a modifier
1. `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java` — supprimer filtre RECETTE dans `getSalesHistory()`
2. `flutter/lib/src/data/remote/data_sources/product_remote_data_source.dart` — ajouter `sell()`, `restock()`, `getSales()`
3. `flutter/lib/src/domain/repositories/product_repository.dart` — ajouter interfaces `sell()`, `restock()`, `getSales()`
4. `flutter/lib/src/features/shop/data/product_repository_remote.dart` — implementer `sell()`, `restock()`, `getSales()`
5. `flutter/lib/src/features/shop/application/product_notifier.dart` — ajouter `sellProduct()`, `restockProduct()`, provider `productSalesProvider`
6. `flutter/lib/src/routing/app_router.dart` — ajouter sous-route `/shop/:id`
7. `flutter/lib/src/features/shop/presentation/product_list_screen.dart` — navigation tap → detail au lieu de modal edition

## Verification rapide

1. Naviguer vers l'onglet Boutique
2. Taper sur un produit → ecran de detail avec stats
3. Taper "Vendre" → stock decremente, snackbar confirmation
4. Taper "Ajouter stock" → dialogue, saisir quantite → stock augmente
5. Verifier l'historique en bas de l'ecran
6. Taper "Modifier" → modale edition s'ouvre
