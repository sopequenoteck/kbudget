# Implementation Plan: Gestion des devises (multi-currency)

**Branch**: `030-multi-currency` | **Date**: 2026-02-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/030-multi-currency/spec.md`

## Summary

Ajout du support multi-devises à l'application budget. Chaque compte bancaire a une devise fixe (ISO 4217), chaque dette et abonnement a un champ devise, et l'utilisateur a une devise par défaut configurable. Pas de conversion entre devises. Les totaux du dashboard sont groupés par devise. Approche : nouveau enum `Currency` côté backend, migration Flyway V8, modification des DTOs et services existants, pipe Angular dynamique côté frontend.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (frontend)
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security + JWT, Angular 21, Lombok
**Storage**: PostgreSQL 15+, Flyway migrations (V1-V7 existantes, V8 pour cette feature)
**Testing**: JUnit 5 + Spring Boot Test + Mockito (backend), Karma/Jasmine (frontend)
**Target Platform**: Docker + Caddy (self-hosted), PWA mobile-first
**Project Type**: Web application (monorepo api/ + app/)
**Performance Goals**: Single-user, pas de contrainte spécifique
**Constraints**: Pas de conversion entre devises, pas de service externe, liste fermée de devises en code
**Scale/Scope**: Single-user, 7 devises supportées initialement, ~15 fichiers backend modifiés, ~20 fichiers frontend modifiés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principe | Statut | Justification |
|---|----------|--------|---------------|
| I | API-First | PASS | Nouveaux endpoints (GET /currencies, PUT /users/me) et modification des DTOs existants. Backend = source de vérité pour devises supportées et validation. |
| II | Sécurité par défaut | PASS | Filtrage par user authentifié conservé. Bean Validation sur currency (code ISO 3 chars). Pas de nouveau secret. |
| III | Simplicité & YAGNI | PASS | Enum Java pour devises (pattern existant). Pas de table en base pour devises, pas de taux de change. Architecture Controller → Service → Repository inchangée. |
| IV | Mobile-First UX | PASS | SelectPicker existant réutilisé pour sélection devise. Workflow de saisie inchangé (+1 champ pré-rempli). |
| V | Testabilité | PASS | Tests d'intégration sur endpoints modifiés. Tests unitaires sur validation devise (transfer cross-currency, immutabilité compte). Nommage should_X_when_Y. |
| VI | Observabilité | PASS | Logging des opérations de création/modification avec devise. Pas de nouveau système de monitoring. |
| VII | Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée. Migration Flyway standard. PostgreSQL seule infra. |

**Résultat** : Toutes les gates passent. Aucune violation de constitution.

## Project Structure

### Documentation (this feature)

```text
specs/030-multi-currency/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── accounts.md
│   ├── debts.md
│   ├── subscriptions.md
│   ├── transactions.md
│   ├── users.md
│   └── currencies.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── enums/
│   │   └── Currency.java              # NEW - Enum devises supportées
│   ├── model/
│   │   ├── Account.java               # MOD - ajout champ currency
│   │   ├── User.java                  # MOD - ajout champ defaultCurrency
│   │   ├── Debt.java                  # MOD - ajout champ currency
│   │   └── Subscription.java          # MOD - ajout champ currency
│   ├── dto/
│   │   ├── request/
│   │   │   ├── AccountRequest.java    # MOD - ajout currency
│   │   │   ├── DebtRequest.java       # MOD - ajout currency
│   │   │   ├── SubscriptionRequest.java # MOD - ajout currency
│   │   │   └── UserUpdateRequest.java # NEW - mise à jour profil
│   │   └── response/
│   │       ├── AccountResponse.java   # MOD - ajout currency
│   │       ├── AccountSummary.java    # MOD - ajout currency
│   │       ├── DebtResponse.java      # MOD - ajout currency
│   │       ├── SubscriptionResponse.java # MOD - ajout currency
│   │       ├── UserResponse.java      # NEW - profil avec defaultCurrency
│   │       ├── MonthlySummaryResponse.java # MOD - ajout currency
│   │       └── CurrencyInfo.java      # NEW - infos devise pour GET /currencies
│   ├── controller/
│   │   ├── AccountController.java     # MOD - validation transfer cross-currency
│   │   ├── UserController.java        # NEW - GET/PUT /users/me
│   │   └── CurrencyController.java    # NEW - GET /currencies
│   ├── service/
│   │   ├── AccountService.java        # MOD - transfer validation, currency immutabilité
│   │   ├── DebtService.java           # MOD - currency par défaut
│   │   ├── SubscriptionService.java   # MOD - currency forcée depuis account
│   │   ├── TransactionService.java    # MOD - summary groupé par currency
│   │   └── UserService.java           # NEW - update preferences
│   └── repository/
│       └── TransactionRepository.java # MOD - query summary par currency
├── src/main/resources/
│   └── db/migration/
│       └── V8__add_currency_support.sql # NEW - migration multi-devises
└── src/test/java/fr/kksdev/budget/api/
    ├── controller/
    │   ├── AccountControllerTest.java   # MOD - tests transfer cross-currency
    │   ├── CurrencyControllerTest.java  # NEW
    │   └── UserControllerTest.java      # NEW
    └── service/
        ├── AccountServiceTest.java      # MOD - tests immutabilité devise
        ├── SubscriptionServiceTest.java # MOD - tests devise forcée
        └── TransactionServiceTest.java  # MOD - tests summary groupé

app/
├── src/app/
│   ├── core/
│   │   ├── models/
│   │   │   ├── account.model.ts       # MOD - ajout currency
│   │   │   ├── debt.model.ts          # MOD - ajout currency
│   │   │   ├── subscription.model.ts  # MOD - ajout currency
│   │   │   ├── transaction.model.ts   # MOD - MonthlySummary avec currency
│   │   │   ├── user.model.ts          # MOD - ajout defaultCurrency
│   │   │   └── currency.model.ts      # NEW - CurrencyInfo interface
│   │   └── services/
│   │       ├── user.ts                # NEW - UserService (preferences)
│   │       └── currency.ts            # NEW - CurrencyService
│   ├── shared/
│   │   ├── pipes/
│   │   │   └── amount.pipe.ts         # MOD - paramètre currency dynamique
│   │   └── components/
│   │       └── account-form/
│   │           └── account-form.ts    # MOD - sélecteur devise
│   └── features/
│       ├── dashboard/
│       │   ├── dashboard.ts           # MOD - totaux groupés par devise
│       │   └── dashboard.html         # MOD - sections par devise
│       ├── debts/components/
│       │   └── debt-form/debt-form.ts # MOD - sélecteur devise
│       ├── subscriptions/components/
│       │   └── subscription-form/subscription-form.ts # MOD - devise auto/manuelle
│       └── settings/components/
│           └── profile/profile.ts     # MOD - sélecteur devise par défaut
```

**Structure Decision**: Web application existante (monorepo api/ + app/). Pas de nouveau module. Modifications dans les packages existants conformément au principe III (Simplicité).

## Complexity Tracking

Aucune violation de constitution à justifier. La feature s'intègre dans l'architecture existante sans pattern supplémentaire.
