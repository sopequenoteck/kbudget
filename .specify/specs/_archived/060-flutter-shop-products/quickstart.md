# Quickstart: 060-flutter-shop-products

## Prérequis

- Flutter >= 3.27 installé
- Backend Spring Boot en cours d'exécution (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Feature `SHOP` activée dans les préférences utilisateur (via Settings > Fonctionnalités)

## Structure des fichiers à créer

```
flutter/lib/src/
├── domain/
│   ├── models/
│   │   └── product.dart                    # Freezed model Product
│   └── repositories/
│       └── product_repository.dart         # Interface abstraite
├── data/
│   ├── remote/
│   │   ├── data_sources/
│   │   │   └── product_remote_data_source.dart  # Dio HTTP client
│   │   └── dtos/
│   │       └── product_dtos.dart           # Request/Response DTOs Freezed
│   └── data_mode_provider.dart             # + productRepositoryProvider
└── features/
    └── shop/
        ├── application/
        │   ├── product_list_state.dart     # Freezed state
        │   └── product_notifier.dart       # CRUD Notifier
        ├── data/
        │   └── product_repository_remote.dart  # Implémentation remote
        └── presentation/
            └── product_list_screen.dart    # Écran liste

flutter/test/src/features/shop/
└── application/
    └── product_notifier_test.dart          # Tests unitaires notifier
```

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `flutter/lib/src/domain/models/models.dart` | Ajouter export `product.dart` |
| `flutter/lib/src/domain/repositories/repositories.dart` | Ajouter export `product_repository.dart` |
| `flutter/lib/src/data/data_mode_provider.dart` | Ajouter `productRepositoryProvider` |
| `flutter/lib/src/routing/app_router.dart` | Remplacer placeholder Shop par `ProductListScreen` |

## Commandes de développement

```bash
# Code generation (après création des fichiers Freezed)
cd flutter && dart run build_runner build --delete-conflicting-outputs

# Lancer l'app
cd flutter && flutter run

# Tests
cd flutter && flutter test test/src/features/shop/

# Analyse statique
cd flutter && flutter analyze
```

## Vérification rapide

1. Activer la feature Boutique : Settings > Fonctionnalités > Boutique ON
2. L'onglet Boutique apparaît dans la bottom nav
3. Ouvrir l'onglet → état vide s'affiche (si pas de produits)
4. Créer un produit via l'API (`POST /api/products`) → pull-to-refresh → le produit apparaît
