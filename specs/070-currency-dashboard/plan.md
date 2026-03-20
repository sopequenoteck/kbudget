# Implementation Plan: Currency Dashboard

**Branch**: `070-currency-dashboard` | **Date**: 2026-03-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/070-currency-dashboard/spec.md`

## Summary

Dashboard unifie multi-devises avec taux de conversion manuels. L'utilisateur saisit ses taux, choisit ses devises et voit son patrimoine total agrege dans une devise unique. Changement de devise instantane via pill selector. Full stack : Backend (API REST + Flyway) + Flutter + Angular.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Freezed, Dio
**Storage**: PostgreSQL 15+ (nouvelle table `exchange_rates`, enrichissement `user_preferences`), SQLite/Drift non utilise (taux serveur uniquement)
**Testing**: JUnit 5 + Spring Boot Test (backend), flutter_test (Flutter), Vitest (Angular)
**Target Platform**: Web PWA (Angular) + Mobile natif (Flutter) + API REST (Spring Boot)
**Project Type**: Web-service + mobile-app (monorepo)
**Performance Goals**: Dashboard < 2s chargement (SC-001), changement devise < 200ms percu (SC-002)
**Constraints**: Conversions 100% client-side, taux manuels uniquement (pas d'API externe), single-user self-hosted
**Scale/Scope**: 7 devises (enum fixe), ~10 comptes max, ~3 devises actives typiques

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Nouveaux endpoints CRUD `/exchange-rates` + enrichissement `/users/me/preferences` avant consommation frontend |
| II. Securite par defaut | PASS | JWT sur tous les endpoints, filtrage par user authentifie, Bean Validation sur les taux |
| III. Simplicite & YAGNI | PASS | Controller -> Service -> Repository. Pas de CQRS. Un seul taux par paire (pas d'historique). Conversion client-side simple. |
| IV. Mobile-First UX | PASS | Pill selector pour changement rapide, conversion inline visible, saisie taux en < 30s |
| V. Testabilite | PASS | Tests integration sur endpoints ExchangeRate, tests unitaires sur ExchangeRateService (rebase, validation) |
| VI. Observabilite | PASS | Logging INFO sur creation/modification/suppression taux, ERROR sur echecs |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dependance, pas d'API de taux externe |

**Post-Phase 1 re-check** : Aucune violation detectee. L'architecture reste dans le pattern Controller -> Service -> Repository.

## Project Structure

### Documentation (this feature)

```text
specs/070-currency-dashboard/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── api-contract.md  # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── model/
│   │   └── ExchangeRate.java          # NOUVEAU — entite JPA
│   ├── repository/
│   │   └── ExchangeRateRepository.java # NOUVEAU — JpaRepository
│   ├── service/
│   │   ├── ExchangeRateService.java    # NOUVEAU — CRUD + rebaseRates()
│   │   └── PreferenceService.java      # MODIFIE — gestion currencies
│   ├── controller/
│   │   ├── ExchangeRateController.java # NOUVEAU — CRUD endpoints
│   │   └── PreferenceController.java   # MODIFIE — DTOs currencies
│   ├── dto/
│   │   ├── request/
│   │   │   ├── ExchangeRateRequest.java    # NOUVEAU
│   │   │   └── UserPreferenceRequest.java  # MODIFIE — ajout currencies
│   │   └── response/
│   │       ├── ExchangeRateResponse.java   # NOUVEAU
│   │       └── UserPreferenceResponse.java # MODIFIE — ajout currencies
│   ├── model/
│   │   ├── User.java                   # MODIFIE — suppression defaultCurrency
│   │   └── UserPreference.java         # MODIFIE — ajout currencies
│   └── converter/
│       └── CurrencyListConverter.java  # NOUVEAU — CSV <-> List<Currency>
├── src/main/resources/db/migration/
│   ├── V13__add_currencies_and_exchange_rates.sql  # NOUVEAU
│   └── V14__remove_user_default_currency.sql       # NOUVEAU
└── src/test/java/fr/kksdev/budget/api/
    ├── controller/
    │   └── ExchangeRateControllerTest.java  # NOUVEAU
    └── service/
        └── ExchangeRateServiceTest.java     # NOUVEAU

