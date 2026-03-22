# Tasks: Système de Feature Toggles — Backend

**Input**: Design documents from `/specs/055-backend-feature-toggles/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/preferences-api.md, research.md

**Tests**: Inclus — les critères d'acceptation de la spec (KKS-117) exigent des tests d'intégration sur les endpoints.

**Organization**: Tasks groupées par user story. Chaque story est implémentable et testable indépendamment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3)
- Chemins exacts depuis la racine du repo

## Path Conventions

Base package : `api/src/main/java/fr/kksdev/budget/api/`
Tests : `api/src/test/java/fr/kksdev/budget/api/`
Migrations : `api/src/main/resources/db/migration/`

---

## Phase 1: Fondation (Infrastructure partagée)

**Purpose**: Enum, converter, migration, entité, repository et DTOs — bloquants pour toutes les user stories

- [X] T001 [P] Create Feature enum with values SUBSCRIPTIONS, DEBTS, SHOP in api/src/main/java/fr/kksdev/budget/api/enums/Feature.java
- [X] T002 [P] Create FeatureListConverter (AttributeConverter<List<Feature>, String>) in api/src/main/java/fr/kksdev/budget/api/model/converter/FeatureListConverter.java
- [X] T003 [P] Create Flyway migration V9__add_user_preferences.sql with table creation and default data insert for existing users in api/src/main/resources/db/migration/V9__add_user_preferences.sql
- [X] T004 [P] Create UserPreferenceRequest record DTO with @NotNull enabledFeatures (List<Feature>) and nullable navOrder (List<Feature>) in api/src/main/java/fr/kksdev/budget/api/dto/request/UserPreferenceRequest.java
- [X] T005 [P] Create UserPreferenceResponse record DTO with enabledFeatures and navOrder (List<Feature>) in api/src/main/java/fr/kksdev/budget/api/dto/response/UserPreferenceResponse.java
- [X] T006 Create UserPreference entity with @OneToOne User relation, enabledFeatures and navOrder columns using @Convert(converter = FeatureListConverter.class), @UpdateTimestamp in api/src/main/java/fr/kksdev/budget/api/model/UserPreference.java
- [X] T007 Create UserPreferenceRepository (JpaRepository<UserPreference, UUID>) with findByUserId and Optional<UserPreference> findByUser_Id methods in api/src/main/java/fr/kksdev/budget/api/repository/UserPreferenceRepository.java

**Checkpoint**: Infrastructure de données prête — les user stories peuvent commencer

---

## Phase 2: User Story 1 — Consulter ses préférences (Priority: P1) 🎯 MVP

**Goal**: Un utilisateur authentifié peut consulter ses préférences (features activées + ordre de navigation). Si aucune préférence n'existe, les valeurs par défaut sont retournées.

**Independent Test**: GET /users/me/preferences retourne les préférences (défaut ou personnalisées). 401 sans token.

### Implementation for User Story 1

- [X] T008 [US1] Implement PreferenceService with getPreferences(UUID userId) method — getOrCreate pattern: find existing or create default (all features enabled, standard order SUBSCRIPTIONS,DEBTS,SHOP), mapping to UserPreferenceResponse via private toResponse() method, @Transactional(readOnly=true) on class, @Transactional on create path, @Slf4j logging in api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java
- [X] T009 [US1] Implement PreferenceController with GET /users/me/preferences endpoint — @RestController @RequestMapping("/users/me/preferences"), extract userId from Authentication principal, delegate to PreferenceService, @Tag and @Operation Swagger annotations in api/src/main/java/fr/kksdev/budget/api/controller/PreferenceController.java
- [X] T010 [US1] Write PreferenceControllerTest for GET scenarios — @WebMvcTest(PreferenceController.class) @Import(SecurityConfig.class), @MockitoBean on PreferenceService/JwtUtil/UserRepository, tests: should_return_200_with_default_preferences_when_no_custom_preferences, should_return_200_with_custom_preferences_when_preferences_exist, should_return_401_when_no_token in api/src/test/java/fr/kksdev/budget/api/controller/PreferenceControllerTest.java

**Checkpoint**: GET endpoint fonctionnel — un client peut lire les préférences

---

## Phase 3: User Story 2 — Activer/désactiver des fonctionnalités (Priority: P1)

**Goal**: Un utilisateur peut modifier ses features activées via PUT. Quand navOrder n'est pas fourni, le backend auto-gère l'ordre (retire les désactivées, ajoute les nouvelles en fin).

**Independent Test**: PUT /users/me/preferences avec enabledFeatures uniquement → features mises à jour, navOrder auto-géré. Valeurs inconnues rejetées.

### Implementation for User Story 2

- [X] T011 [US2] Implement PreferenceService.updatePreferences(UserPreferenceRequest request, UUID userId) — validate enabledFeatures (reject unknown values with IllegalArgumentException), when navOrder is null: auto-manage (remove disabled from current navOrder, append newly enabled at end), persist and return updated response, @Transactional, log.info on update in api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java
- [X] T012 [US2] Add PUT /users/me/preferences endpoint to PreferenceController — @Valid @RequestBody UserPreferenceRequest, delegate to PreferenceService.updatePreferences, return ResponseEntity.ok() with updated response in api/src/main/java/fr/kksdev/budget/api/controller/PreferenceController.java
- [X] T013 [US2] Write PreferenceServiceTest for updatePreferences auto-management logic — mock UserPreferenceRepository, tests: should_remove_disabled_feature_from_navOrder_when_navOrder_not_provided, should_append_reactivated_feature_at_end_when_navOrder_not_provided, should_accept_empty_enabledFeatures_when_all_features_disabled, should_throw_when_unknown_feature_in_enabledFeatures, should_preserve_remaining_order_when_feature_removed_from_middle in api/src/test/java/fr/kksdev/budget/api/service/PreferenceServiceTest.java
- [X] T014 [US2] Add PUT test scenarios to PreferenceControllerTest — should_return_200_when_toggle_features_without_navOrder, should_return_200_when_disable_all_features, should_return_400_when_unknown_feature, should_return_401_when_no_token_on_put in api/src/test/java/fr/kksdev/budget/api/controller/PreferenceControllerTest.java

**Checkpoint**: PUT endpoint fonctionnel pour toggle — le client peut activer/désactiver les features

---

## Phase 4: User Story 3 — Personnaliser l'ordre de navigation (Priority: P2)

**Goal**: Un utilisateur peut fournir un navOrder explicite dans le PUT pour réordonner ses onglets. Le backend valide que navOrder contient exactement les features activées, sans doublons.

**Independent Test**: PUT avec enabledFeatures + navOrder explicite → ordre sauvegardé. navOrder incohérent ou avec doublons → rejeté 400.

### Implementation for User Story 3

- [X] T015 [US3] Extend PreferenceService.updatePreferences() with explicit navOrder validation — when navOrder is provided: validate no duplicates (IllegalArgumentException), validate navOrder contains exactly enabledFeatures (same elements, no more, no less), reject with descriptive error messages per contracts/preferences-api.md in api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java
- [X] T016 [US3] Write PreferenceServiceTest for navOrder validation — should_accept_valid_navOrder_when_matches_enabledFeatures, should_throw_when_navOrder_contains_duplicates, should_throw_when_navOrder_missing_enabled_feature, should_throw_when_navOrder_contains_disabled_feature, should_preserve_explicit_navOrder_order in api/src/test/java/fr/kksdev/budget/api/service/PreferenceServiceTest.java
- [X] T017 [US3] Add PUT reorder test scenarios to PreferenceControllerTest — should_return_200_when_valid_navOrder_provided, should_return_400_when_navOrder_has_duplicates, should_return_400_when_navOrder_missing_enabled_feature, should_return_400_when_navOrder_contains_disabled_feature in api/src/test/java/fr/kksdev/budget/api/controller/PreferenceControllerTest.java

**Checkpoint**: PUT endpoint complet — toggle et réordonnement fonctionnels

---

## Phase 5: Polish & Validation

**Purpose**: Validation end-to-end et vérification de la qualité

- [X] T018 Compile project and run all tests via `cd api && mvn clean test` to verify all scenarios pass
- [X] T019 Run quickstart.md validation (skip: nécessite PostgreSQL et serveur lancé — validé via tests d'intégration T018) — verify GET and PUT endpoints respond correctly with curl commands from specs/055-backend-feature-toggles/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Fondation (Phase 1)**: Aucune dépendance — commence immédiatement
- **US1 (Phase 2)**: Dépend de Phase 1 (T006 entity + T007 repository)
- **US2 (Phase 3)**: Dépend de Phase 2 (T008 service + T009 controller)
- **US3 (Phase 4)**: Dépend de Phase 3 (T011 service.update + T012 controller PUT)
- **Polish (Phase 5)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Après Phase 1 — indépendant des autres stories. MVP minimal.
- **US2 (P1)**: Après US1 — étend le service et le controller existants. Peut être testé indépendamment (PUT sans navOrder).
- **US3 (P2)**: Après US2 — étend la validation dans updatePreferences. Peut être testé indépendamment (PUT avec navOrder).

### Within Each User Story

- Service avant controller
- Controller avant tests d'intégration
- Tests unitaires service en parallèle avec tests controller

### Parallel Opportunities

**Phase 1** — T001, T002, T003, T004, T005 en parallèle (fichiers indépendants). T006 après T001+T002. T007 après T006.

**Phase 3** — T013 (service test) et T014 (controller test) en parallèle après T011+T012.

**Phase 4** — T016 (service test) et T017 (controller test) en parallèle après T015.

---

## Parallel Example: Phase 1

```text
# Lancer en parallèle (fichiers différents, aucune dépendance) :
T001: Feature enum in enums/Feature.java
T002: FeatureListConverter in model/converter/FeatureListConverter.java
T003: Migration V9 in db/migration/V9__add_user_preferences.sql
T004: UserPreferenceRequest in dto/request/UserPreferenceRequest.java
T005: UserPreferenceResponse in dto/response/UserPreferenceResponse.java

# Ensuite séquentiellement :
T006: UserPreference entity (dépend de T001 enum + T002 converter)
T007: UserPreferenceRepository (dépend de T006 entity)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Fondation (enum, converter, migration, entity, repo, DTOs)
2. Compléter Phase 2: US1 (GET /users/me/preferences)
3. **STOP et VALIDER**: Tester le GET avec token JWT → préférences par défaut retournées
4. Deploy/demo si prêt

### Incremental Delivery

1. Phase 1 → Infrastructure prête
2. + US1 → GET fonctionnel (MVP!)
3. + US2 → PUT toggle fonctionnel (valeur principale)
4. + US3 → PUT reorder fonctionnel (confort)
5. Chaque story ajoute de la valeur sans casser les précédentes

---

## Notes

- Feature entièrement additive — aucun fichier existant modifié
- Tous les fichiers dans le package `fr.kksdev.budget.api`
- Suivre les patterns existants : records pour DTOs, Lombok pour entities, `@WebMvcTest` pour tests controller
- Messages d'erreur en français (cohérent avec les erreurs existantes)
- Commit après chaque phase complétée
