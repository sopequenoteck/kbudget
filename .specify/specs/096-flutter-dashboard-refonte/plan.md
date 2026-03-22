# Implementation Plan: Refonte Dashboard Flutter

**Branch**: `096-flutter-dashboard-refonte` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/096-flutter-dashboard-refonte/spec.md`

## Summary

Refonte du dashboard Flutter pour l'aligner sur le wireframe valide (KKS-161), deja implemente cote Angular (KKS-200). Remplacement des widgets existants (HeroAccountSection, MonthlySummarySection, MiniCardsSection) par une structure patrimoine-first : carte Patrimoine Total avec variation mensuelle, cartes Revenus/Depenses en devise principale avec delta vs mois precedent, header enrichi (cloche + avatar avec menu), transactions recentes avec badges devise et conversion, et section budgets conditionnelle.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, dio, shimmer, intl, phosphor_flutter
**Storage**: API REST (mode serveur) via Dio. Pas de Drift/SQLite pour cette feature (donnees toujours fraiches depuis l'API)
**Testing**: flutter_test (widget tests + unit tests), ProviderContainer avec overrides
**Target Platform**: iOS + Android (mobile-first)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Chargement initial < 3s, pull-to-refresh < 5s
**Constraints**: Offline-degraded (patrimoine et conversion non disponibles sans API), aligne sur l'implementation Angular KKS-200
**Scale/Scope**: Single-user, 1 ecran (dashboard), ~8 widgets a creer/modifier

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Notes |
|----------|--------|-------|
| I. API-First | PASS | Pas de nouvel endpoint. Consomme les APIs existantes (accounts, transactions/summary, exchange-rates, preferences, budgets/overview) |
| II. Securite | PASS | JWT deja en place. Donnees filtrees par user. Menu avatar ajoute logout (AuthService existant) |
| III. Simplicite & YAGNI | PASS | Enrichissement du DashboardNotifier existant. Pas de nouveau pattern, pas d'abstraction supplementaire |
| IV. Mobile-First UX | VIOLATION JUSTIFIEE | Le dashboard ne montrera plus le resume abonnements/dettes (MiniCards supprimees). Justification : wireframe KKS-161 valide, ces donnees restent accessibles via navigation dediee. Le dashboard se concentre sur le patrimoine et les flux mensuels |
| V. Testabilite | PASS | Tests unitaires DashboardNotifier (calculs) + tests widget (composants principaux) |
| VI. Observabilite | N/A | Feature frontend uniquement, pas de logging backend |
| VII. Self-Hosted Ready | PASS | Aucun changement d'infrastructure |

## Project Structure

### Documentation (this feature)

```text
specs/096-flutter-dashboard-refonte/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
flutter/lib/src/features/dashboard/
├── application/
│   ├── dashboard_notifier.dart     # MODIFIER — enrichir avec patrimoine, variation, summaries courant+precedent
│   └── dashboard_state.dart        # MODIFIER — ajouter champs patrimoine, variation, currentSummary, previousSummary
├── presentation/
│   ├── dashboard_screen.dart       # MODIFIER — restructurer layout, CustomScrollView
│   └── widgets/
│       ├── dashboard_header.dart           # CREER — salutation + cloche + avatar menu
│       ├── patrimoine_card.dart            # CREER — remplace hero_account_section
│       ├── income_expense_cards.dart       # CREER — remplace monthly_summary_section
│       ├── recent_transactions_section.dart # MODIFIER — ajouter badges devise + conversion
│       ├── budget_summary_section.dart     # MODIFIER — tri par %, max 4 items
│       ├── currency_pill_selector.dart     # CONSERVER tel quel
│       ├── hero_account_section.dart       # SUPPRIMER
│       ├── monthly_summary_section.dart    # SUPPRIMER
│       └── mini_cards_section.dart         # SUPPRIMER
└── (pas de data layer specifique — reutilise les notifiers/repositories existants)

flutter/test/src/features/dashboard/
├── application/
│   └── dashboard_notifier_test.dart  # CREER/MODIFIER — tests calculs patrimoine, variation, delta
└── presentation/
    └── widgets/
        ├── dashboard_header_test.dart          # CREER
        ├── patrimoine_card_test.dart           # CREER
        └── income_expense_cards_test.dart      # CREER
```

**Structure Decision**: Feature Flutter uniquement. Modification in-place du module `features/dashboard/`. Pas de nouveau data layer — le dashboard agrege les donnees des notifiers existants (accounts, transactions, exchange_rates, budgets, subscriptions, debts). Les widgets remplaces (HeroAccountSection, MonthlySummarySection, MiniCardsSection) sont supprimes apres creation de leurs remplacants.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Constitution IV : MiniCards (resume abonnements/dettes) supprimees du dashboard | Wireframe KKS-161 valide ne les inclut pas. Le dashboard se concentre sur patrimoine + flux mensuels. Angular KKS-200 les a deja supprimees. | Conserver les MiniCards en plus du wireframe ajouterait du bruit visuel et divergerait du wireframe valide et de l'implementation Angular |
