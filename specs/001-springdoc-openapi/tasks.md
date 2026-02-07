# Tasks: Documentation API OpenAPI / Swagger UI

**Input**: Design documents from `/specs/001-springdoc-openapi/`
**Prerequisites**: plan.md, spec.md, research.md, contracts/openapi-endpoints.md, quickstart.md

**Tests**: Non demandes dans la spec. Les 84 tests existants servent de filet de securite (aucun ne doit casser).

**Organization**: Taches groupees par user story pour implementation incrementale.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story concernee (US1, US2, US3)
- Chemins exacts dans chaque description

---

## Phase 1: Setup (Dependance Maven)

**Purpose**: Ajouter springdoc-openapi au projet et verifier la compilation

- [X] T001 Ajouter la dependance `org.springdoc:springdoc-openapi-starter-webmvc-ui:3.0.1` dans `api/pom.xml` apres le bloc Flyway
- [X] T002 Verifier la compilation avec `cd api && mvn clean compile`

---

## Phase 2: Foundational (Configuration securite + OpenAPI)

**Purpose**: Infrastructure partagee par toutes les user stories — routes publiques Swagger et metadata API

**CRITICAL**: Les user stories ne peuvent pas etre validees sans ces taches

- [X] T003 Ajouter les routes `/v3/api-docs/**`, `/swagger-ui/**`, `/swagger-ui.html` en `permitAll()` dans `api/src/main/java/fr/kksdev/budget/api/config/SecurityConfig.java`
- [X] T004 Creer la classe `OpenApiConfig` dans `api/src/main/java/fr/kksdev/budget/api/config/OpenApiConfig.java` avec : bean `OpenAPI` contenant `Info` (titre "Budget API", description "API REST de gestion de budget personnel", version "1.0.0"), `SecurityScheme` (type HTTP, scheme bearer, bearerFormat JWT, nom "bearerAuth"), et `SecurityRequirement` global ("bearerAuth")

**Checkpoint**: `mvn clean compile` reussit. L'application demarre et Swagger UI est accessible sur `http://localhost:8080/api/swagger-ui.html` avec le bouton Authorize visible.

---

## Phase 3: User Story 1 - Consulter la documentation interactive (Priority: P1) MVP

**Goal**: Tous les endpoints apparaissent dans Swagger UI groupes par domaine fonctionnel

**Independent Test**: Naviguer vers `http://localhost:8080/api/swagger-ui.html` et voir 4 groupes (Authentification, Transactions, Abonnements, Dettes) avec les 18 endpoints documentes

### Implementation for User Story 1

- [X] T005 [P] [US1] Ajouter `@Tag(name = "Authentification", description = "Inscription et connexion")` et `@Operation(summary = "...")` sur les 2 methodes de `api/src/main/java/fr/kksdev/budget/api/controller/AuthController.java`
- [X] T006 [P] [US1] Ajouter `@Tag(name = "Transactions", description = "Gestion des depenses et recettes")` et `@Operation(summary = "...")` sur les 6 methodes de `api/src/main/java/fr/kksdev/budget/api/controller/TransactionController.java`
- [X] T007 [P] [US1] Ajouter `@Tag(name = "Abonnements", description = "Gestion des abonnements recurrents")` et `@Operation(summary = "...")` sur les 5 methodes de `api/src/main/java/fr/kksdev/budget/api/controller/SubscriptionController.java`
- [X] T008 [P] [US1] Ajouter `@Tag(name = "Dettes", description = "Suivi des dettes et prets")` et `@Operation(summary = "...")` sur les 5 methodes de `api/src/main/java/fr/kksdev/budget/api/controller/DebtController.java`

**Checkpoint**: Swagger UI affiche 4 groupes, 18 endpoints avec resume descriptif. Spec JSON accessible sur `/api/v3/api-docs`.

---

## Phase 4: User Story 2 - Tester un endpoint protege depuis Swagger UI (Priority: P2)

**Goal**: Le bouton Authorize fonctionne et permet d'executer des appels authentifies

