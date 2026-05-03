# Implementation Plan: Documentation API OpenAPI / Swagger UI

**Branch**: `001-springdoc-openapi` | **Date**: 2026-02-07 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-springdoc-openapi/spec.md`

## Summary

Ajouter springdoc-openapi 3.0.1 au projet pour generer automatiquement une specification OpenAPI 3.1 et une interface Swagger UI interactive. Necessite : 1 dependance Maven, 1 classe de configuration, des modifications mineures a SecurityConfig (routes publiques), et des annotations descriptives sur les 4 controllers existants.

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, springdoc-openapi-starter-webmvc-ui 3.0.1
**Storage**: N/A (pas de nouvelles donnees)
**Testing**: JUnit 5 + Spring Boot Test + Mockito (tests existants, aucun nouveau test requis)
**Target Platform**: Serveur Linux self-hosted
**Project Type**: Single module Maven (API REST)
**Performance Goals**: Page Swagger UI accessible en < 2s apres demarrage
**Constraints**: Aucun — feature additive sans impact sur les endpoints existants
**Scale/Scope**: 4 controllers, 18 endpoints, 10 DTOs a documenter

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Status | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Documente l'API existante, ne modifie aucun contrat |
| II. Securite par defaut | PASS | Routes Swagger en permitAll explicites, routes API toujours protegees |
| III. Simplicite & YAGNI | PASS | 1 dependance, 1 classe config, annotations minimales (@Tag + @Operation) |
| IV. Mobile-First UX | N/A | Pas de frontend concerne |
| V. Testabilite | PASS | Aucun test casse, annotations purement descriptives |
| VI. Observabilite | PASS | Aucun impact sur le logging |
| VII. Self-Hosted Ready | PASS | Pas de dependance SaaS, Swagger UI embarque dans le JAR |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/001-springdoc-openapi/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: recherche et decisions techniques
├── data-model.md        # Phase 1: pas de nouvelles entites
├── quickstart.md        # Phase 1: guide de verification
├── contracts/
│   └── openapi-endpoints.md  # Phase 1: endpoints documentes
├── checklists/
│   └── requirements.md  # Checklist qualite spec
└── tasks.md             # Phase 2 (/speckit.tasks — a venir)
```

### Source Code (repository root)

```text
api/
├── pom.xml                                          # +1 dependance springdoc
└── src/main/java/fr/kksdev/budget/api/
    ├── config/
    │   ├── SecurityConfig.java                      # +3 routes publiques
    │   └── OpenApiConfig.java                       # NOUVEAU — metadata + JWT scheme
    └── controller/
        ├── AuthController.java                      # +@Tag +@Operation (2 methodes)
        ├── TransactionController.java               # +@Tag +@Operation (6 methodes)
        ├── SubscriptionController.java              # +@Tag +@Operation (5 methodes)
        └── DebtController.java                      # +@Tag +@Operation (5 methodes)

README.md                                            # +URL Swagger UI
```

**Structure Decision**: Structure existante conservee. Un seul fichier cree (`OpenApiConfig.java`), le reste est de l'edition de fichiers existants. Conforme au module unique Maven.

## Complexity Tracking

Aucune violation de la constitution — tableau vide.
