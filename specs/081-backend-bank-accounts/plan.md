# Implementation Plan: Banques sur les comptes — Backend

**Branch**: `081-backend-bank-accounts` | **Date**: 2026-03-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/081-backend-bank-accounts/spec.md`

## Summary

Ajouter le concept de banque aux comptes utilisateur. Un registre statique de 29 banques (15 FR, 12 TG/UEMOA, 1 International, 1 OTHER) est exposé via un endpoint public GET /api/banks. L'entité Account est enrichie de 3 champs (bankCode, bankCustomName, bankCustomLogo). Les logos SVG sont servis comme ressources statiques. Une migration Flyway V19 ajoute les colonnes et initialise les comptes existants à "OTHER".

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security, Lombok, Flyway, jjwt 0.12.6
**Storage**: PostgreSQL 15+ (Flyway V19)
**Testing**: JUnit 5 + Spring Boot Test + Mockito + H2
**Target Platform**: Linux server (self-hosted Docker)
**Project Type**: Web service (API REST)
**Performance Goals**: N/A (endpoint statique, données en mémoire)
**Constraints**: Endpoint GET /banks public (sans auth), données banques statiques en code
**Scale/Scope**: Single-user, 29 banques, ~10 comptes max par utilisateur

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Endpoint REST GET /banks + enrichissement DTOs Account. Pas d'entité JPA exposée. |
| II. Sécurité par défaut | PASS | GET /banks explicitement public dans SecurityConfig. Comptes restent protégés JWT + isolation user. |
| III. Simplicité & YAGNI | PASS | Données banques statiques en code (registre Map). Pas de table en base. Controller → Service simple. |
| IV. Mobile-First UX | PASS | Backend-only. Les frontends consommeront l'endpoint et les logos statiques. |
| V. Testabilité | PASS | Tests intégration sur endpoints (GET /banks, POST/PUT /accounts avec bankCode). Tests unitaires sur BankRegistry. |
| VI. Observabilité | PASS | Logging INFO sur association/changement de banque. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe. Logos embarqués dans le classpath. |

**GATE RESULT: PASS** — Aucune violation détectée.

## Project Structure

### Documentation (this feature)

```text
specs/081-backend-bank-accounts/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── controller/
│   └── BankController.java          # NEW — GET /banks
├── service/
│   ├── BankRegistry.java            # NEW — registre statique Map<String, Bank> (pas un @Service)
│   └── BankService.java             # NEW — résolution bankCode → Bank
├── model/
│   ├── Account.java                 # MODIFIED — +bankCode, +bankCustomName, +bankCustomLogo
│   └── Bank.java                    # NEW — record/POJO statique (code, nom, pays, couleur, logoUrl)
├── dto/
│   ├── response/
│   │   ├── BankResponse.java        # NEW — réponse GET /banks
│   │   ├── AccountResponse.java     # MODIFIED — +bankCode, +bankName, +bankCountry, +bankBrandColor, +bankLogoUrl, +bankCustomName, +bankCustomLogo
│   │   └── AccountSummary.java      # MODIFIED — +bankCode
│   └── request/
│       └── AccountRequest.java      # MODIFIED — +bankCode, +bankCustomName, +bankCustomLogo
├── config/
│   └── SecurityConfig.java          # MODIFIED — /banks (exact) + /bank-logos/** public
└── enums/
    └── (pas de nouvel enum — bankCode est un String, pas un enum Java)

api/src/main/resources/
├── db/migration/
│   └── V19__add_bank_to_accounts.sql  # NEW — ALTER accounts + DEFAULT 'OTHER'
└── static/bank-logos/
    └── *.svg                          # 29 fichiers logos SVG (déplacés depuis static/banks/ par T002)

api/src/test/java/fr/kksdev/budget/api/
├── controller/
│   └── BankControllerTest.java        # NEW — tests intégration
└── service/
    └── BankServiceTest.java           # NEW — tests unitaires
```

**Structure Decision**: Feature backend-only dans le module `api/` existant. Nouveau controller + service pour les banques. Enrichissement de l'entité Account et de ses DTOs. Pas de nouveau package — les fichiers s'intègrent dans la structure existante.

## Complexity Tracking

> Aucune violation de constitution détectée. Tableau vide.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
