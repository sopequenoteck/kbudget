# Implementation Plan: Système de Feature Toggles — Backend

**Branch**: `055-backend-feature-toggles` | **Date**: 2026-02-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/055-backend-feature-toggles/spec.md`

## Summary

Ajout d'un système de préférences utilisateur permettant d'activer/désactiver les fonctionnalités optionnelles (Abonnements, Dettes, Boutique) et de personnaliser l'ordre de la navigation. Implémentation backend-only via 2 endpoints REST (`GET` et `PUT` sur `/users/me/preferences`), une nouvelle entité `UserPreference` (relation 1:1 avec `User`), un enum `Feature`, et une migration Flyway V9.

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, jjwt 0.12.6
**Storage**: PostgreSQL 15+ (nouvelle table `user_preferences`)
**Testing**: JUnit 5 + Spring Boot Test + Mockito + H2 (profil test)
**Target Platform**: Linux server (self-hosted)
**Project Type**: Web service (API REST)
**Performance Goals**: N/A — CRUD simple, mono-utilisateur
**Constraints**: Pas de dépendance externe supplémentaire, migration Flyway additive
**Scale/Scope**: 1 utilisateur, 3 fonctionnalités optionnelles, 2 endpoints

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Endpoints REST définis avant tout frontend. DTOs séparent API et persistance. Context path `/api` respecté. |
| II. Sécurité par défaut | PASS | Endpoints sous JWT. Données isolées par user authentifié. Inputs validés via Bean Validation. |
| III. Simplicité & YAGNI | PASS | Architecture Controller → Service → Repository. Pas de pattern complexe. Un seul converter JPA pour le stockage des listes. |
| IV. Mobile-First UX | N/A | Feature backend-only — pas d'impact UX direct. |
| V. Testabilité | PASS | Tests d'intégration (@WebMvcTest) sur les endpoints + tests unitaires sur le service. Nommage `should_[résultat]_when_[condition]`. |
| VI. Observabilité | PASS | Logs INFO sur les actions (create, update preferences). Logs WARN sur les cas limites. SLF4J/Logback. |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dépendance. Migration Flyway automatique au démarrage. |

**Post-Phase 1 re-check** : aucune violation détectée. Le `FeatureListConverter` est un converter JPA standard, pas un pattern complexe.

## Project Structure

### Documentation (this feature)

```text
specs/055-backend-feature-toggles/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── preferences-api.md
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── enums/
│   └── Feature.java                        # NOUVEAU
├── model/
│   ├── UserPreference.java                 # NOUVEAU
│   └── converter/
│       └── FeatureListConverter.java       # NOUVEAU
├── dto/
│   ├── request/
│   │   └── UserPreferenceRequest.java      # NOUVEAU
│   └── response/
│       └── UserPreferenceResponse.java     # NOUVEAU
├── repository/
│   └── UserPreferenceRepository.java       # NOUVEAU
├── service/
│   └── PreferenceService.java              # NOUVEAU
└── controller/
    └── PreferenceController.java           # NOUVEAU

api/src/main/resources/db/migration/
└── V9__add_user_preferences.sql            # NOUVEAU

api/src/test/java/fr/kksdev/budget/api/
├── controller/
│   └── PreferenceControllerTest.java       # NOUVEAU
└── service/
    └── PreferenceServiceTest.java          # NOUVEAU
```

**Structure Decision**: Feature entièrement additive — aucun fichier existant modifié. Suit la structure `enums/`, `model/`, `dto/`, `repository/`, `service/`, `controller/` existante.

## Complexity Tracking

Aucune violation de la constitution détectée. Pas de justification nécessaire.
