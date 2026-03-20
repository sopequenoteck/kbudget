# Tasks: Backend Budget Categories

**Input**: Design documents from `/specs/073-backend-budget-categories/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.md, quickstart.md

**Tests**: Inclus — la spec mentionne tests d'integration et unitaires (constitution principe V).

**Organization**: Tasks groupees par user story pour implementation et test independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Backend**: `api/src/main/java/fr/kksdev/budget/api/`
- **Tests**: `api/src/test/java/fr/kksdev/budget/api/`
- **Migrations**: `api/src/main/resources/db/migration/`

---

## Phase 1: Setup

**Purpose**: Migration Flyway et modifications des enums existants

- [x] T001 [P] Ajouter `HEBDOMADAIRE` a l'enum `Frequency` dans `api/src/main/java/fr/kksdev/budget/api/enums/Frequency.java`
- [x] T002 [P] Ajouter `BUDGETS` a l'enum `Feature` dans `api/src/main/java/fr/kksdev/budget/api/enums/Feature.java`
- [x] T003 Creer la migration Flyway `V17__add_budgets.sql` dans `api/src/main/resources/db/migration/` — tables `budgets` (UUID PK, montant DECIMAL(12,2), currency VARCHAR(3) DEFAULT 'EUR', frequence VARCHAR(20), seuil_notification INTEGER DEFAULT 80, actif BOOLEAN DEFAULT true, updated_at TIMESTAMP, category_id UUID NOT NULL FK CASCADE, user_id UUID NOT NULL FK, UNIQUE(category_id, user_id)) et `budget_snapshots` (UUID PK, montant_budget DECIMAL(12,2), currency VARCHAR(3), taux_change DECIMAL(20,6) nullable, montant_depense DECIMAL(12,2), mois VARCHAR(7), created_at TIMESTAMP, category_id UUID NOT NULL FK CASCADE, user_id UUID NOT NULL FK, UNIQUE(mois, category_id, user_id)) + index sur user_id, category_id, mois

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Entites JPA, repositories, DTOs et query de somme — prerequis pour tous les endpoints

- [x] T004 [P] Creer l'entite `Budget` dans `api/src/main/java/fr/kksdev/budget/api/model/Budget.java` — @Entity @Data @NoArgsConstructor @AllArgsConstructor @Builder, UUID PK, montant BigDecimal(12,2), currency Currency @Enumerated(STRING) @Builder.Default EUR, frequence Frequency @Enumerated(STRING), seuilNotification Integer @Builder.Default 80, actif Boolean @Builder.Default true, @UpdateTimestamp updatedAt, @ManyToOne(LAZY) category, @ManyToOne(LAZY) user, @Table(uniqueConstraints category_id+user_id)
- [x] T005 [P] Creer l'entite `BudgetSnapshot` dans `api/src/main/java/fr/kksdev/budget/api/model/BudgetSnapshot.java` — @Entity @Data @NoArgsConstructor @AllArgsConstructor @Builder, UUID PK, montantBudget BigDecimal(12,2), currency Currency @Enumerated(STRING), tauxChange BigDecimal(20,6) nullable, montantDepense BigDecimal(12,2), mois String(7), @CreationTimestamp createdAt (updatable=false), @ManyToOne(LAZY) category, @ManyToOne(LAZY) user, @Table(uniqueConstraints mois+category_id+user_id)
- [x] T006 [P] Creer `BudgetRepository` dans `api/src/main/java/fr/kksdev/budget/api/repository/BudgetRepository.java` — extends JpaRepository<Budget, UUID>, findByUserId, findByUserIdAndActifTrue, findByIdAndUserId, existsByCategoryIdAndUserId, findByCategoryIdAndUserId
- [x] T007 [P] Creer `BudgetSnapshotRepository` dans `api/src/main/java/fr/kksdev/budget/api/repository/BudgetSnapshotRepository.java` — extends JpaRepository<BudgetSnapshot, UUID>, findByUserIdAndMois, findByCategoryIdAndUserIdAndMois, existsByUserIdAndMois
- [x] T008 [P] Creer `BudgetRequest` dans `api/src/main/java/fr/kksdev/budget/api/dto/request/BudgetRequest.java` — record avec @NotNull UUID categoryId, @NotNull @Positive BigDecimal montant, @NotNull Frequency frequence, Currency currency (nullable, defaut EUR), @Min(0) @Max(100) Integer seuilNotification (nullable, defaut 80), Boolean actif (nullable, permet desactivation/reactivation via PUT)
- [x] T009 [P] Creer `BudgetResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/BudgetResponse.java` — record(UUID id, BigDecimal montant, String currency, String frequence, Integer seuilNotification, Boolean actif, CategoryResponse category, BigDecimal spent, LocalDateTime updatedAt)
- [x] T010 Ajouter une query native dans `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java` — methode `sumDepenseByUserIdAndCategoryIdAndDateBetween(UUID userId, UUID categoryId, LocalDate from, LocalDate to)` retournant BigDecimal (COALESCE SUM montant WHERE type='DEPENSE')

**Checkpoint**: Fondation prete — entites, repos, DTOs disponibles pour les user stories

---

## Phase 3: User Story 1 - CRUD Budgets (Priority: P1) MVP

**Goal**: L'utilisateur peut creer, lire, modifier et supprimer des budgets par categorie.

**Independent Test**: Creer un budget via POST, le lire via GET, le modifier via PUT, le supprimer via DELETE. Verifier l'unicite par categorie (409 sur doublon).

### Implementation for User Story 1

- [x] T011 [US1] Creer `BudgetService` dans `api/src/main/java/fr/kksdev/budget/api/service/BudgetService.java` — @Service @Slf4j @RequiredArgsConstructor @Transactional(readOnly=true). Injecter BudgetRepository, BudgetSnapshotRepository, CategoryRepository, TransactionRepository, UserRepository, PreferenceService, ExchangeRateRepository. Implementer : methode privee `findByIdAndUser(UUID id, UUID userId)`, methode privee `toResponse(Budget)` (sans spent, pour create/update/delete) et `toResponseWithSpent(Budget, UUID userId)` (avec calcul spent du mois courant via TransactionRepository.sumDepense, pour GET list/detail), methode privee `checkFeatureEnabled(UUID userId)` via PreferenceService.isFeatureEnabled(userId, Feature.BUDGETS). Logging : log.info sur actions CRUD, les erreurs metier (404, 409, 400) sont gerees par le GlobalExceptionHandler existant (log.error automatique)
- [x] T012 [US1] Implementer `create(BudgetRequest, UUID userId)` dans BudgetService — @Transactional, checkFeatureEnabled, valider categorie existe et appartient au user, verifier unicite (ConflictException si doublon), builder Budget avec defaults (currency=EUR, seuil=80), save, log.info, retourner BudgetResponse via `toResponse()` (sans calcul spent — le budget vient d'etre cree, spent=null)
- [x] T013 [US1] Implementer `getAll(UUID userId, boolean includeInactive)` et `getById(UUID id, UUID userId)` dans BudgetService — checkFeatureEnabled, retourner avec spent calcule via toResponseWithSpent
- [x] T014 [US1] Implementer `update(UUID id, BudgetRequest, UUID userId)` dans BudgetService — @Transactional, checkFeatureEnabled, findByIdAndUser, mettre a jour champs (montant, frequence, currency, seuilNotification, actif si fourni), gerer changement de categoryId (verifier unicite, ConflictException si doublon), save, log.info
- [x] T015 [US1] Implementer `delete(UUID id, UUID userId)` dans BudgetService — @Transactional, checkFeatureEnabled, findByIdAndUser, hard delete (repository.delete), log.info. Les snapshots sont conserves (pas de cascade cote applicatif)
- [x] T016 [US1] Creer `BudgetController` dans `api/src/main/java/fr/kksdev/budget/api/controller/BudgetController.java` — @RestController @RequestMapping("/budgets") @RequiredArgsConstructor @Slf4j @Tag(name="Budgets"). 5 endpoints : POST / (201), GET / (?includeInactive), GET /{id}, PUT /{id}, DELETE /{id} (204). Chaque endpoint extrait userId via authentication.getPrincipal()

### Tests for User Story 1

- [x] T017 [P] [US1] Creer `BudgetServiceTest` dans `api/src/test/java/fr/kksdev/budget/api/service/BudgetServiceTest.java` — tests unitaires avec Mockito : should_create_budget_when_valid_request, should_throw_conflict_when_duplicate_category, should_return_all_active_budgets_when_includeInactive_false, should_return_all_budgets_when_includeInactive_true, should_update_budget_when_valid, should_hard_delete_budget_when_exists, should_preserve_snapshots_when_budget_deleted (verifier que snapshotRepository.delete n'est PAS appele), should_throw_not_found_when_budget_missing, should_throw_feature_disabled_when_budgets_off, should_calculate_spent_for_current_month
- [x] T018 [P] [US1] Creer `BudgetControllerTest` dans `api/src/test/java/fr/kksdev/budget/api/controller/BudgetControllerTest.java` — tests d'integration avec @SpringBootTest/@AutoConfigureMockMvc ou @WebMvcTest : should_create_budget_return_201, should_return_409_when_duplicate_category, should_list_budgets_with_spent, should_get_budget_by_id, should_update_budget, should_delete_budget_return_204, should_return_404_when_not_found, should_validate_positive_montant, should_validate_seuil_range, should_accept_seuil_0_and_100, should_return_403_when_feature_disabled

**Checkpoint**: CRUD complet et teste. L'utilisateur peut gerer ses budgets. MVP fonctionnel.

---

## Phase 4: User Story 2 - Overview mensuel (Priority: P2)

**Goal**: L'utilisateur consulte le tableau de bord budgetaire du mois courant avec totaux normalises et conversion multi-devises.

**Independent Test**: Creer des budgets avec differentes frequences et devises, ajouter des transactions DEPENSE pour le mois courant, appeler GET /budgets/overview et verifier les totaux normalises et convertis.

### Implementation for User Story 2

- [x] T019 [P] [US2] Creer `BudgetOverviewItemResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/BudgetOverviewItemResponse.java` — record(UUID budgetId, UUID categoryId, String categoryNom, String categoryIcone, String categoryCouleur, BigDecimal montantBudget, BigDecimal montantBudgetNormalise, String currency, BigDecimal montantDepense, BigDecimal percentage, String frequence)
- [x] T020 [P] [US2] Creer `BudgetOverviewResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/BudgetOverviewResponse.java` — record(String month, BigDecimal totalBudget, BigDecimal totalSpent, BigDecimal percentage, String currency, List<BudgetOverviewItemResponse> items)
- [x] T021 [US2] Implementer `getOverview(UUID userId)` dans BudgetService — checkFeatureEnabled, charger budgets actifs, pour chaque budget : normaliser montant mensuel (HEBDO*4.33, ANNUEL/12, arrondi HALF_UP scale 2), calculer spent du mois courant (montantDepense reste dans la devise des transactions, PAS de conversion), convertir UNIQUEMENT montantBudget en devise principale (currencies[0] via PreferenceService + ExchangeRateRepository) si devise differente (BadRequestException avec message indiquant la devise manquante si taux absent — cf. FR-011), agreger totaux, calculer pourcentages (arrondi 2 decimales, percentage=0 si totalBudget=0), retourner BudgetOverviewResponse
- [x] T022 [US2] Ajouter endpoint `GET /budgets/overview` dans BudgetController — @GetMapping("/overview"), @Operation(summary="Tableau de bord budgetaire du mois courant"), retourner ResponseEntity<BudgetOverviewResponse>

### Tests for User Story 2

- [x] T023 [P] [US2] Ajouter tests overview dans BudgetServiceTest — should_normalize_weekly_budget_multiply_4_33, should_normalize_annual_budget_divide_12, should_calculate_total_budget_and_spent, should_convert_foreign_currency_budget, should_throw_when_exchange_rate_missing, should_return_zero_totals_when_no_active_budgets, should_return_zero_percentage_when_total_budget_is_zero, should_sum_expenses_regardless_of_budget_frequency
- [x] T024 [P] [US2] Ajouter tests overview dans BudgetControllerTest — should_return_overview_with_totals, should_return_overview_with_normalized_amounts

**Checkpoint**: Dashboard budgetaire fonctionnel. L'utilisateur voit ses budgets vs depenses en temps reel.

---

## Phase 5: User Story 3 - Historique avec snapshots (Priority: P3)

**Goal**: L'utilisateur consulte l'historique budgetaire d'un mois passe via des snapshots crees a la volee.

**Independent Test**: Creer des budgets et transactions pour un mois passe, appeler GET /budgets/history?month=YYYY-MM, verifier la creation lazy des snapshots et le retour des donnees historiques.

### Implementation for User Story 3

- [x] T025 [P] [US3] Creer `BudgetHistoryItemResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/BudgetHistoryItemResponse.java` — record(UUID categoryId, String categoryNom, String categoryIcone, String categoryCouleur, BigDecimal montantBudget, String currency, BigDecimal tauxChange, BigDecimal montantDepense, BigDecimal percentage, LocalDateTime createdAt)
- [x] T026 [P] [US3] Creer `BudgetHistoryResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/BudgetHistoryResponse.java` — record(String month, BigDecimal totalBudget, BigDecimal totalSpent, BigDecimal percentage, String currency, List<BudgetHistoryItemResponse> items)
- [x] T027 [US3] Implementer `getHistory(String month, UUID userId)` dans BudgetService — @Transactional (car peut creer des snapshots), checkFeatureEnabled, valider format YYYY-MM (BadRequestException si invalide), valider mois passe (BadRequestException si mois courant ou futur), chercher snapshots existants pour ce mois. Si pas de snapshots : creer lazy — pour chaque budget actif du user **au moment de la consultation** (limitation acceptee : un budget supprime ou desactive entre le mois cible et la date de consultation ne sera pas capture — cf. spec Assumptions), normaliser montant (HALF_UP scale 2), calculer spent du mois, recuperer taux de change (BadRequestException si manquant), persister BudgetSnapshot. Retourner BudgetHistoryResponse avec totaux convertis en devise principale (percentage=0 si totalBudget=0)
- [x] T028 [US3] Ajouter endpoint `GET /budgets/history` dans BudgetController — @GetMapping("/history"), @RequestParam String month, @Operation(summary="Historique budgetaire d'un mois passe"), retourner ResponseEntity<BudgetHistoryResponse>

### Tests for User Story 3

- [x] T029 [P] [US3] Ajouter tests history dans BudgetServiceTest — should_create_snapshots_lazily_when_none_exist, should_return_existing_snapshots_when_available, should_return_empty_when_no_budgets_for_month, should_reject_current_month, should_reject_future_month, should_preserve_exchange_rate_in_snapshot
- [x] T030 [P] [US3] Ajouter tests history dans BudgetControllerTest — should_return_history_for_past_month, should_return_400_for_current_month, should_return_400_for_invalid_month_format

**Checkpoint**: Historique complet. L'utilisateur peut consulter les performances budgetaires passees.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et nettoyage

- [x] T031 Verifier la suppression en cascade : supprimer une categorie ayant un budget et des snapshots, confirmer que tout est supprime (test d'integration)
- [x] T032 Executer `cd api && mvn clean install` — verifier que la compilation et tous les tests passent
- [x] T033 Valider le quickstart.md — executer manuellement les commandes curl et verifier les reponses
- [x] T034 Valider SC-002 (performance) — verifier que GET /budgets/overview repond en moins de 2 secondes avec les donnees de test (validation manuelle via curl ou test d'integration avec timeout)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dependance — demarrage immediat
- **Foundational (Phase 2)**: Depend de Phase 1 (enums + migration)
- **US1 (Phase 3)**: Depend de Phase 2 — CRUD complet
- **US2 (Phase 4)**: Depend de Phase 2 + T011 (BudgetService squelette) — peut demarrer en parallele de US1 si service existe
- **US3 (Phase 5)**: Depend de Phase 2 + T011 (BudgetService squelette) — peut demarrer en parallele de US1/US2 si service existe
- **Polish (Phase 6)**: Depend de toutes les phases precedentes

### User Story Dependencies

- **US1 (P1)**: Autonome apres Phase 2
- **US2 (P2)**: Autonome apres Phase 2 + BudgetService cree (T011). Pas de dependance sur les endpoints CRUD de US1
- **US3 (P3)**: Autonome apres Phase 2 + BudgetService cree (T011). Pas de dependance sur US1/US2

### Within Each User Story

- DTOs avant service
- Service avant controller
- Implementation avant tests (tests valident l'implementation)

### Parallel Opportunities

- Phase 1 : T001 || T002 || T003 (3 fichiers independants)
- Phase 2 : T004 || T005 || T006 || T007 || T008 || T009 (6 fichiers independants)
- Phase 3 : T017 || T018 (tests parallelisables)
- Phase 4 : T019 || T020 (DTOs parallelisables), T023 || T024 (tests parallelisables)
- Phase 5 : T025 || T026 (DTOs parallelisables), T029 || T030 (tests parallelisables)

---

## Parallel Example: User Story 1

```bash
# DTOs deja crees en Phase 2 (T008, T009)

