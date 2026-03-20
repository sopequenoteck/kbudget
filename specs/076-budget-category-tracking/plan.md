# Implementation Plan: Budgets par catégorie — suivi des dépenses avec snapshots mensuels

**Branch**: `076-budget-category-tracking` | **Date**: 2026-03-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/076-budget-category-tracking/spec.md`

## Summary

Cette feature complète l'implémentation existante des budgets (KKS-073/074/075) avec les fonctionnalités manquantes : catégorie "Autre" (dépenses non budgétées) avec drill-down, notifications de seuil (80%/100%) déclenchées à la création de transaction, toggle actif/inactif dans les UI, et corrections du mode local Flutter (snapshots lazy, conversion multi-devises).

### Delta par rapport à l'existant

| Fonctionnalité | Backend (073) | Angular (074) | Flutter (075) |
|----------------|:---:|:---:|:---:|
| CRUD budgets | Complet | Complet | Complet |
| Dashboard top 5 | Complet | Complet | Complet |
| Historique + camembert | Complet | Complet | Complet |
| **Catégorie "Autre" + drill-down** | **À ajouter** | **À ajouter** | **À ajouter** |
| **Notifications seuil (80%/100%)** | **À ajouter** | N/A (passif) | N/A (passif) |
| **Toggle actif/inactif UI** | Complet | **À ajouter** | **À ajouter** |
| **Snapshots lazy (local)** | N/A | N/A | **À ajouter** |
| **Conversion multi-devises (local)** | N/A | N/A | **À ajouter** |

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, ng2-charts, fl_chart
**Storage**: PostgreSQL 15+ (backend), SQLite/Drift (Flutter local)
**Testing**: JUnit 5 + Mockito (backend), flutter_test (Flutter)
**Target Platform**: Web (Angular PWA) + Mobile (Flutter iOS/Android) + API REST
**Project Type**: Monorepo web-service + mobile-app
**Performance Goals**: Dashboard < 2s, navigation historique < 2s, notification < 5min post-transaction
**Constraints**: Self-hosted, single-user, offline-capable (Flutter local mode)
**Scale/Scope**: Single user, ~100 catégories max, ~12 mois d'historique

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Commentaire |
|----------|--------|-------------|
| I. API-First | PASS | Les endpoints overview/history seront enrichis côté API avant les frontends. "Autre" calculé côté API. |
| II. Sécurité par défaut | PASS | Filtrage par user authentifié existant. Notifications filtrées par user. |
| III. Simplicité & YAGNI | PASS | Pas de nouveau pattern — extension des services existants (BudgetService, TransactionService, NotificationService). |
| IV. Mobile-First UX | PASS | Toggle actif/inactif accessible, "Autre" cliquable, notifications push. |
| V. Testabilité | PASS | Tests unitaires BudgetService (notifications), tests d'intégration endpoints enrichis. |
| VI. Observabilité | PASS | Logs INFO pour notifications envoyées, WARN pour taux manquant. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée. |

## Project Structure

### Documentation (this feature)

```text
specs/076-budget-category-tracking/
├── spec.md              # Spécification feature
├── plan.md              # Ce fichier
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-endpoints.md # Endpoints modifiés/ajoutés
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── enums/
│   ├── NotificationType.java      # + BUDGET_THRESHOLD, BUDGET_EXCEEDED
│   └── EntityType.java            # + BUDGET
├── service/
│   ├── BudgetService.java         # + getUnbudgetedSpending(), checkThresholds()
│   ├── TransactionService.java    # + hook post-create/update/delete → budget check
│   └── NotificationService.java   # (existant, utilisé par BudgetService)
├── dto/response/
│   ├── BudgetOverviewResponse.java    # + unbudgetedItems, unbudgetedTotal
│   └── BudgetHistoryResponse.java     # + unbudgetedItems, unbudgetedTotal
└── repository/
    └── TransactionRepository.java     # + query dépenses par catégories non budgétées

app/src/app/
├── core/models/budget.model.ts        # + UnbudgetedItem type
├── features/budgets/components/
│   ├── budget-list/budget-list.ts     # + section "Autre" + toggle actif
│   ├── budget-detail/budget-detail.ts # + section "Autre" drill-down
│   ├── budget-chart.ts                # + section "Autre" grise dans le doughnut
│   └── budget-form/budget-form.ts     # + toggle actif/inactif
└── features/dashboard/components/
    └── budget-summary/budget-summary.ts  # (inchangé)

flutter/lib/src/features/budgets/
├── application/budget_notifier.dart   # (inchangé, overview/history enrichis par API)
├── data/
│   ├── budget_repository_local.dart   # + getUnbudgetedSpending(), lazy snapshots, multi-devise
│   └── budget_repository_remote.dart  # + mapping nouveaux champs "Autre"
├── presentation/
│   ├── budget_list_screen.dart        # + section "Autre" + toggle actif
│   ├── budget_detail_screen.dart      # + "Autre" drill-down
│   └── widgets/
│       ├── budget_form.dart           # + toggle actif/inactif
│       └── unbudgeted_detail_sheet.dart  # NOUVEAU : drill-down "Autre"
└── domain/models/
    ├── budget_overview.dart           # + unbudgetedItems, unbudgetedTotal
    └── budget_history.dart            # + unbudgetedItems, unbudgetedTotal
```

**Structure Decision**: Extension de la structure existante. Aucun nouveau module, uniquement enrichissement des fichiers existants + 1 nouveau widget Flutter pour le drill-down "Autre".

## Complexity Tracking

Aucune violation des principes constitutionnels. Pas de déviation nécessaire.
