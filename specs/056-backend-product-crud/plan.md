# Implementation Plan: Entité Product + CRUD complet (Backend)

**Branch**: `056-backend-product-crud` | **Date**: 2026-02-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/056-backend-product-crud/spec.md`

## Summary

Créer l'entité `Product` et le CRUD REST complet pour la fonctionnalité Boutique. Inclut la migration Flyway, l'entité JPA, les DTOs (request/response), le repository, le service avec isolation par utilisateur et vérification du feature toggle `SHOP`, le controller REST, et les tests d'intégration. Backend uniquement — bloque KKS-124 (Flutter: Formulaire Produit).

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, jjwt 0.12.6
**Storage**: PostgreSQL 15+ (Flyway V10)
**Testing**: JUnit 5, Spring Boot Test, H2 (profil test)
**Target Platform**: Linux server (self-hosted, Docker + Caddy)
**Project Type**: Web service (API REST)
**Performance Goals**: N/A (single-user, self-hosted)
**Constraints**: JWT stateless, isolation données par utilisateur, feature toggle SHOP
**Scale/Scope**: 1 utilisateur, ~100-1000 produits max

## Constitution Check

*GATE: Pré-Phase 0 — toutes les gates PASS.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | CRUD REST avant frontend. DTOs séparés de l'entité. Context path `/api`. |
| II. Sécurité par défaut | PASS | JWT sur tous les endpoints. Isolation par userId. Bean Validation. Feature toggle SHOP. |
| III. Simplicité & YAGNI | PASS | Controller → Service → Repository. Pas de patterns complexes. Toggle check simple dans le service. |
| IV. Mobile-First UX | N/A | Backend uniquement. |
| V. Testabilité | PASS | Tests d'intégration sur endpoints (nominaux + erreurs + limites). Nommage `should_*_when_*`. |
| VI. Observabilité | PASS | `log.info()` pour CRUD, `log.warn()` pour accès refusé, SLF4J/Logback. |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dépendance. Flyway migration auto. |

## Project Structure

### Documentation (this feature)

```text
specs/056-backend-product-crud/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── products-api.md
└── tasks.md             # (Phase 2 — /speckit.tasks)
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── model/
│   └── Product.java                          # CRÉER — Entité JPA
├── dto/
│   ├── request/
│   │   ├── ProductRequest.java               # CRÉER — DTO création
│   │   └── ProductUpdateRequest.java         # CRÉER — DTO modification (inclut actif)
│   └── response/
│       └── ProductResponse.java              # CRÉER — DTO réponse
├── repository/
│   └── ProductRepository.java                # CRÉER — Interface JPA
├── service/
│   ├── ProductService.java                   # CRÉER — Logique métier
│   └── PreferenceService.java                # MODIFIER — Ajout isFeatureEnabled()
├── controller/
│   └── ProductController.java                # CRÉER — Endpoints REST
├── config/
│   └── GlobalExceptionHandler.java           # MODIFIER — FeatureDisabledException handler
└── exception/
    └── FeatureDisabledException.java         # CRÉER — Exception feature toggle

api/src/main/resources/db/migration/
└── V10__add_products.sql                     # CRÉER — Table products

api/src/test/java/fr/kksdev/budget/api/
├── controller/
│   └── ProductControllerIntegrationTest.java # CRÉER — Tests d'intégration
└── service/
    └── ProductServiceTest.java               # CRÉER — Tests unitaires
```

**Structure Decision**: Module backend existant `api/`. Suit la structure en packages existante (`model/`, `dto/`, `repository/`, `service/`, `controller/`). Ajout d'un package `exception/` pour les exceptions métier dédiées (si inexistant, sinon utiliser le package existant).

## Design Decisions

### D1: DTOs séparés pour création et modification

- **ProductRequest** : utilisé pour POST (sans champ `actif`, initialisé à `true`)
- **ProductUpdateRequest** : utilisé pour PUT (inclut `actif` pour le toggle de visibilité)

Rationale : La création n'expose pas `actif` (toujours `true`), tandis que la modification le requiert. Deux DTOs distincts évitent une logique conditionnelle dans la validation.

### D2: Feature toggle via service check

Chaque méthode publique de `ProductService` appelle `preferenceService.isFeatureEnabled(userId, Feature.SHOP)` en premier. Si désactivé, lève `FeatureDisabledException` → 403.

Pattern :
```java
private void checkShopEnabled(UUID userId) {
    if (!preferenceService.isFeatureEnabled(userId, Feature.SHOP)) {
        throw new FeatureDisabledException("SHOP");
    }
}
```

### D3: Mapping entité → DTO dans le service

Méthode privée `toResponse(Product)` dans `ProductService`, cohérent avec le pattern existant (cf. `TransactionService.toResponse()`).

### D4: Suppression physique

`productRepository.delete(product)` — pas de soft delete. Le champ `actif` est un toggle de visibilité indépendant, pas un mécanisme de suppression.

## Complexity Tracking

> Aucune violation de la constitution. Pas de justification nécessaire.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