# Service : implementation sequentielle (meme fichier)
Task T011: BudgetService squelette + helpers
Task T012: create()
Task T013: getAll() + getById()
Task T014: update()
Task T015: delete()

# Controller (depend du service)
Task T016: BudgetController

# Tests en parallele (fichiers differents)
Task T017: BudgetServiceTest
Task T018: BudgetControllerTest
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (enums + migration) — 3 taches
2. Phase 2: Foundational (entites, repos, DTOs, query) — 7 taches
3. Phase 3: US1 CRUD + tests — 8 taches
4. **STOP et VALIDER** : tester le CRUD independamment
5. Commiter et deployer si pret

### Incremental Delivery

1. Setup + Foundational → Base prete
2. US1 CRUD → Tester → Commiter (MVP)
3. US2 Overview → Tester → Commiter
4. US3 History → Tester → Commiter
5. Polish → Build final → Deployer

---

## Notes

- Tous les montants monetaires en BigDecimal(12,2), taux en BigDecimal(20,6)
- Constante de normalisation : WEEKS_PER_MONTH = BigDecimal.valueOf(4.33)
- Arrondi : RoundingMode.HALF_UP, scale 2 apres normalisation et conversion
- Feature toggle BUDGETS verifie dans chaque methode publique du service
- Devise principale = currencies[0] de UserPreference
- Hard delete sur Budget, snapshots conserves (pas de FK snapshot→budget)
- Cascade DB : category supprimee → budget ET snapshots supprimes
