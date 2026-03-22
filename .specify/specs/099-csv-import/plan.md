# Implementation Plan: Import de releves bancaires CSV

**Branch**: `099-csv-import` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/099-csv-import/spec.md`

## Summary

Import de releves bancaires CSV avec parsing cote API (Spring Boot), review interactif cote Angular, brouillons persistants, categorisation par apprentissage (regles pattern → categorie), et deduplication fuzzy (Jaro-Winkler). Architecture : upload multipart → parsing via Commons CSV avec detection auto du format par bankCode du compte → brouillon persistant avec lignes pre-analysees → review interactif Angular → confirmation tout-ou-rien via `saveAll()` transactionnel.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (frontend Angular)
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Apache Commons CSV 1.11.0 (nouveau), Apache Commons Text 1.12.0 (nouveau), Angular 21
**Storage**: PostgreSQL 15+ (Flyway V22 — 5 nouvelles tables)
**Testing**: JUnit 5 + Spring Boot Test + Mockito (backend), Vitest (frontend)
**Target Platform**: Web (self-hosted server + PWA Angular mobile-first)
**Project Type**: Web application (monorepo API + frontend)
**Performance Goals**: Parsing 200 lignes CSV < 3 secondes (SC-007)
**Constraints**: Fichier CSV max 5 Mo, encodages UTF-8 et ISO-8859-1, pas de Flutter dans cette iteration
**Scale/Scope**: Single-user, imports de 50-200 lignes typiques, max ~500 lignes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-research check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. API-First | PASS | Parsing cote serveur, endpoints REST, DTOs request/response |
| II. Securite par defaut | PASS | Endpoints proteges JWT, isolation par user, Bean Validation sur inputs |
| III. Simplicite & YAGNI | PASS | Controller → Service → Repository, pas de patterns complexes |
| IV. Mobile-First UX | PASS | Page Settings > Import, icone d'import par compte, review interactif |
| V. Testabilite | PASS | Tests integration endpoints, tests unitaires services (parsing, dedup, nettoyage) |
| VI. Observabilite | PASS | Logger INFO pour upload/confirm, ERROR pour parsing failures |
| VII. Self-Hosted Ready | PASS | Pas de dependance cloud, PostgreSQL uniquement |

### Post-design check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. API-First | PASS | 15 endpoints definis dans contracts/api-endpoints.md, DTOs complets |
| II. Securite par defaut | PASS | Tous les endpoints filtrent par user authentifie, validation multipart (taille, format) |
| III. Simplicite & YAGNI | PASS | Services decomposes par responsabilite (parsing, nettoyage, dedup, regles) sans sur-abstraction |
| IV. Mobile-First UX | PASS | Upload accessible depuis comptes + settings, review avec indicateur de progression |
| V. Testabilite | PASS | CsvParsingService, LabelCleaningService, DeduplicationService testables unitairement avec des CSV de test |
| VI. Observabilite | PASS | Chaque upload et confirmation logge au niveau INFO |
| VII. Self-Hosted Ready | PASS | Commons CSV et Commons Text sont des dependances Java pures, pas de service externe |

## Project Structure

### Documentation (this feature)

```text
specs/099-csv-import/
├── spec.md              # Specification feature
├── plan.md              # This file
├── research.md          # Phase 0 output — decisions techniques
├── data-model.md        # Phase 1 output — 5 entites, enums, relations
├── quickstart.md        # Phase 1 output — setup et test rapide
├── contracts/
│   └── api-endpoints.md # Phase 1 output — 15 endpoints REST
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── model/
│   │   ├── ImportProfile.java          # Profils custom (JPA)
│   │   ├── ImportDraft.java            # Brouillon d'import
│   │   ├── ImportDraftLine.java        # Ligne de brouillon
│   │   ├── CategoryRule.java           # Regle de categorisation
│   │   └── ImportHistory.java          # Historique
│   ├── enums/
│   │   ├── ImportDraftStatus.java      # PENDING, COMPLETED, EXPIRED
│   │   └── ImportLineStatus.java       # READY, NEEDS_REVIEW, DUPLICATE, SKIPPED
│   ├── repository/                     # 5 JpaRepository
│   ├── service/
│   │   ├── ImportService.java          # Orchestration
│   │   ├── ImportProfileRegistry.java  # Profils pre-configures (statique)
│   │   ├── CsvParsingService.java      # Parsing + detection format
│   │   ├── LabelCleaningService.java   # Nettoyage libelles
│   │   ├── DeduplicationService.java   # Detection doublons Jaro-Winkler
│   │   ├── CategoryRuleService.java    # CRUD regles + application
│   │   └── ImportDraftCleanupJob.java  # @Scheduled cleanup 7j
│   ├── controller/
│   │   └── ImportController.java       # /imports/**
│   └── dto/
│       ├── request/                    # 4 DTOs request
│       └── response/                   # 8 DTOs response
├── src/main/resources/
│   └── db/migration/
│       └── V22__csv_import.sql         # 5 tables + index
└── src/test/java/                      # Tests integration + unitaires

app/
├── src/app/
│   ├── core/services/
│   │   ├── import.ts                   # ImportService Angular
│   │   └── category-rule.ts            # CategoryRuleService Angular
│   └── features/settings/components/
│       ├── import-settings/            # Hub Settings > Import
│       ├── import-review/              # Review brouillon
│       └── csv-mapping/                # Mapping manuel colonnes
```

**Structure Decision**: Web application (Option 2 du template). Backend dans `api/`, frontend dans `app/`. Suit exactement la structure existante du monorepo — pas de nouveau module.

## Complexity Tracking

Aucune violation de la constitution. Pas de complexite additionnelle non justifiee.

| Decision | Justification |
|----------|---------------|
| 2 nouvelles dependances Maven (Commons CSV + Commons Text) | Bibliotheques legeres, standards Java, pas de service externe. Justifie par la complexite du parsing CSV et du matching flou. |
| Multipart upload (nouveau pattern) | Premier usage dans le projet. Justifie : le CSV peut aller jusqu'a 5 Mo, le base64 existant (images) n'est pas adapte. |
| 5 nouvelles tables BDD | Minimum necessaire : profils, brouillons, lignes, regles, historique. Chacune correspond a une entite metier distincte de la spec. |
