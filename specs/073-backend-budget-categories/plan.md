# Implementation Plan: Backend Budget Categories

**Branch**: `073-backend-budget-categories` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/073-backend-budget-categories/spec.md`

## Summary

Implementer le systeme de budgets par categorie cote backend : deux entites (Budget, BudgetSnapshot), migration Flyway V17, CRUD complet, overview temps reel du mois courant, historique avec snapshots lazy, conversion multi-devises, feature toggle BUDGETS. Architecture standard Controller → Service → Repository.

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, jjwt 0.12.6
**Storage**: PostgreSQL 15+ (Flyway V17)
**Testing**: JUnit 5 + Spring Boot Test + Mockito + H2 (profil test)
**Target Platform**: Linux server (self-hosted)
**Project Type**: Web service (API REST)
**Performance Goals**: Overview < 2s avec 50 budgets actifs (SC-002)
**Constraints**: Single-user self-hosted, isolation par JWT, pas de service cloud
**Scale/Scope**: 5-20 budgets par utilisateur, 7 endpoints

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | 7 endpoints REST, DTOs request/response separes, context path /api |
| II. Securite par defaut | PASS | JWT sur toutes les routes, filtrage par userId, Bean Validation, feature toggle |
| III. Simplicite & YAGNI | PASS | Controller → Service → Repository, pas de pattern complexe, List<> sans pagination Spring |
| IV. Mobile-First UX | N/A | Backend uniquement, pas d'UI |
| V. Testabilite | PASS | Tests d'integration controller + tests unitaires service prevus |
| VI. Observabilite | PASS | log.info sur CRUD, log.error sur erreurs, SLF4J/Logback |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dependance, profils Spring dev/prod |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/073-backend-budget-categories/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── api.md           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── model/
│   ├── Budget.java                    # NOUVEAU
│   └── BudgetSnapshot.java            # NOUVEAU
├── repository/
│   ├── BudgetRepository.java          # NOUVEAU
│   ├── BudgetSnapshotRepository.java  # NOUVEAU
│   └── TransactionRepository.java     # MODIFIE (+query SUM par categorie)
├── service/
│   └── BudgetService.java             # NOUVEAU
├── controller/
│   └── BudgetController.java          # NOUVEAU
├── dto/
│   ├── request/
│   │   └── BudgetRequest.java         # NOUVEAU
│   └── response/
│       ├── BudgetResponse.java              # NOUVEAU
│       ├── BudgetOverviewResponse.java      # NOUVEAU
│       ├── BudgetOverviewItemResponse.java  # NOUVEAU
│       ├── BudgetHistoryResponse.java       # NOUVEAU
│       └── BudgetHistoryItemResponse.java   # NOUVEAU
├── enums/
│   ├── Feature.java                   # MODIFIE (+BUDGETS)
│   └── Frequency.java                 # MODIFIE (+HEBDOMADAIRE)
└── ...

api/src/main/resources/db/migration/
└── V17__add_budgets.sql               # NOUVEAU

api/src/test/java/fr/kksdev/budget/api/
├── controller/
│   └── BudgetControllerTest.java      # NOUVEAU
└── service/
    └── BudgetServiceTest.java         # NOUVEAU
```

**Structure Decision**: Backend uniquement — ajout de fichiers dans l'arborescence existante `api/`. Aucun nouveau module.

## Complexity Tracking

Aucune violation de la constitution. Pas de complexite ajoutee.

## Design Decisions

### 1. Liste sans pagination Spring

Les controllers existants (Category, Account) retournent des `List<>` sans `Page<>`. Un utilisateur a 5-20 categories max, donc 5-20 budgets. Suivre le pattern existant.

### 2. Acces direct au ExchangeRateRepository

BudgetService injecte `ExchangeRateRepository` directement (pas ExchangeRateService) pour la lecture des taux. Pattern existant (PreferenceService → AccountRepository). Evite un couplage service-service.

### 3. Snapshot sans FK vers Budget

BudgetSnapshot reference (user, category, mois) mais PAS le budget. Les snapshots survivent a la suppression du budget (FR-015). FK CASCADE sur category_id pour nettoyage a la suppression de categorie.

### 4. TransactionRepository — nouvelle query

Ajout d'une query native pour sommer les DEPENSES par categorie, utilisateur et plage de dates. Plus performant que charger toutes les transactions en memoire.

### 5. Overview et History — meme structure de reponse

Les deux endpoints retournent une structure similaire (totaux + items par categorie). Les DTOs sont distincts car History inclut `tauxChange` et `createdAt` du snapshot, tandis qu'Overview inclut `budgetId` et `frequence`.
