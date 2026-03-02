# Tasks: Écran Boutique — Liste produits + stock (Flutter)

**Input**: Design documents from `/specs/060-flutter-shop-products/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/product-api.md

**Tests**: Tests unitaires du ProductNotifier (constitution V — testabilité).

**Organization**: Tasks groupées par user story. US2, US3 et US4 sont intrinsèquement intégrées dans l'écran ProductListScreen (US1) car elles correspondent à des interactions UI (navigation no-op, pull-to-refresh) déjà couvertes par le pattern standard.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts dans les descriptions

---

## Phase 1: Foundational — Domain & Data Layer

**Purpose**: Créer le modèle Product, les DTOs, le repository et la data source. Prérequis bloquant pour toutes les user stories.

**⚠️ CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase.

- [x] T001 [P] Create Product Freezed model in `flutter/lib/src/domain/models/product.dart` — Champs: id (String), nom, description?, icone?, imageUrl?, prixAchat (double), prixVente (double), stock (int), totalVendu (int), actif (bool), createdAt (DateTime?), updatedAt (DateTime?). Ajouter `export 'product.dart';` dans `flutter/lib/src/domain/models/models.dart`

- [x] T002 [P] Create Product DTOs (Freezed + json_serializable) in `flutter/lib/src/data/remote/dtos/product_dtos.dart` — Trois classes: ProductRequest (création: nom, description?, icone?, imageUrl?, prixAchat, prixVente, stock), ProductUpdateRequest (idem + actif), ProductResponse (tous les champs du modèle, dates en String?). Pattern: voir `flutter/lib/src/data/remote/dtos/subscription_dtos.dart`

- [x] T003 [P] Create ProductRepository abstract interface in `flutter/lib/src/domain/repositories/product_repository.dart` — Méthodes: `Future<List<Product>> getAll()`, `Future<Product> getById(String id)`, `Future<Product> create(Product product)`, `Future<Product> update(Product product)`, `Future<void> delete(String id)`. Ajouter `export 'product_repository.dart';` dans `flutter/lib/src/domain/repositories/repositories.dart`. Pattern: voir `flutter/lib/src/domain/repositories/subscription_repository.dart`

- [x] T004 [P] Create ProductRemoteDataSource (Dio HTTP client) in `flutter/lib/src/data/remote/data_sources/product_remote_data_source.dart` — Endpoints: `GET /products` (getAll), `GET /products/{id}` (getById), `POST /products` (create), `PUT /products/{id}` (update), `DELETE /products/{id}` (delete). Pattern: voir `flutter/lib/src/data/remote/data_sources/subscription_remote_data_source.dart`

- [x] T005 Create ProductRepositoryRemote implementation in `flutter/lib/src/features/shop/data/product_repository_remote.dart` — Injecte ProductRemoteDataSource. Mappers DTO → Domain: `_toDomain(ProductResponse)` (parse DateTime strings), `_toRequest(Product)` → ProductRequest, `_toUpdateRequest(Product)` → ProductUpdateRequest. Pattern: voir `flutter/lib/src/features/subscriptions/data/subscription_repository_remote.dart`

- [x] T006 Add productRepositoryProvider (server-only) in `flutter/lib/src/data/data_mode_provider.dart` — Provider<ProductRepository> qui utilise authenticatedDioProvider pour instancier ProductRepositoryRemote(ProductRemoteDataSource(dio)). Pas de fallback local (server-only). Ajouter les imports nécessaires.

- [x] T007 Run `cd flutter && dart run build_runner build --delete-conflicting-outputs` — Génère les fichiers `.freezed.dart` et `.g.dart` pour Product model et DTOs. Vérifier que la compilation passe: `cd flutter && flutter analyze`

**Checkpoint**: Domain + Data layer prêts. Le repository peut charger des produits depuis l'API.

---

## Phase 2: User Story 1 — Consulter la liste des produits (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur ouvre l'écran Boutique et voit la liste de ses produits actifs avec icône, nom, prix de vente, stock et ventes. Inclut les états loading (shimmer), vide (CTA), erreur (retry), et rupture de stock (opacité réduite).

**Independent Test**: Ouvrir l'écran Boutique → les produits s'affichent avec les 4 informations clés. Tester les 3 états (loading, empty, error) + pull-to-refresh.

### Implementation for User Story 1

- [x] T008 [P] [US1] Create ProductListState Freezed state model in `flutter/lib/src/features/shop/application/product_list_state.dart` — Champs: items (List<Product>, default []), isLoading (bool, default false), error (String?, default null), currentPage (int, default 0), hasMore (bool, default true), mutatingIds (Set<String>, default {}). Pattern: voir `flutter/lib/src/features/subscriptions/application/subscription_list_state.dart`

- [x] T009 [US1] Create ProductNotifier in `flutter/lib/src/features/shop/application/product_notifier.dart` — `NotifierProvider<ProductNotifier, ProductListState>`. Méthodes: `loadItems()` (getAll + tri alphabétique par nom + _refreshPage), `refresh()` (alias loadItems), `create(Product)`, `update(Product)`, `delete(String id)` avec optimistic updates et mutatingIds. `_pageSize = 20`, `_allItems` interne. `loadMore()` pour pagination client-side. Pattern exact: voir `flutter/lib/src/features/subscriptions/application/subscription_notifier.dart` — SANS filtre (pas de SegmentedFilter pour la boutique) et SANS summary computation.

- [x] T010 [US1] Run `cd flutter && dart run build_runner build --delete-conflicting-outputs` — Génère ProductListState.freezed.dart

- [x] T011 [US1] Create ProductListScreen in `flutter/lib/src/features/shop/presentation/product_list_screen.dart` — `ConsumerStatefulWidget`. initState: charger produits via `ref.read(productNotifierProvider.notifier).loadItems()`. Build: `RefreshIndicator` + `CustomScrollView` avec Slivers. 4 états:
  1. **Loading**: `List.generate(5, (_) => const ListItem.skeleton())` (shimmer)
  2. **Error**: Icône erreur + message + bouton retry (`ref.read(...).refresh()`)
  3. **Empty**: Icône storefront + "Aucun produit" + bouton CTA "Créer un produit" (no-op pour l'instant)
  4. **Data**: `SliverList.builder` avec `ListItem` pour chaque produit:
     - `icon`: `product.icone ?? '📦'`
     - `title`: `product.nom`
     - `value`: `AmountFormatter.format(product.prixVente, currency: currency)`
     - `subtitle`: `'Stock: ${product.stock}'`
     - `rightSubtitle`: `product.stock == 0 ? 'Rupture' : '${product.totalVendu} ventes'`
     - `onPressed`: navigation vers détail (no-op)
     - Rupture de stock: envelopper le `ListItem` dans `Opacity(opacity: product.stock == 0 ? 0.5 : 1.0)`
  5. Padding final `SliverToBoxAdapter(child: SizedBox(height: 96))` pour le FAB
  Pattern: voir `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart`

**Checkpoint**: US1 complète — l'écran affiche les produits avec tous les états. Pull-to-refresh fonctionne (US4). Navigation no-op préparée (US2/US3).

---

## Phase 3: User Story 2 — Navigation création (Priority: P1)

**Goal**: Le CTA de l'état vide navigue vers le formulaire de création de produit. Le FAB global reste dédié aux entrées budgétaires.

**Independent Test**: Appuyer sur le CTA "Créer un produit" dans l'état vide → no-op (formulaire non implémenté, KKS futur).

> **Note**: La navigation création est intégrée dans ProductListScreen (T011) comme no-op. Le `create()` du NotifierProvider est implémenté dans T009 pour usage futur. Le FAB au niveau shell n'a pas besoin de modification — la Boutique n'utilise pas le système de modales (FabMenu). Aucune tâche supplémentaire requise.

---

## Phase 4: User Story 3 — Navigation détail (Priority: P2)

**Goal**: Tap sur un produit dans la liste → navigation vers l'écran de détail (KKS-125).

**Independent Test**: Taper sur un produit → no-op (écran détail non implémenté).

> **Note**: Le `onPressed` du ListItem est intégré dans ProductListScreen (T011) comme no-op. La route `/shop/:id` sera ajoutée dans une feature ultérieure (KKS-125). Aucune tâche supplémentaire requise.

---

## Phase 5: User Story 4 — Rafraîchir la liste (Priority: P3)

**Goal**: Pull-to-refresh recharge les produits depuis le serveur.

**Independent Test**: Tirer vers le bas → indicateur de rafraîchissement → données rechargées.

> **Note**: Le `RefreshIndicator` est intégré dans ProductListScreen (T011), appelant `notifier.refresh()` implémenté dans T009. Aucune tâche supplémentaire requise.

---

## Phase 6: Polish & Integration

**Purpose**: Wiring final du router et validation

- [x] T012 Update `flutter/lib/src/routing/app_router.dart` — Remplacer le placeholder Shop (lignes 181-187, `Scaffold(body: Center(child: Text('Boutique — À venir')))`) par `const ProductListScreen()`. Ajouter l'import `package:k_budget/src/features/shop/presentation/product_list_screen.dart`.

- [x] T013 Run `cd flutter && flutter analyze` — Vérifier qu'il n'y a aucune erreur d'analyse statique. Corriger les warnings éventuels.

---

## Phase 7: Tests

**Purpose**: Tests unitaires du ProductNotifier (constitution V — testabilité)

- [x] T014 [US1] Create ProductNotifier unit tests in `flutter/test/src/features/shop/application/product_notifier_test.dart` — Tests: `should_load_products_sorted_by_name_when_loadItems_called`, `should_set_loading_true_when_loading`, `should_set_error_when_load_fails`, `should_add_product_when_create_called`, `should_refresh_items_when_refresh_called`. Setup: `ProviderContainer` avec `productRepositoryProvider` overridden par un mock. Pattern: voir `flutter/test/src/features/subscriptions/application/subscription_notifier_test.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Pas de dépendance — démarrage immédiat
- **US1 (Phase 2)**: Dépend de Phase 1 (T007 code gen doit être terminé)
- **US2/US3/US4 (Phases 3-5)**: Intégrées dans US1 — pas de tâches séparées
- **Polish (Phase 6)**: Dépend de Phase 2 (écran doit exister pour le wiring)
- **Tests (Phase 7)**: Dépend de Phase 2 (T009 notifier doit exister)

