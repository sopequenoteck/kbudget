# Implementation Plan: Écran Transactions Liste (Flutter)

**Branch**: `043-flutter-transactions-list` | **Date**: 2026-02-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/043-flutter-transactions-list/spec.md`

## Summary

Implémenter l'écran principal de consultation des transactions dans l'app Flutter. L'écran affiche un sélecteur de mois, un résumé mensuel (recettes/dépenses/bilan), un filtre par type, et la liste des transactions groupées par jour. Approche : notifier dédié (`TransactionListNotifier`) avec chargement par mois via `getByMonth()`, filtrage côté client, et réutilisation des widgets communs existants (`MonthSelector`, `SegmentedFilter`, `ListItem`).

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, shimmer, intl
**Storage**: Drift (SQLite local) / Dio (API REST) via strategy pattern `dataModeProvider`
**Testing**: flutter_test + mockito
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: Mobile app (module Flutter d'un monorepo)
**Performance Goals**: < 2s chargement initial, < 1s changement mois (local), < 100ms filtrage
**Constraints**: Offline-capable (mode local Drift), single-user
**Scale/Scope**: ~100-500 transactions/mois max (usage personnel)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | `getByMonth()` ajouté au repository avec implémentation remote (Dio). L'endpoint API existe déjà partiellement (`getMonthlySummary`). Le `getByMonth` remote appellera `GET /transactions?month=M&year=Y`. |
| II. Sécurité par défaut | PASS | Pas de nouvelles routes API. Le JWT existant protège toutes les requêtes via `JwtInterceptor`. Isolation par user assurée côté API. |
| III. Simplicité & YAGNI | PASS | Un seul notifier dédié, pas de patterns complexes. Réutilisation maximale des widgets existants. Pas d'abstractions superflues. |
| IV. Mobile-First UX | PASS | Écran conçu mobile-first : sélecteur de mois compact, filtre segmenté, liste scrollable avec pull-to-refresh. |
| V. Testabilité | PASS | Notifier testable via `ProviderContainer` + mock repository. Widget tests avec `ProviderScope`. Format de nommage `should_X_when_Y`. |
| VI. Observabilité | N/A | Pas de nouvelles routes backend. Les logs existants couvrent déjà les requêtes API. |
| VII. Self-Hosted Ready | PASS | Aucune nouvelle dépendance infrastructure. Drift local fonctionne offline. |

## Project Structure

### Documentation (this feature)

```text
specs/043-flutter-transactions-list/
├── plan.md              # Ce fichier
├── spec.md              # Spécification feature
├── research.md          # Recherches et décisions
├── data-model.md        # Modèle de données
├── quickstart.md        # Guide de démarrage rapide
└── tasks.md             # Tâches (généré par /speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── domain/
│   ├── models/
│   │   └── monthly_summary.dart          # MODIFIÉ (solde → bilan)
│   └── repositories/
│       └── transaction_repository.dart   # MODIFIÉ (+getByMonth)
│
├── data/
│   ├── local/
│   │   └── daos/
│   │       └── transaction_dao.dart      # MODIFIÉ (+getTransactionsByMonth, fix getMonthlySummary)
│   └── remote/
│       ├── data_sources/
│       │   └── transaction_remote_data_source.dart  # MODIFIÉ (+getByMonth)
│       └── dtos/
│           └── transaction_dtos.dart     # MODIFIÉ (MonthlySummaryResponse.bilan)
│
├── features/
│   ├── transactions/
│   │   ├── application/
│   │   │   ├── transaction_notifier.dart              # EXISTANT (pas modifié)
│   │   │   ├── transaction_list_notifier.dart          # CRÉÉ
│   │   │   └── transaction_list_state.dart             # CRÉÉ
│   │   ├── data/
│   │   │   ├── transaction_repository_local.dart       # MODIFIÉ (+getByMonth, bilan)
│   │   │   └── transaction_repository_remote.dart      # MODIFIÉ (+getByMonth, bilan)
│   │   └── presentation/
│   │       ├── transaction_list_screen.dart            # MODIFIÉ (remplace stub)
│   │       └── widgets/
│   │           ├── transaction_summary_card.dart       # CRÉÉ
│   │           └── transaction_day_group.dart          # CRÉÉ
│   │
│   └── dashboard/
│       └── presentation/widgets/
│           └── monthly_summary_section.dart            # MODIFIÉ (.solde → .bilan)
│
├── utils/
│   └── day_header_formatter.dart                       # CRÉÉ
│
└── [fichiers .freezed.dart et .g.dart régénérés via build_runner]

flutter/test/src/
├── features/transactions/
│   ├── application/
│   │   └── transaction_list_notifier_test.dart         # CRÉÉ
│   └── presentation/
│       └── transaction_list_screen_test.dart           # CRÉÉ
└── utils/
    └── day_header_formatter_test.dart                  # CRÉÉ
```

**Structure Decision**: Module Flutter existant, structure feature-based. Nouveaux fichiers dans `features/transactions/` (application + presentation). Helper partagé dans `utils/`.

## Complexity Tracking

> Aucune violation des principes constitutionnels. Pas de complexité ajoutée au-delà du nécessaire.

| Aspect | Décision | Justification |
|--------|----------|---------------|
| Notifier dédié | `TransactionListNotifier` séparé du `TransactionNotifier` existant | Le notifier existant gère le CRUD global pour le dashboard. Le modifier casserait le dashboard. Deux notifiers = séparation des responsabilités (R2). |
| Enum `TransactionTypeFilter` | Nouvel enum au lieu de `TransactionType?` | Plus explicite que `null` pour "Tous". Coût minimal (3 valeurs). |
| `DayHeaderFormatter` dans `utils/` | Nouveau helper au lieu d'étendre `RelativeDateFormatter` | Format différent requis (jour de la semaine vs "il y a X jours"). Modifier l'existant casserait le dashboard. |
