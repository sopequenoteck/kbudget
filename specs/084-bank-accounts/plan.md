# Implementation Plan: Banques sur les comptes — liste pré-définie avec logos embarqués

**Branch**: `084-bank-accounts` | **Date**: 2026-03-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/084-bank-accounts/spec.md`
**Status**: Done (plan rétroactif — KKS-197/198/199 terminées)

## Summary

Associer une banque pré-définie (29 banques FR/TG/International) à chaque compte bancaire. La banque fournit automatiquement un logo SVG et une couleur brand, simplifiant la création de compte. Un registre statique embarqué dans le code (pas en base) avec résolution côté service enrichit les réponses API. Option "Autre" pour les banques non listées avec logo custom en base64.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Freezed, Dio, flutter_svg
**Storage**: PostgreSQL 15+ (Flyway V19), SQLite/Drift (migration v3, +3 colonnes)
**Testing**: JUnit 5 + Spring Boot Test (27 tests), Angular tests (347 total), flutter_test (604 total, 9 widget tests bank)
**Target Platform**: Web PWA + Mobile natif (iOS/Android)
**Project Type**: Monorepo web-service + mobile-app
**Performance Goals**: Filtrage client-side sur 29 éléments — pas de latence perceptible
**Constraints**: Logos embarqués en assets statiques (pas de CDN), base64 data URI pour custom logos
**Scale/Scope**: 29 banques statiques, single-user

## Constitution Check

*GATE: Vérification des 7 principes.*

| Principe | Status | Justification |
|----------|--------|---------------|
| I. API-First | PASS | GET /banks endpoint public. Account DTOs enrichis avec 7 champs bank résolus. Jamais d'entité JPA exposée. |
| II. Sécurité par défaut | PASS | GET /banks public (données statiques, pas de risque). Accounts filtrés par user authentifié. |
| III. Simplicité & YAGNI | PASS | Static registry (pas de table Bank en BDD). Résolution via service simple. Pas de pattern complexe. |
| IV. Mobile-First UX | PASS | Sélecteur banque simplifie la création (2-3 interactions). Recherche temps réel. Groupement par pays. |
| V. Testabilité | PASS | 27 tests backend (service + controller), 9 tests widget Flutter. Tests d'intégration sur endpoints. |
| VI. Observabilité | PASS | Logging standard via SLF4J. |
| VII. Self-Hosted Ready | PASS | Logos SVG embarqués dans les assets. Aucune dépendance externe. PostgreSQL seul. |

Aucune violation. Gate passée.

## Project Structure

### Documentation (this feature)

```text
specs/084-bank-accounts/
├── spec.md              # Spécification consolidée
├── plan.md              # Ce fichier
├── research.md          # Phase 0 : décisions techniques
├── data-model.md        # Phase 1 : modèle de données
├── contracts/           # Phase 1 : contrats API
│   └── bank-api.md
└── checklists/
    └── requirements.md  # Checklist qualité spec
```

### Source Code (repository root)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── model/Bank.java                    # Record (code, name, country, brandColor, logoUrl)
│   ├── service/BankRegistry.java          # Registre statique 29 banques
│   ├── service/BankService.java           # Résolution banque → BankResolvedInfo
│   ├── controller/BankController.java     # GET /banks (public)
│   ├── dto/BankResponse.java             # DTO réponse banque
│   ├── dto/AccountRequest.java           # +bankCode, bankCustomName, bankCustomLogo
│   └── dto/AccountResponse.java          # +7 champs bank résolus
├── src/main/resources/
│   ├── db/migration/V19__add_bank_to_accounts.sql
│   └── static/bank-logos/*.svg            # 29 logos SVG
└── src/test/java/.../
    ├── service/BankServiceTest.java
    └── controller/BankControllerTest.java

app/
├── src/app/core/
│   ├── services/bank.ts                   # BankService (signal-based, cache lazy)
│   └── models/account.model.ts            # Account enrichi +7 champs bank
├── src/app/shared/components/
│   ├── bank-select/bank-select.ts         # ControlValueAccessor, groupement, recherche
│   └── account-bank-icon/account-bank-icon.ts  # Cascade SVG → data URI → emoji
└── src/app/shared/utils/image.utils.ts    # compressImage (partagé products + accounts)

flutter/
├── lib/src/
│   ├── domain/
│   │   ├── models/bank.dart               # Freezed model
│   │   └── repositories/bank_repository.dart  # Interface abstraite
│   ├── data/
│   │   └── remote/
│   │       ├── dtos/bank_dtos.dart        # BankResponse DTO
│   │       └── data_sources/bank_remote_data_source.dart
│   ├── features/accounts/
│   │   ├── data/bank_repository_remote.dart
│   │   └── application/bank_provider.dart # FutureProvider
│   └── common_widgets/
│       ├── bank_select_picker.dart         # Bottom sheet groupé + recherche
│       └── account_bank_icon.dart          # Cascade SVG → base64 → emoji
├── assets/banks/*.svg                      # 29 logos SVG embarqués
└── test/src/common_widgets/
    └── account_bank_icon_test.dart         # 9 widget tests
```

**Structure Decision**: Monorepo existant (api/ + app/ + flutter/). Feature transversale touchant les 3 modules. Pas de nouvelle structure créée.

## Complexity Tracking

Aucune violation de constitution à justifier.