### Within Phase 1 (Foundational)

```
T001 ─┐
T002 ─┤
T003 ─┼─→ T005 (repo remote needs interface + data source)
T004 ─┘         ↓
              T006 (provider needs repo remote)
                ↓
              T007 (build_runner after all Freezed files)
```

### Within Phase 2 (US1)

```
T008 ─→ T010 (build_runner after state Freezed)
           ↓
T009 ─→ T011 (screen needs notifier)
           ↓
         T012 (router wiring)
           ↓
         T013 (final validation)
```

### Parallel Opportunities

```bash
# Phase 1 — 4 fichiers indépendants en parallèle:
T001: Product model (flutter/lib/src/domain/models/product.dart)
T002: Product DTOs (flutter/lib/src/data/remote/dtos/product_dtos.dart)
T003: ProductRepository interface (flutter/lib/src/domain/repositories/product_repository.dart)
T004: ProductRemoteDataSource (flutter/lib/src/data/remote/data_sources/product_remote_data_source.dart)

# Phase 2 — T008 en parallèle avec T009 (fichiers différents):
T008: ProductListState (flutter/lib/src/features/shop/application/product_list_state.dart)
T009: ProductNotifier (flutter/lib/src/features/shop/application/product_notifier.dart)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (T001-T007)
2. Complete Phase 2: US1 (T008-T011)
3. Complete Phase 6: Polish (T012-T013)
4. Complete Phase 7: Tests (T014)
5. **STOP and VALIDATE**: Activer Feature.shop dans Settings → onglet Boutique visible → liste produits fonctionne

### Incremental Delivery

1. Phase 1 → Data layer prête
2. Phase 2 → Écran fonctionnel (MVP) avec tous les états
3. Phase 6 → Router branché, app compilable et testable
4. Futures features (KKS-125 détail, formulaire) → remplacent les no-ops

---

## Notes

- [P] tasks = fichiers différents, pas de dépendance
- US2/US3/US4 sont intrinsèquement intégrées dans l'écran ProductListScreen (T011) car ce sont des interactions UI (navigation no-op, pull-to-refresh) couvertes par le pattern standard
- Le Notifier inclut d'emblée create/update/delete pour préparer les features futures (KKS-125, formulaire)
- Server-only: pas de Drift/SQLite — pas de RepositoryLocal ni de DAO
- 2 passages build_runner: après Phase 1 (models + DTOs) et après Phase 2 (state)
- Commit recommandé après chaque phase
- T014 (tests) peut être exécuté en parallèle avec Phase 6 (fichiers indépendants)
