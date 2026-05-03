# Tasks: Endpoints ventes et stock produits

**Input**: Design documents from `/specs/057-backend-product-sales/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Inclus — la constitution (principe V: Testabilite) exige des tests d'integration sur les endpoints et des tests unitaires sur les services.

**Organization**: Tasks groupees par user story pour permettre implementation et test independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'executer en parallele (fichiers differents, pas de dependance)
- **[Story]**: User story concernee (US1, US2, US3)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Setup (Infrastructure partagee)

**Purpose**: Migration BDD, exception 409, modifications entites et DTOs — prerequis pour toutes les user stories

- [x] T001 Creer la migration Flyway V11 dans `api/src/main/resources/db/migration/V11__add_shop_support.sql` — categorie systeme "Boutique" pour users existants, colonne `product_id` (FK nullable) sur `transactions`, colonnes `shop_account_id` et `include_shop_in_balance` sur `user_preferences` (cf. data-model.md section Migration)
- [x] T002 [P] Creer `ConflictException` dans `api/src/main/java/fr/kksdev/budget/api/exception/ConflictException.java` — exception runtime pour les conflits d'etat (stock epuise, produit inactif)
- [x] T003 [P] Ajouter le handler `ConflictException` → HTTP 409 dans `api/src/main/java/fr/kksdev/budget/api/config/GlobalExceptionHandler.java` — meme format que les autres handlers (`Map {timestamp, status, message}`)
- [x] T004 [P] Ajouter le champ `product` (`@ManyToOne(fetch = LAZY)`, `@JoinColumn(name = "product_id")`, nullable) sur l'entite `Transaction` dans `api/src/main/java/fr/kksdev/budget/api/model/Transaction.java`
- [x] T005 [P] Ajouter les champs `shopAccountId` (UUID nullable, `@Column(name = "shop_account_id")`) et `includeShopInBalance` (Boolean, default false, `@Column(name = "include_shop_in_balance")`) sur l'entite `UserPreference` dans `api/src/main/java/fr/kksdev/budget/api/model/UserPreference.java`
- [x] T006 [P] Creer le DTO `RestockRequest` dans `api/src/main/java/fr/kksdev/budget/api/dto/RestockRequest.java` — record avec champ `quantity` (`@NotNull @Positive Integer`)
- [x] T007 [P] Enrichir `TransactionResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/TransactionResponse.java` — ajouter champs `productId` (UUID nullable) et `productName` (String nullable)
- [x] T008 [P] Enrichir `AccountResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/AccountResponse.java` — ajouter champ `isShopAccount` (boolean)
- [x] T009 [P] Enrichir `UserPreferenceResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/UserPreferenceResponse.java` — ajouter champs `shopAccountId` (UUID nullable) et `includeShopInBalance` (Boolean)
- [x] T010 [P] Enrichir `UserPreferenceRequest` dans `api/src/main/java/fr/kksdev/budget/api/dto/UserPreferenceRequest.java` — ajouter champs optionnels `shopAccountId` (UUID nullable) et `includeShopInBalance` (Boolean nullable)

**Checkpoint**: Schema BDD pret, entites et DTOs a jour, exception 409 disponible

---

## Phase 2: Foundational (Prerequis bloquants)

**Purpose**: Services de support (categorie, preferences, compte) necessaires AVANT les endpoints de vente/restock

**CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase

**Note**: La methode `checkShopEnabled(UUID userId)` existe deja dans `ProductService` (KKS-118). Elle verifie que `Feature.SHOP` est dans les `enabledFeatures` de l'utilisateur et leve une `AccessDeniedException` (403) si absente. Les taches T018, T021, T024 l'appellent directement.

- [x] T011 Ajouter la categorie "Boutique" dans `CategoryService.seedSystemCategories()` dans `api/src/main/java/fr/kksdev/budget/api/service/CategoryService.java` — icone 🛍️, couleur #f59e0b, `isSystem = true`. Suivre le pattern exact des categories "Abonnement", "Dette", "Virement"
- [x] T012 [P] Ajouter la methode `findOrCreateShopCategory(UUID userId)` dans `CategoryService` — pattern lazy-create identique a `findOrCreateAdjustmentCategory`. Retourne la categorie systeme "Boutique" existante ou la cree si absente
- [x] T013 [P] Enrichir `PreferenceService` dans `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java` — mettre a jour `getOrCreate()` pour initialiser `includeShopInBalance = false`. Mettre a jour `updatePreferences()` pour accepter `shopAccountId` (avec validation: compte existant + appartient a l'utilisateur) et `includeShopInBalance`. Mettre a jour `toResponse()` pour inclure les deux nouveaux champs
- [x] T014 Ajouter la methode `getOrCreateShopAccount(UUID userId)` dans `ProductService` dans `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java` — si `shopAccountId` est null dans les preferences, creer un compte "Boutique" (type COURANT, icone 🛍️, couleur #f59e0b, soldeInitial = 0, actif = true) via `AccountService`, puis sauvegarder le `shopAccountId` dans les preferences via `PreferenceService`. Sinon retourner le compte existant. (Placement pragmatique dans ProductService car c'est le seul consommateur — evite un service dedie pour une seule methode, conforme au principe III YAGNI). **Depend de T013** (PreferenceService enrichi pour gerer shopAccountId)
- [x] T015 [P] Ajouter la methode `findByProductIdAndUserId(UUID productId, UUID userId)` dans `TransactionRepository` dans `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java` — retourne `List<Transaction>` triee par date decroissante. Requete JPQL filtrant sur `product.id` et `user.id`
- [x] T016 Enrichir `AccountService.toResponse()` dans `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java` — ajouter le parametre `UUID shopAccountId` (recupere depuis les preferences) pour calculer `isShopAccount` (`account.getId().equals(shopAccountId)`). Mettre a jour tous les appels a `toResponse()` dans le service
- [x] T017 Enrichir `TransactionService.toResponse()` dans `api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java` — mapper `productId` et `productName` depuis la relation `transaction.getProduct()` (nullable). Mettre a jour le mapping existant

**Checkpoint**: Fondation prete — services categorie, preferences, compte et repository disponibles pour les user stories

---

## Phase 3: User Story 1 — Vendre un produit (Priority: P1) MVP

**Goal**: Enregistrer une vente unitaire qui decremente le stock, incremente totalVendu, et cree une transaction RECETTE automatique

**Independent Test**: Creer un produit avec stock > 0, appeler POST /products/{id}/sell, verifier stock -= 1, totalVendu += 1, transaction RECETTE creee avec montant = prixVente

### Implementation

- [x] T018 [US1] Implementer `sell(UUID productId, UUID userId)` dans `ProductService` — verifier `checkShopEnabled`, trouver le produit (404 si inexistant/autre user), verifier `actif` (409 ConflictException si inactif), verifier `stock > 0` (409 ConflictException si stock = 0), decrementer stock, incrementer totalVendu, appeler `getOrCreateShopAccount`, appeler `findOrCreateShopCategory`, creer une Transaction (type RECETTE, montant = prixVente, libelle = "Vente: {nom}", date = LocalDate.now(), product = product, account = shopAccount, category = shopCategory), sauvegarder tout en `@Transactional`, retourner ProductResponse
- [x] T019 [US1] Ajouter le endpoint `POST /products/{id}/sell` dans `ProductController` dans `api/src/main/java/fr/kksdev/budget/api/controller/ProductController.java` — appeler `productService.sell(id, userId)`, retourner 200 avec ProductResponse

### Tests

- [x] T020 [US1] Creer `ProductSalesIntegrationTest` dans `api/src/test/java/fr/kksdev/budget/api/controller/ProductSalesIntegrationTest.java` — tests d'integration pour le endpoint sell: `should_sell_product_when_stock_available` (200, stock -= 1, totalVendu += 1, transaction RECETTE creee), `should_return_409_when_stock_is_zero`, `should_return_409_when_product_inactive`, `should_return_404_when_product_not_found`, `should_create_shop_account_on_first_sell` (verifier creation lazy du compte), `should_return_403_when_shop_feature_disabled` (desactiver SHOP dans les preferences, verifier 403 Forbidden — un seul test 403 suffit car le mecanisme `checkShopEnabled` est commun aux 3 endpoints)

**Checkpoint**: US1 fonctionnelle — vente unitaire avec creation auto de transaction, compte et categorie

---

## Phase 4: User Story 2 — Restocker un produit (Priority: P2)

**Goal**: Ajouter du stock avec creation automatique d'une transaction DEPENSE refletant le cout d'achat

**Independent Test**: Creer un produit avec stock = 0, appeler POST /products/{id}/restock avec quantity = 10, verifier stock = 10, transaction DEPENSE creee avec montant = prixAchat * 10

### Implementation

- [x] T021 [US2] Implementer `restock(UUID productId, RestockRequest request, UUID userId)` dans `ProductService` — verifier `checkShopEnabled`, trouver le produit (404), verifier `actif` (409 si inactif), incrementer stock de `request.quantity()`, appeler `getOrCreateShopAccount` et `findOrCreateShopCategory`, creer une Transaction (type DEPENSE, montant = prixAchat * quantity, libelle = "Stock: {nom} x{quantity}", date = LocalDate.now(), product = product), sauvegarder en `@Transactional`, retourner ProductResponse
- [x] T022 [US2] Ajouter le endpoint `POST /products/{id}/restock` dans `ProductController` — accepter `@Valid @RequestBody RestockRequest`, appeler `productService.restock(id, request, userId)`, retourner 200 avec ProductResponse

### Tests

- [x] T023 [US2] Ajouter les tests restock dans `ProductSalesIntegrationTest` — `should_restock_product_when_active` (200, stock += N, transaction DEPENSE creee avec montant = prixAchat * N), `should_return_400_when_quantity_zero`, `should_return_400_when_quantity_negative`, `should_return_409_when_product_inactive_restock`

**Checkpoint**: US2 fonctionnelle — restockage avec transaction DEPENSE automatique

---

## Phase 5: User Story 3 — Consulter l'historique des ventes (Priority: P3)

**Goal**: Retourner la liste des transactions de vente liees a un produit, triees par date decroissante

**Independent Test**: Creer un produit, enregistrer 3 ventes, appeler GET /products/{id}/sales, verifier 3 transactions RECETTE retournees triees par date DESC

### Implementation

- [x] T024 [US3] Implementer `getSalesHistory(UUID productId, UUID userId)` dans `ProductService` — verifier `checkShopEnabled`, trouver le produit (404), appeler `transactionRepository.findByProductIdAndUserId(productId, userId)`, filtrer par type RECETTE (ventes uniquement), mapper en `List<TransactionResponse>`, retourner la liste
- [x] T025 [US3] Ajouter le endpoint `GET /products/{id}/sales` dans `ProductController` — appeler `productService.getSalesHistory(id, userId)`, retourner 200 avec la liste

### Tests

- [x] T026 [US3] Ajouter les tests historique dans `ProductSalesIntegrationTest` — `should_return_sales_history_ordered_by_date_desc`, `should_return_empty_list_when_no_sales`, `should_return_404_when_product_not_found_sales`, `should_return_404_when_product_belongs_to_other_user` (isolation cross-user — verifier qu'un utilisateur ne peut pas consulter l'historique d'un produit d'un autre utilisateur)

**Checkpoint**: US3 fonctionnelle — historique des ventes consultable par produit

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Rollback stock, logging, validation finale

- [x] T027 Enrichir `TransactionService.delete()` dans `api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java` — AVANT la suppression, si `transaction.getProduct() != null` : type RECETTE → `product.stock += 1`, `product.totalVendu -= 1` ; type DEPENSE → `product.stock -= (montant / product.prixAchat).intValue()` (prixAchat est toujours > 0 grace a `@Positive`, pas de risque de division par zero). Sauvegarder le produit. Gerer le cas ou le produit a ete supprime (product == null → pas de rollback). **Limitations documentees** : (1) le rollback DEPENSE utilise le prixAchat actuel — si le prix a ete modifie apres le restock, la quantite rollbackee peut differer de l'originale ; (2) le stock peut devenir negatif apres rollback d'un restock si des ventes ont eu lieu entre-temps — la valeur negative est acceptee (app mono-utilisateur, cas rare, corrigeable par un nouveau restock)
- [x] T028 [P] Ajouter le logging INFO dans `ProductService` pour les operations sell et restock — logger userId, productId, productName, stock avant/apres, montant transaction. Logger ERROR sur les cas de refus (stock = 0, inactif). Utiliser SLF4J (`@Slf4j` Lombok)
- [x] T029 [P] Ajouter les tests de rollback stock dans `ProductSalesIntegrationTest` — `should_rollback_stock_when_sale_transaction_deleted` (stock += 1, totalVendu -= 1), `should_rollback_stock_when_restock_transaction_deleted` (stock -= N)
- [x] T030 [P] Ajouter le test `should_flag_shop_account_in_account_response` dans `ProductSalesIntegrationTest` — apres creation lazy du compte Boutique, verifier que GET /accounts retourne le compte avec `isShopAccount = true` et les autres comptes avec `isShopAccount = false`
- [x] T031 [P] Creer `ProductServiceTest` dans `api/src/test/java/fr/kksdev/budget/api/service/ProductServiceTest.java` — tests unitaires avec mocks (Mockito) : `should_sell_product_when_stock_available`, `should_throw_conflict_when_stock_zero`, `should_throw_conflict_when_product_inactive_sell`, `should_restock_product_when_active`, `should_throw_conflict_when_product_inactive_restock`, `should_create_shop_account_on_first_operation`, `should_return_sales_history_filtered_by_recette`
- [x] T032 Verifier la compilation et executer `cd api && mvn clean test` — tous les tests existants + nouveaux doivent passer

**Checkpoint**: Feature complete — tous les endpoints fonctionnels, rollback stock operationnel, logging en place

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dependance — demarrage immediat
- **Foundational (Phase 2)**: Depend de Phase 1 (entites et DTOs a jour)
- **US1 (Phase 3)**: Depend de Phase 2 (services fondation)
- **US2 (Phase 4)**: Depend de Phase 2 — independant de US1
- **US3 (Phase 5)**: Depend de Phase 2 — independant de US1/US2 (mais mieux apres US1 pour avoir des ventes a consulter)
- **Polish (Phase 6)**: Depend de US1 + US2 (rollback stock necessite sell + restock)

### User Story Dependencies

- **US1 (P1)**: Peut demarrer apres Phase 2 — aucune dependance sur d'autres stories
- **US2 (P2)**: Peut demarrer apres Phase 2 — aucune dependance sur US1
- **US3 (P3)**: Peut demarrer apres Phase 2 — independant mais plus pertinent apres US1

### Within Each User Story

- Service avant controller
- Controller avant tests d'integration
- Tests en dernier (verifient le endpoint complet)

### Parallel Opportunities

- Phase 1: T002-T010 tous parallelisables (fichiers differents)
- Phase 2: T012, T013, T015 parallelisables (services differents) — T014 depend de T013
- US1 et US2 parallelisables apres Phase 2 (endpoints differents)
- Phase 6: T028, T029, T030, T031 parallelisables

---

## Parallel Example: Phase 1

```bash
# Tous ces fichiers sont independants — execution parallele:
Task: "T002 — ConflictException"
Task: "T004 — Transaction.product field"
Task: "T005 — UserPreference shop fields"
Task: "T006 — RestockRequest DTO"
Task: "T007 — TransactionResponse enrichment"
Task: "T008 — AccountResponse enrichment"
Task: "T009 — UserPreferenceResponse enrichment"
Task: "T010 — UserPreferenceRequest enrichment"
```

## Parallel Example: US1 + US2

```bash
# Apres Phase 2, ces deux stories sont independantes:
Task: "US1 — T018 sell service + T019 sell endpoint + T020 tests"
Task: "US2 — T021 restock service + T022 restock endpoint + T023 tests"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001-T010)
2. Phase 2: Foundational (T011-T017)
3. Phase 3: US1 — Vendre un produit (T018-T020)
4. **STOP et VALIDER**: Tester la vente de bout en bout
5. Deployer si pret

### Incremental Delivery

1. Setup + Foundational → Fondation prete
2. US1 (vente) → Tester → Deploy (MVP)
3. US2 (restock) → Tester → Deploy
4. US3 (historique) → Tester → Deploy
5. Polish (rollback, logging) → Tests finaux → Deploy

---

## Notes

- [P] = fichiers differents, pas de dependance
- [US*] = tracabilite vers la user story
- Chaque user story est testable independamment apres Phase 2
- Commiter apres chaque tache ou groupe logique
- Stop a chaque checkpoint pour valider