**Independent Test**: Se connecter via `POST /auth/login` dans Swagger UI, copier le token, cliquer Authorize, puis appeler `GET /transactions` et obtenir une reponse 200

### Implementation for User Story 2

Aucune tache supplementaire. Le schema JWT Bearer est deja configure dans T004 (`OpenApiConfig.java`). Le bouton Authorize est fonctionnel des la Phase 2.

**Checkpoint**: Validation manuelle — login, copier token, Authorize, appeler un endpoint protege → 200 OK.

---

## Phase 5: User Story 3 - Comprendre les champs et contraintes (Priority: P3)

**Goal**: Les schemas de requete affichent les champs obligatoires, types, contraintes de validation et valeurs d'enums

**Independent Test**: Ouvrir `POST /transactions` dans Swagger UI et verifier que `montant` est marque required/positive, `libelle` a une taille max, `type` liste DEPENSE/RECETTE

### Implementation for User Story 3

Aucune tache supplementaire. springdoc auto-detecte les annotations Bean Validation (`@NotNull`, `@NotBlank`, `@Size`, `@Positive`) et les valeurs d'enums depuis les records Java. Les schemas sont generes automatiquement des la Phase 1.

**Checkpoint**: Verification visuelle des schemas dans Swagger UI — contraintes et enums affiches correctement.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verification finale, documentation, non-regression

- [X] T009 Executer la suite de tests avec `cd api && mvn test` et verifier que les 84 tests passent
- [X] T010 Ajouter l'URL Swagger UI dans la section "Documentation complementaire" de `README.md`
- [X] T011 Suivre le guide `specs/001-springdoc-openapi/quickstart.md` pour validation complete (compilation, tests, Swagger UI, spec JSON, authentification)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Pas de dependance — demarrage immediat
- **Phase 2 (Foundational)**: Depend de Phase 1 (dependance Maven requise pour compiler)
- **Phase 3 (US1)**: Depend de Phase 2 (routes publiques + config OpenAPI necessaires)
- **Phase 4 (US2)**: Depend de Phase 2 — pas de taches propres, valide T004
- **Phase 5 (US3)**: Depend de Phase 1 — pas de taches propres, auto-detecte par springdoc
- **Phase 6 (Polish)**: Depend de Phase 3 (tous les controllers annotes)

### User Story Dependencies

- **US1 (P1)**: Depend de Phase 2 — peut demarrer des que T004 est complete
- **US2 (P2)**: Pas de taches propres — deja couvert par T004 (OpenApiConfig)
- **US3 (P3)**: Pas de taches propres — couvert automatiquement par springdoc + Bean Validation

### Parallel Opportunities

- T005, T006, T007, T008 sont tous paralleles (4 fichiers differents, aucune dependance croisee)

---

## Parallel Example: User Story 1

```
# Les 4 controllers peuvent etre annotes en parallele :
T005: AuthController.java         (@Tag + @Operation x2)
T006: TransactionController.java  (@Tag + @Operation x6)
T007: SubscriptionController.java (@Tag + @Operation x5)
T008: DebtController.java         (@Tag + @Operation x5)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001-T002 : Setup (dependance Maven, compilation)
2. T003-T004 : Foundational (securite + OpenApiConfig)
3. T005-T008 : US1 — Annoter les 4 controllers (en parallele)
4. **STOP et VALIDER** : Swagger UI affiche les 4 groupes, 18 endpoints

### Incremental Delivery

1. Setup + Foundational → Swagger UI accessible (vide de descriptions custom)
2. US1 (annotations) → Documentation complete et groupee
3. US2 → Validation du bouton Authorize (deja fonctionnel)
4. US3 → Validation des schemas/contraintes (deja auto-generes)
5. Polish → Tests, README, validation quickstart

---

## Notes

- Les US2 et US3 n'ont pas de taches d'implementation propres car springdoc + OpenApiConfig couvrent automatiquement ces besoins. Les phases 4 et 5 sont des checkpoints de validation uniquement.
- Total de taches reelles : 11 (dont 4 parallelisables)
- Chaque tache touche un seul fichier pour eviter les conflits
- Commit recommande apres chaque phase
