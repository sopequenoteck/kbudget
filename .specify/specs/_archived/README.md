# Specs archivées

Ce dossier contient les specs devflow qui ne sont plus actives dans le projet `budget` mais qui sont conservées comme **historique documentaire**.

## Pourquoi archiver plutôt que supprimer

Les specs devflow racontent l'histoire des décisions techniques et produit du projet. Les supprimer reviendrait à perdre le contexte des choix faits. L'archivage permet de garder cette mémoire sans polluer le dossier `.specify/specs/` actif.

## Module shop — archivé le 2026-04-13

Les 6 specs suivantes concernent l'ancien module **shop** (gestion de micro-commerce) qui a été **entièrement extrait** de l'app budget :

| Spec | Contenu |
|------|---------|
| `056-backend-product-crud` | CRUD produits côté Spring Boot (Product, ProductRepository, ProductService, ProductController) |
| `057-backend-product-sales` | Endpoints de vente (SellRequest, RestockRequest, rollback stock, transactions auto-générées) |
| `060-flutter-shop-products` | Liste des produits côté Flutter (Riverpod notifier, ListState, repository) |
| `061-flutter-product-form` | Formulaire de création/édition produit côté Flutter |
| `062-flutter-product-detail` | Écran de détail produit côté Flutter |
| `068-angular-shop-module` | Module shop complet côté Angular (liste, détail, dialogs sell/restock) |

### Raison de l'extraction

Le shop a été identifié comme un **autre métier** (gestion active de micro-commerce) qui n'avait pas sa place dans une app de budget personnel (constatation passive de flux). Une seule utilisatrice active au moment de l'extraction, quatre autres avaient exprimé une intention d'usage mais continuaient à utiliser leurs tableurs. La constitution du projet (principe #3, YAGNI) ne justifiait pas de faire évoluer le shop dans l'app budget.

### Référence code

Le code du module shop au moment de l'extraction est préservé dans le tag git **`archive/shop-v0`**. Pour inspecter l'ancienne implémentation :

```bash
git show archive/shop-v0:api/src/main/java/fr/kksdev/budget/api/service/ProductService.java
git checkout archive/shop-v0 -- <fichier>  # récupérer un fichier ponctuellement
```

### Suite

Un projet séparé `kshop` sera créé dans une session ultérieure, conçu **from scratch** à partir des vrais besoins de l'utilisatrice active. Ces specs archivées servent de référence de l'ancien périmètre, pas de base de transfert.
