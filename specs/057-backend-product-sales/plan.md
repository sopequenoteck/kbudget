# Implementation Plan: Endpoints ventes et stock produits

**Branch**: `057-backend-product-sales` | **Date**: 2026-02-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/057-backend-product-sales/spec.md`

## Summary

Ajouter les endpoints de vente, restockage et historique des ventes sur les produits existants (KKS-118). Chaque operation genere automatiquement une transaction (RECETTE pour vente, DEPENSE pour restock) liee au produit via un nouveau champ `productId` sur Transaction. Un compte Boutique est cree lazily a la premiere operation. Les preferences utilisateur sont enrichies pour gerer le compte boutique et l'unification des soldes.

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, Flyway, jjwt 0.12.6
**Storage**: PostgreSQL 15+ (Flyway V11)
**Testing**: JUnit 5, Spring Boot Test, Mockito, H2 (profil test)
**Target Platform**: Linux server (self-hosted)
**Project Type**: Web service (API REST)
**Performance Goals**: N/A (mono-utilisateur)
**Constraints**: Operations atomiques (@Transactional), isolation des donnees par user
**Scale/Scope**: Mono-utilisateur, ~3 nouveaux endpoints, ~5 fichiers modifies, ~5 fichiers crees

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Endpoints REST (POST sell, POST restock, GET sales), DTOs dedies, context path `/api` |
| II. Securite par defaut | PASS | JWT obligatoire, `checkShopEnabled`, isolation par userId, Bean Validation sur RestockRequest |
| III. Simplicite & YAGNI | PASS | Architecture Controller → Service → Repository. Pas de pattern complexe. Logique dans ProductService existant |
| IV. Mobile-First UX | N/A | Feature backend uniquement |
| V. Testabilite | PASS | Tests d'integration sur les 3 endpoints + cas d'erreur. Tests unitaires sur ProductService. Nommage `should_*_when_*` |
| VI. Observabilite | PASS | Logging INFO sur vente/restock, ERROR sur echecs. SLF4J/Logback |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dependance. Migration Flyway. Pas de service externe |

**Post-Phase 1 re-check**: Aucune violation. Le design suit les patterns existants sans deviation.

## Project Structure

### Documentation (this feature)

```text
specs/057-backend-product-sales/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── api-endpoints.md # Phase 1 output
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── controller/
│   └── ProductController.java          # MODIFIE — ajout sell, restock, sales
├── service/
│   ├── ProductService.java             # MODIFIE — logique vente/restock/historique
│   ├── TransactionService.java         # MODIFIE — rollback stock sur delete
│   ├── AccountService.java             # MODIFIE — toResponse avec isShopAccount
│   ├── PreferenceService.java          # MODIFIE — shopAccountId, includeShopInBalance
│   └── CategoryService.java            # MODIFIE — seedSystemCategories + findOrCreateShopCategory
├── model/
│   ├── Transaction.java                # MODIFIE — ajout champ product (FK)
│   └── UserPreference.java             # MODIFIE — ajout shopAccountId, includeShopInBalance
├── dto/
│   ├── RestockRequest.java             # NOUVEAU
│   ├── AccountResponse.java            # MODIFIE — ajout isShopAccount
│   ├── TransactionResponse.java        # MODIFIE — ajout productId, productName
│   ├── UserPreferenceRequest.java      # MODIFIE — ajout shopAccountId, includeShopInBalance
│   └── UserPreferenceResponse.java     # MODIFIE — ajout shopAccountId, includeShopInBalance
├── config/
│   └── GlobalExceptionHandler.java     # MODIFIE — ajout ConflictException → 409
├── exception/
│   └── ConflictException.java          # NOUVEAU
├── repository/
│   └── TransactionRepository.java      # MODIFIE — ajout findByProductIdAndUserId

api/src/main/resources/db/migration/
└── V11__add_shop_support.sql           # NOUVEAU

api/src/test/java/fr/kksdev/budget/api/
├── controller/
│   └── ProductSalesIntegrationTest.java # NOUVEAU — tests d'integration
└── service/
    └── ProductServiceTest.java          # NOUVEAU — tests unitaires vente/restock
```

**Structure Decision**: Feature backend uniquement dans `api/`. Modifications sur les fichiers existants + 4 nouveaux fichiers (RestockRequest, ConflictException, migration V11, tests).

## Complexity Tracking

Aucune violation de la constitution. Pas de justification requise.
