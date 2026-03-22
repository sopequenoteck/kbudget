# Tasks: Entité Product + CRUD complet (Backend)

**Input**: Design documents from `/specs/056-backend-product-crud/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/products-api.md

**Tests**: Inclus — requis par SC-005 et le principe V (Testabilité) de la constitution.

**Organization**: Tâches groupées par user story pour permettre l'implémentation et le test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story concernée (US1, US2, US3, US4, US5)
- Chemins exacts inclus dans chaque description

## Path Conventions

- **Backend**: `api/src/main/java/fr/kksdev/budget/api/` (abrégé `api/.../`)
- **Tests**: `api/src/test/java/fr/kksdev/budget/api/` (abrégé `test/.../`)
- **Migrations**: `api/src/main/resources/db/migration/`

---

## Phase 1: Setup (Migration)

**Purpose**: Créer la table `products` en base de données

- [X] T001 Create Flyway migration `api/src/main/resources/db/migration/V10__add_products.sql` — table `products` avec colonnes (id UUID PK, nom VARCHAR(100) NOT NULL, description VARCHAR(500), icone VARCHAR(10), image_url VARCHAR(500), prix_achat NUMERIC(12,2) NOT NULL, prix_vente NUMERIC(12,2) NOT NULL, stock INTEGER NOT NULL DEFAULT 0, total_vendu INTEGER NOT NULL DEFAULT 0, actif BOOLEAN NOT NULL DEFAULT true, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, user_id UUID NOT NULL FK → users(id) ON DELETE CASCADE). Index : `idx_products_user_id` et `idx_products_user_actif`. Cf. `data-model.md` pour le DDL exact.

---

## Phase 2: Foundational (Bloquants)

**Purpose**: Infrastructure partagée par toutes les user stories — DOIT être complétée avant toute implémentation CRUD

- [X] T002 [P] Create `FeatureDisabledException` in `api/src/main/java/fr/kksdev/budget/api/exception/FeatureDisabledException.java` — exception runtime avec champ `featureName` (String). Message : "Fonctionnalité {featureName} désactivée". Cf. research.md R2.
- [X] T003 [P] Create `Product` entity in `api/src/main/java/fr/kksdev/budget/api/model/Product.java` — annotations `@Entity @Table(name = "products") @Data @NoArgsConstructor @AllArgsConstructor @Builder`. Champs : id (UUID, `@GeneratedValue(strategy = GenerationType.UUID)`), nom, description, icone, imageUrl (`@Column(name = "image_url")`), prixAchat (`@Column(name = "prix_achat", nullable = false, precision = 12, scale = 2)`), prixVente (idem), stock, totalVendu (`@Column(name = "total_vendu")`), actif (`@Builder.Default private Boolean actif = true`), createdAt (`@CreationTimestamp @Column(nullable = false, updatable = false)`), updatedAt (`@UpdateTimestamp`), user (`@ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false)`). Cf. data-model.md.
- [X] T004 [P] Create `ProductResponse` record in `api/src/main/java/fr/kksdev/budget/api/dto/response/ProductResponse.java` — champs : id (UUID), nom, description, icone, imageUrl, prixAchat (BigDecimal), prixVente (BigDecimal), stock (Integer), totalVendu (Integer), actif (Boolean), createdAt (LocalDateTime), updatedAt (LocalDateTime). Cf. contracts/products-api.md.
- [X] T005 [P] Create `ProductRepository` interface in `api/src/main/java/fr/kksdev/budget/api/repository/ProductRepository.java` — extends `JpaRepository<Product, UUID>`. Méthodes : `List<Product> findByUserIdAndActifTrueOrderByCreatedAtDesc(UUID userId)`.
- [X] T006 Add `FeatureDisabledException` handler in `api/src/main/java/fr/kksdev/budget/api/config/GlobalExceptionHandler.java` — méthode `handleFeatureDisabled(FeatureDisabledException ex)` retournant 403 FORBIDDEN avec body `errorBody(403, ex.getMessage())`. Logger `log.warn("Feature disabled: {}", ex.getMessage())`. Dépend de T002.
- [X] T007 Add `isFeatureEnabled(UUID userId, Feature feature)` method in `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java` — retourne `boolean`. Utilise `getOrCreate(userId)` pour charger (ou créer avec les défauts) les préférences utilisateur, puis vérifie si `enabledFeatures` contient la feature. Garantit que les nouveaux utilisateurs bénéficient des features par défaut (dont SHOP). Cf. research.md R1.
- [X] T008 Create `ProductService` skeleton in `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java` — annotations `@Slf4j @Service @RequiredArgsConstructor @Transactional(readOnly = true)`. Inject : `ProductRepository`, `UserRepository`, `PreferenceService`. Méthodes privées : `checkShopEnabled(UUID userId)` (appelle `preferenceService.isFeatureEnabled(userId, Feature.SHOP)`, lève `FeatureDisabledException("SHOP")` si false), `findByIdAndUser(UUID id, UUID userId)` (récupère produit + vérifie propriétaire, lève `EntityNotFoundException`), `toResponse(Product)` (mappe entité vers `ProductResponse`). Dépend de T002-T005, T007.

**Checkpoint**: Infrastructure prête — l'implémentation des user stories peut commencer.

---

## Phase 3: User Story 1 — Créer un produit (Priority: P1)

**Goal**: L'utilisateur peut créer un produit avec nom, prix d'achat, prix de vente et stock via POST /products.

**Independent Test**: Envoyer POST avec champs obligatoires → produit retourné avec UUID, actif=true, totalVendu=0, timestamps.

### Implementation

- [X] T009 [P] [US1] Create `ProductRequest` record in `api/src/main/java/fr/kksdev/budget/api/dto/request/ProductRequest.java` — champs : nom (`@NotBlank @Size(max = 100)`), description (`@Size(max = 500)`), icone (String, nullable), imageUrl (`@Size(max = 500)`), prixAchat (`@NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal`), prixVente (`@NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal`), stock (`@NotNull @Min(0) Integer`). Cf. contracts/products-api.md POST request.
- [X] T010 [US1] Implement `create(ProductRequest request, UUID userId)` method in `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java` — annoté `@Transactional`. Appelle `checkShopEnabled(userId)`. Build `Product` via builder (nom, description, icone, imageUrl, prixAchat, prixVente, stock, actif=true, totalVendu=0, user=userRepository.getReferenceById(userId)). Save et log.info("Produit créé: {} pour userId {}", id, userId). Retourne `toResponse(product)`. Dépend de T008, T009.
- [X] T011 [US1] Create `ProductController` with POST endpoint in `api/src/main/java/fr/kksdev/budget/api/controller/ProductController.java` — annotations `@Slf4j @RestController @RequestMapping("/products") @RequiredArgsConstructor @Tag(name = "Produits", description = "CRUD produits boutique")`. Inject `ProductService`. Méthode `create(@Valid @RequestBody ProductRequest request, Authentication authentication)` → extraire userId, retourner `ResponseEntity.status(HttpStatus.CREATED).body(productService.create(request, userId))`. Annoter `@Operation(summary = "Créer un produit")`. Dépend de T010.

**Checkpoint**: POST /products fonctionne. Un produit peut être créé et persisté.

---

## Phase 4: User Story 2 — Lister ses produits (Priority: P1)

**Goal**: L'utilisateur peut voir la liste de ses produits actifs via GET /products.

**Independent Test**: Créer plusieurs produits → GET /products retourne uniquement les produits actifs de l'utilisateur authentifié, triés par date de création décroissante.

### Implementation

- [X] T012 [US2] Implement `getAllByUser(UUID userId)` method in `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java` — appelle `checkShopEnabled(userId)`. Appelle `productRepository.findByUserIdAndActifTrueOrderByCreatedAtDesc(userId)`. Mappe vers `List<ProductResponse>` via `toResponse()`. Dépend de T008.
- [X] T013 [US2] Add GET /products endpoint in `api/src/main/java/fr/kksdev/budget/api/controller/ProductController.java` — méthode `getAll(Authentication authentication)` → `ResponseEntity.ok(productService.getAllByUser(userId))`. Annoter `@Operation(summary = "Lister les produits actifs")`. Dépend de T011, T012.

**Checkpoint**: GET /products retourne la liste filtrée par utilisateur et par statut actif.

---

## Phase 5: User Story 3 — Consulter un produit (Priority: P2)

**Goal**: L'utilisateur peut consulter le détail d'un produit par son identifiant via GET /products/{id}.

**Independent Test**: Créer un produit → GET /products/{id} retourne le détail complet. Tester aussi : produit d'un autre utilisateur → 404, identifiant inexistant → 404.

### Implementation

- [X] T014 [US3] Implement `getById(UUID id, UUID userId)` method in `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java` — appelle `checkShopEnabled(userId)`. Appelle `findByIdAndUser(id, userId)`. Retourne `toResponse(product)`. Note : retourne le produit même si actif=false. Dépend de T008.
- [X] T015 [US3] Add GET /products/{id} endpoint in `api/src/main/java/fr/kksdev/budget/api/controller/ProductController.java` — méthode `getById(@PathVariable UUID id, Authentication authentication)` → `ResponseEntity.ok(productService.getById(id, userId))`. Annoter `@Operation(summary = "Consulter un produit")`. Dépend de T011, T014.

**Checkpoint**: GET /products/{id} fonctionne avec isolation par utilisateur.

---

## Phase 6: User Story 4 — Modifier un produit (Priority: P2)

**Goal**: L'utilisateur peut modifier un produit existant via PUT /products/{id} (remplacement complet).

**Independent Test**: Créer un produit → PUT avec nouvelles valeurs → vérifier que les valeurs sont mises à jour et updatedAt actualisé.

### Implementation

- [X] T016 [P] [US4] Create `ProductUpdateRequest` record in `api/src/main/java/fr/kksdev/budget/api/dto/request/ProductUpdateRequest.java` — mêmes champs que `ProductRequest` + `actif` (`@NotNull Boolean`). Champs : nom (`@NotBlank @Size(max = 100)`), description (`@Size(max = 500)`), icone, imageUrl (`@Size(max = 500)`), prixAchat (`@NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal`), prixVente (`@NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal`), stock (`@NotNull @Min(0) Integer`), actif (`@NotNull Boolean`). Cf. contracts/products-api.md PUT request.
- [X] T017 [US4] Implement `update(UUID id, ProductUpdateRequest request, UUID userId)` method in `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java` — annoté `@Transactional`. Appelle `checkShopEnabled(userId)` puis `findByIdAndUser(id, userId)`. Met à jour tous les champs éditables (nom, description, icone, imageUrl, prixAchat, prixVente, stock, actif). NE PAS modifier totalVendu ni createdAt. Save et log.info("Produit mis à jour: {}", id). Retourne `toResponse(product)`. Dépend de T008, T016.
- [X] T018 [US4] Add PUT /products/{id} endpoint in `api/src/main/java/fr/kksdev/budget/api/controller/ProductController.java` — méthode `update(@PathVariable UUID id, @Valid @RequestBody ProductUpdateRequest request, Authentication authentication)` → `ResponseEntity.ok(productService.update(id, request, userId))`. Annoter `@Operation(summary = "Modifier un produit")`. Dépend de T011, T017.

**Checkpoint**: PUT /products/{id} fonctionne avec remplacement complet et toggle actif/inactif.

---

## Phase 7: User Story 5 — Supprimer un produit (Priority: P3)

**Goal**: L'utilisateur peut supprimer définitivement un produit via DELETE /products/{id}.

**Independent Test**: Créer un produit → DELETE → vérifier qu'il n'existe plus en base (GET retourne 404).

### Implementation

- [X] T019 [US5] Implement `delete(UUID id, UUID userId)` method in `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java` — annoté `@Transactional`. Appelle `checkShopEnabled(userId)` puis `findByIdAndUser(id, userId)`. Appelle `productRepository.delete(product)` (suppression physique). log.info("Produit supprimé: {}", id). Dépend de T008.
- [X] T020 [US5] Add DELETE /products/{id} endpoint in `api/src/main/java/fr/kksdev/budget/api/controller/ProductController.java` — méthode `delete(@PathVariable UUID id, Authentication authentication)` → appelle service puis `ResponseEntity.noContent().build()`. Annoter `@Operation(summary = "Supprimer un produit")`. Dépend de T011, T019.

**Checkpoint**: DELETE /products/{id} supprime physiquement le produit. CRUD complet fonctionnel.

---

## Phase 8: Tests & Validation

**Purpose**: Tests d'intégration et unitaires couvrant tous les scénarios d'acceptance (SC-005)

- [X] T021 [P] Create `ProductControllerIntegrationTest` in `api/src/test/java/fr/kksdev/budget/api/controller/ProductControllerIntegrationTest.java` — `@SpringBootTest @AutoConfigureMockMvc`. Setup : créer un utilisateur test + JWT token + activer SHOP. Tests à implémenter (nommage `should_*_when_*`) : (1) should_createProduct_when_validRequest — POST avec champs obligatoires → 201 + vérifier id, actif=true, totalVendu=0. (2) should_createProduct_when_optionalFieldsProvided — POST avec description, icone, imageUrl → 201. (3) should_returnBadRequest_when_invalidCreateData — nom vide, prix négatif, stock négatif → 400. (4) should_returnActiveProducts_when_listingProducts — créer actif + inactif → GET list retourne uniquement actif. (5) should_returnEmptyList_when_noProducts — GET list → 200 []. (6) should_returnProduct_when_getById — GET /id → 200 avec tous les champs. (7) should_returnNotFound_when_productOfOtherUser — GET /id d'un autre user → 404. (8) should_returnNotFound_when_productDoesNotExist — GET /uuid-inexistant → 404. (9) should_updateProduct_when_validRequest — PUT avec nouvelles valeurs → 200 + champs mis à jour. (10) should_toggleActive_when_updatingProduct — PUT avec actif=false puis actif=true → vérifier visibilité dans la liste. (11) should_returnBadRequest_when_invalidUpdateData — PUT avec données invalides → 400. (12) should_deleteProduct_when_ownerDeletes — DELETE → 204 + GET retourne 404. (13) should_returnForbidden_when_shopDisabled — désactiver SHOP → toute requête → 403. (14) should_isolateData_when_differentUsers — user A crée, user B ne voit pas. (15) should_allowDuplicateNames_when_creatingProducts — créer 2 produits avec le même nom → 201 pour les deux, pas de contrainte d'unicité. (16) should_remainVisible_when_stockIsZero — créer un produit avec stock=0 → GET list le retourne (actif=true, stock=0). Dépend de T001-T020.
- [X] T022 [P] Create `ProductServiceTest` in `api/src/test/java/fr/kksdev/budget/api/service/ProductServiceTest.java` — `@ExtendWith(MockitoExtension.class)`. Mock : `ProductRepository`, `UserRepository`, `PreferenceService`. Tests (nommage `should_*_when_*`) : (1) should_createProduct_when_shopEnabled — vérifier save() appelé, toResponse() correct. (2) should_throwFeatureDisabled_when_shopNotEnabled — vérifier exception levée. (3) should_returnActiveProducts_when_listing — vérifier appel repo avec bon userId. (4) should_returnProduct_when_ownerRequests — vérifier ownership check. (5) should_throwNotFound_when_notOwner — vérifier EntityNotFoundException. (6) should_updateAllFields_when_validUpdate — vérifier que tous les champs éditables sont mis à jour. (7) should_deleteProduct_when_ownerDeletes — vérifier delete() appelé. Dépend de T008.
- [X] T023 Run full build verification — `cd api && mvn clean compile && mvn test`. Vérifier : compilation sans erreur, tous les tests passent, migration Flyway s'exécute correctement sur H2.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — peut commencer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (T001) — **BLOQUE** toutes les user stories
- **US1 (Phase 3)**: Dépend de Phase 2 (T008)
- **US2 (Phase 4)**: Dépend de Phase 2 (T008) + Phase 3 (T011 pour le controller existant)
- **US3 (Phase 5)**: Dépend de Phase 2 (T008) + Phase 3 (T011 pour le controller existant)
- **US4 (Phase 6)**: Dépend de Phase 2 (T008) + Phase 3 (T011 pour le controller existant)
- **US5 (Phase 7)**: Dépend de Phase 2 (T008) + Phase 3 (T011 pour le controller existant)
- **Tests (Phase 8)**: Dépend de toutes les phases précédentes (CRUD complet)

### User Story Dependencies

- **US1 (P1)**: Crée le ProductController — toutes les autres stories ajoutent des endpoints à ce controller
- **US2 (P1)**: Peut être implémentée immédiatement après US1 (même fichier controller)
- **US3 (P2)**: Indépendante de US2, dépend de US1 (controller existant)
- **US4 (P2)**: Indépendante de US2/US3, dépend de US1 (controller existant)
- **US5 (P3)**: Indépendante de US2/US3/US4, dépend de US1 (controller existant)

### Within Each User Story

- DTOs avant service
- Service avant controller
- Controller complète la story

### Parallel Opportunities

- Phase 2 : T002, T003, T004, T005 sont tous parallélisables (fichiers différents)
- Phase 3 : T009 est parallélisable avec T002-T005 (DTO indépendant)
- Phase 6 : T016 est parallélisable (DTO indépendant)
- Phase 8 : T021 et T022 sont parallélisables (fichiers de test indépendants)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Lancer en parallèle (fichiers indépendants) :
Task: "Create FeatureDisabledException in exception/FeatureDisabledException.java"
Task: "Create Product entity in model/Product.java"
Task: "Create ProductResponse DTO in dto/response/ProductResponse.java"
Task: "Create ProductRepository in repository/ProductRepository.java"

# Puis séquentiellement (dépendances) :
Task: "Add handler in GlobalExceptionHandler.java" (dépend de FeatureDisabledException)
Task: "Add isFeatureEnabled() in PreferenceService.java"
Task: "Create ProductService skeleton" (dépend de tout ce qui précède)
```

---

## Implementation Strategy

### MVP First (US1 + US2 uniquement)

1. Phase 1 : Migration V10
2. Phase 2 : Infrastructure fondationnelle
3. Phase 3 : US1 — Créer un produit (POST)
4. Phase 4 : US2 — Lister les produits (GET list)
5. **STOP et VALIDER** : tester POST + GET list manuellement (cf. quickstart.md)

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US1 (Créer) → Test POST → Commit
3. US2 (Lister) → Test GET list → Commit
4. US3 (Consulter) → Test GET by id → Commit
5. US4 (Modifier) → Test PUT → Commit
6. US5 (Supprimer) → Test DELETE → Commit
7. Tests complets → Validation finale → Commit

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [USn] = lien vers la user story n de la spec
- Chaque story est indépendamment testable après implémentation
- Commit recommandé après chaque checkpoint de phase
- Suivre les patterns existants (cf. TransactionController, TransactionService)
- Nommage des tests : `should_[résultat]_when_[condition]`