flutter/test/src/
└── utils/
    └── currency_converter_test.dart         # NOUVEAU — tests unitaires CurrencyConverter

app/src/app/core/services/
└── conversion.spec.ts                       # NOUVEAU — tests unitaires ConversionService

flutter/lib/src/
├── domain/
│   ├── models/
│   │   └── exchange_rate.dart              # NOUVEAU — Freezed model
│   └── repositories/
│       └── exchange_rate_repository.dart    # NOUVEAU — interface
├── features/
│   ├── dashboard/
│   │   ├── application/
│   │   │   └── dashboard_notifier.dart     # MODIFIE — integration taux
│   │   └── presentation/
│   │       ├── dashboard_screen.dart       # MODIFIE — pill selector
│   │       └── widgets/
│   │           ├── currency_pill_selector.dart  # NOUVEAU
│   │           ├── hero_account_section.dart    # MODIFIE — conversion
│   │           └── mini_cards_section.dart      # MODIFIE — conversion
│   ├── exchange_rates/
│   │   ├── application/
│   │   │   ├── exchange_rate_notifier.dart     # NOUVEAU
│   │   │   └── currency_config_notifier.dart   # NOUVEAU — gestion currencies
│   │   ├── data/
│   │   │   ├── exchange_rate_remote_data_source.dart  # NOUVEAU
│   │   │   └── exchange_rate_repository_impl.dart     # NOUVEAU
│   │   └── presentation/
│   │       ├── currency_settings_screen.dart   # NOUVEAU — Devises & Taux
│   │       └── widgets/
│   │           ├── rate_form.dart              # NOUVEAU — formulaire taux
│   │           └── rate_calculator.dart        # NOUVEAU — calculateur
│   ├── transactions/presentation/
│   │   └── transaction_list_screen.dart        # MODIFIE — sous-texte converti
│   ├── subscriptions/presentation/
│   │   └── subscription_list_screen.dart       # MODIFIE — sous-texte converti
│   └── debts/presentation/
│       └── debt_list_screen.dart               # MODIFIE — sous-texte converti
├── utils/
│   └── currency_converter.dart                 # NOUVEAU — helper conversion
└── data/
    └── data_mode_provider.dart                 # MODIFIE — exchangeRateRepositoryProvider

app/src/app/
├── core/
│   ├── models/
│   │   └── exchange-rate.model.ts              # NOUVEAU
│   └── services/
│       ├── exchange-rate.ts                    # NOUVEAU — ExchangeRateService
│       ├── preference.ts                       # MODIFIE — currencies signal
│       └── conversion.ts                       # NOUVEAU — ConversionService
├── features/
│   ├── dashboard/
│   │   ├── dashboard.ts                        # MODIFIE — pill selector + conversion
│   │   └── components/
│   │       └── currency-pill-selector.ts       # NOUVEAU
│   ├── transactions/
│   │   └── transactions.ts                     # MODIFIE — sous-texte converti
│   ├── subscriptions/
│   │   └── subscriptions.ts                    # MODIFIE — sous-texte converti
│   ├── debts/
│   │   └── debts.ts                            # MODIFIE — sous-texte converti
│   └── settings/
│       ├── settings.routes.ts                  # MODIFIE — route currencies
│       └── currency-settings/
│           └── currency-settings.ts            # NOUVEAU
└── shared/pipes/
    └── convert-amount.pipe.ts                  # NOUVEAU — pipe conversion
```

**Structure Decision**: Monorepo existant a 3 modules (api/, app/, flutter/). La feature enrichit les 3 modules. Pas de nouveau module/package — extension des structures existantes.

## Complexity Tracking

> Aucune violation de constitution detectee. Pas de justification necessaire.
