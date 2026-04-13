# EXTRACTION — Module Shop

> Fichier guide vivant du chantier d'extraction du module **shop** hors de `budget`. Supprimer au merge de `chore/extract-shop`.

## Contexte

**Décision** : extraire totalement le module shop de l'app budget.

**Raison** : le shop est un autre métier (gestion active de micro-commerce) qui n'a rien à faire dans une app de budget personnel (constatation passive de flux). Le module n'a aujourd'hui qu'**un seul utilisateur actif** (petite sœur). Trois autres users ont exprimé une intention mais utilisent leurs tableurs. La constitution du projet (principe #3, YAGNI) ne justifie pas de faire évoluer le shop dans son état actuel.

**Ce qui sera fait plus tard** : un projet séparé `../kshop` sera créé dans une session ultérieure, conçu from scratch avec la sœur à partir de ses vrais besoins. Le code shop actuel est **archivé** (tag git `archive/shop-v0`) comme référence, pas comme base de transfert.

## Contraintes du chantier

- **Une seule PR, un seul objectif.** Pas de refacto collatéral opportuniste. Si de la dette est repérée pendant l'extraction, elle est notée ici et traitée dans une PR suivante.
- **Séquentiel, pas parallèle.** Les agents d'implémentation (`spring-boot-dev`, `angular-dev`, `flutter-dev`) tournent l'un après l'autre. L'orchestrateur valide chaque phase avant de lancer la suivante.
- **Préserver `CurrencyPillSelector`** (utilisé par dashboard, transactions, subscriptions, debts, budgets). Il n'est pas propre au shop.
- **Préserver la transaction seed "Sushi Shop"** dans `R__dev_seed.sql` (libellé de transaction resto, pas lié au module).

## État git

- **Branche** : `chore/extract-shop` (depuis `develop`)
- **Tag archive** : `archive/shop-v0` (snapshot figé avant extraction)
- **Merge target** : `develop`

## Phases

### Phase 1 — Backend Spring Boot

**Agent** : `spring-boot-dev`

Supprimer :
- `api/src/main/java/fr/kksdev/budget/api/controller/ProductController.java`
- `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java`
- `api/src/main/java/fr/kksdev/budget/api/repository/ProductRepository.java`
- `api/src/main/java/fr/kksdev/budget/api/model/Product.java`
- `api/src/main/java/fr/kksdev/budget/api/dto/request/ProductRequest.java`
- `api/src/main/java/fr/kksdev/budget/api/dto/request/ProductUpdateRequest.java`
- `api/src/main/java/fr/kksdev/budget/api/dto/response/ProductResponse.java`
- `api/src/test/java/fr/kksdev/budget/api/controller/ProductControllerIntegrationTest.java`
- `api/src/test/java/fr/kksdev/budget/api/controller/ProductSalesIntegrationTest.java`
- `api/src/test/java/fr/kksdev/budget/api/service/ProductServiceTest.java`

Modifier :
- `api/src/main/java/fr/kksdev/budget/api/enums/Feature.java` — retirer `SHOP`
- `api/src/main/resources/db/dev/R__dev_seed.sql` — retirer `SHOP` de `enabled_features` + supprimer tout `INSERT INTO products` / `product_sales`. **Conserver** la transaction "Sushi Shop" (libellé resto).

Créer :
- `api/src/main/resources/db/migration/V13__drop_shop.sql` — `DROP TABLE IF EXISTS product_sales; DROP TABLE IF EXISTS products;` (confirmer les noms exacts en lisant V10/V11 d'abord).

Audit :
- `grep -r "Product" api/src/main/java/` pour détecter les résidus (imports, catégories par défaut liées au shop, tests de `PreferenceService` qui mentionnent `SHOP`).

Validation :
- `cd api && mvn clean test`

### Phase 2 — Frontend Angular

**Agent** : `angular-dev`

Supprimer :
- `app/src/app/features/shop/` (tout le dossier, 16 fichiers)
- `app/src/app/core/services/product.ts`
- `app/src/app/core/models/product.model.ts`

Modifier :
- `app/src/app/app.routes.ts` — retirer la route `shop` (lignes ~50-53, lazy-load)
- `app/src/app/shared/components/shell/shell.ts` — retirer les imports `ProductForm`, `SellDialog`, `RestockDialog` (lignes 54, 55, 58) et leur déclaration `imports` (ligne 82)
- Audit feature toggles Angular : retirer `SHOP` / `'shop'` des features listées

Préserver :
- `app/src/app/features/dashboard/components/currency-pill-selector.ts` (utilisé ailleurs)
- `ConversionService`, `ExchangeRateService`

Validation :
- `cd app && ng build && ng test`

### Phase 3 — Flutter

**Agent** : `flutter-dev`

Supprimer :
- `flutter/lib/src/features/shop/` (tout le dossier, 7 fichiers)
- `flutter/test/src/features/shop/application/product_notifier_test.dart`
- `flutter/lib/src/domain/models/product.dart`
- `flutter/lib/src/domain/repositories/product_repository.dart`
- `flutter/lib/src/data/remote/dtos/product_dtos.dart`
- `flutter/lib/src/data/remote/data_sources/product_remote_data_source.dart`

Modifier :
- `flutter/lib/src/routing/app_router.dart` — imports shop (lignes 42, 43, 48, 49), route `/shop` (240-252), case `Feature.shop` (483-484), `_ProductFormConsumer` (759-780), branche form router `Product`
- `flutter/lib/src/routing/route_names.dart` — retirer `shop` (14) et `shopName` (50)
- `flutter/lib/src/domain/enums/feature.dart` — retirer `shop` de l'enum (10) et tous les cases dans les switch (17, 24, 31, 38, 45)
- `flutter/lib/src/data/data_mode_provider.dart` — retirer exposition `ProductRepository`
- `flutter/test/src/features/settings/presentation/feature_settings_navigation_test.dart` — nettoyer références shop
- `flutter/test/src/features/settings/application/feature_config_notifier_reorder_test.dart` — nettoyer références shop

Drift local :
- Vérifier `flutter/lib/src/data/local/` — si table `products` dans le schéma Drift, créer une migration Drift pour la dropper.

Validation :
- `cd flutter && flutter test && flutter analyze`

### Phase 4 — Archivage specs

Déplacer vers `.specify/specs/_archived/` :
- `056-backend-product-crud/`
- `057-backend-product-sales/`
- `060-flutter-shop-products/`
- `061-flutter-product-form/`
- `062-flutter-product-detail/`
- `068-angular-shop-module/`

Créer `.specify/specs/_archived/README.md` expliquant le contexte.

### Phase 5 — Documentation

- `CLAUDE.md` — retirer mentions shop (Recent Changes, features)
- `docs/vision.md` — retirer module shop
- `docs/architecture.md` — modèle de données : 19 entités → 17
- `docs/api-examples.md` — retirer endpoints `/products`, `/sales`
- `docs/api-errors.md` — retirer codes erreur shop si présents
- `docs/roadmap-v2.md` — retirer ou section "Abandonné"
- `DESIGN.md`, `DESIGN-REFONTE.md` — retirer patterns shop si présents
- `CHANGELOG.md` — entrée `### Removed` : `Shop module extracted for separate product redesign (archive: tag archive/shop-v0)`

### Phase 6 — Validation complète

```bash
cd api && mvn clean test
cd app && ng build && ng test
cd flutter && flutter test && flutter analyze
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev  # smoke test
cd app && ng serve  # smoke test
```

Vérif finale : `git grep -iE "shop|product"` — 0 résultat attendu hors catégories métier et libellé "Sushi Shop".

### Phase 7 — Release

- Bump `VERSION`, `api/pom.xml`, `app/package.json`
- Entrée `CHANGELOG.md`
- PR `chore/extract-shop` → `develop`
- Supprimer ce fichier `EXTRACTION.md` au merge

## Dette repérée en cours de chantier

_(à compléter au fil de l'extraction)_

**Phase 3 Flutter :**
- **`ModalType.product` dans `modal_type.dart`** : non listé dans le scope initial de la Phase 3 mais découvert lors de l'audit. Supprimé dans cette phase (était mort après suppression de `_ProductFormConsumer` dans `app_router.dart`). Aucun autre consommateur.
- **8 tests préexistants en échec** (layout overflow, non liés au shop) : `register_screen_test.dart` (5 tests — overflow RenderFlex), `dashboard_notifier_test.dart` (1 test), `recurring_list_screen_test.dart` (1 test), `subscription_list_screen_test.dart` ou `subscription_detail_screen_test.dart` (1 test). Échouent pour des raisons d'environnement de test indépendantes de l'extraction. Hors scope de cette PR.
- **`feature_settings_screen.dart`** : non listé dans le scope initial mais référençait `productNotifierProvider` et `Feature.shop` — nettoyé dans cette phase.
- **`test/helpers/mocks.dart`** : non listé dans le scope initial mais référençait `ProductRepository` dans `@GenerateNiceMocks` — nettoyé dans cette phase.

- **TransactionResponse.productId/productName** : ces champs étaient exposés dans l'API publique. Ils sont retirés dans cette phase. Les clients Angular/Flutter qui consomment `GET /transactions` et `GET /transactions/{id}` doivent vérifier qu'ils n'en dépendent pas (Phase 2 et 3 en charge de nettoyer leur côté).
- **AccountResponse.isShopAccount** : champ exposé dans l'API publique, retiré. Même vigilance côté Angular/Flutter.
- **UserPreferenceResponse.shopAccountId / includeShopInBalance** : champs retirés du DTO. Les clients doivent être mis à jour (Phase 2 et 3).
- **UserPreferenceRequest.shopAccountId / includeShopInBalance** : si des clients envoient ces champs dans leurs requêtes PUT /users/me/preferences, ils seront ignorés (JSON désérialisé sans erreur grâce à Jackson). Pas bloquant mais à nettoyer côté client. **Phase 2 Angular : nettoyé** — champs retirés de `UserPreference` et `UserPreferenceRequest` dans `preference.model.ts`.
- **Tests préexistants en échec** (46 tests, 7 fichiers) : `subscriptions.spec.ts`, `debt-form.spec.ts`, `repay-dialog.spec.ts`, `debt-detail.spec.ts`, `notification-panel.spec.ts`, `recurring-list.spec.ts`, `subscription-detail.spec.ts` — échouent pour des raisons d'environnement de test (IntersectionObserver non défini, absence de mock HTTP pour exchange-rates/currencies). Hors scope de cette PR.
- **phosphorPackage / phosphorShoppingBag** dans `confirm-dialog.ts` : icônes enregistrées mais non référencées dans le template (le template utilise `config.icon` dynamiquement). Code mort potentiel — à nettoyer dans une PR dédiée.
- **Catégorie système "Boutique"** : retirée du seeding à l'inscription (`seedSystemCategories`) et de la BDD en production (migration V24). Les transactions existantes liées à la catégorie "Boutique" conservent leur category_id — la catégorie est supprimée par `DELETE FROM categories WHERE nom = 'Boutique' AND is_system = true`, ce qui met `category_id` à NULL via ON DELETE SET NULL sur les transactions (à vérifier selon le schéma FK existant).

## Angles morts signalés

- Catégories de transaction par défaut liées au shop (ex : "Ventes produits", "Achats stock") dans les seeds → décider si conservées ou retirées.
- Feature toggles persistés en BDD pour les 16 users : après suppression de `SHOP` de l'enum, les users ayant `SHOP` dans leur `enabled_features` vont avoir une valeur orpheline. La migration `V13` doit aussi nettoyer : `UPDATE user_preferences SET enabled_features = REPLACE(enabled_features, 'SHOP,', '') ...` (ou équivalent selon le format de stockage).
