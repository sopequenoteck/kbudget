# Implementation Plan: Budgets par catégorie — Flutter

**Branch**: `075-flutter-budget-categories` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/075-flutter-budget-categories/spec.md`

## Summary

Implémenter le module budgets dans l'app Flutter : section dashboard avec résumé budgets (top 5), écran dédié avec liste/sélecteur de mois, formulaire création/édition (modal bottom sheet), suppression avec confirmation, et écran détail avec graphique camembert (fl_chart). Data mode local+remote (Drift + Dio) via `dataModeProvider`. Backend déjà implémenté (7 endpoints).

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, drift, dio, fl_chart (nouveau), shimmer, intl, phosphor_flutter
**Storage**: SQLite/Drift (local) + API REST/Dio (remote) via strategy pattern `dataModeProvider`
**Testing**: flutter_test + mockito
**Target Platform**: iOS + Android (mobile-first)
**Project Type**: Mobile app (Flutter module dans monorepo)
**Performance Goals**: < 2s chargement dashboard, navigation mois instantanée
**Constraints**: Offline-capable (mode local Drift), respect design system tokens
**Scale/Scope**: Single-user, ~50 budgets max, 12 mois d'historique

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Backend 073 déjà implémenté avec 7 endpoints REST. DTOs séparent API de persistance. |
| II. Sécurité par défaut | PASS | JWT requis sur tous les endpoints. Filtrage par user authentifié côté backend. |
| III. Simplicité & YAGNI | PASS | Réutilise patterns existants (CRUD Notifier, ListState, ModalNotifier, dataModeProvider). Pas d'abstraction nouvelle. |
| IV. Mobile-First UX | PASS | Formulaire en modal bottom sheet (2-3 interactions). FAB sur écran budgets. Dashboard summary visible immédiatement. |
| V. Testabilité | PASS | Notifier testable via ProviderContainer + mocks. Widgets testables via ProviderScope. |
| VI. Observabilité | PASS | Pas de logging Flutter spécifique requis (backend logge déjà les actions). |
| VII. Self-Hosted Ready | PASS | Pas de nouvelle dépendance infra. fl_chart est une lib UI pure. |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/075-flutter-budget-categories/
├── spec.md              # Spécification feature
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── budget-api.md    # Contrats API backend
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── domain/
│   ├── models/
│   │   ├── budget.dart                         # NEW
│   │   ├── budget_overview.dart                # NEW
│   │   └── budget_history.dart                 # NEW
│   ├── repositories/
│   │   └── budget_repository.dart              # NEW
│   └── enums/
│       ├── feature.dart                        # MODIFY (+budgets)
│       └── modal_type.dart                     # MODIFY (+budget)
├── data/
│   ├── local/
│   │   ├── database.dart                       # MODIFY (+tables, +DAO)
│   │   ├── daos/
│   │   │   └── budget_dao.dart                 # NEW
│   │   └── mappers.dart                        # MODIFY (+budget mappers)
│   ├── remote/
│   │   ├── data_sources/
│   │   │   └── budget_remote_data_source.dart  # NEW
│   │   └── dtos/
│   │       └── budget_dtos.dart                # NEW
│   └── data_mode_provider.dart                 # MODIFY (+budgetRepositoryProvider)
├── features/
│   ├── budgets/
│   │   ├── application/
│   │   │   ├── budget_notifier.dart            # NEW
│   │   │   └── budget_list_state.dart          # NEW
│   │   ├── data/
│   │   │   ├── budget_repository_local.dart    # NEW
│   │   │   └── budget_repository_remote.dart   # NEW
│   │   └── presentation/
│   │       ├── budget_list_screen.dart          # NEW
│   │       ├── budget_detail_screen.dart        # NEW
│   │       └── widgets/
│   │           ├── budget_form.dart             # NEW
│   │           ├── budget_item.dart             # NEW
│   │           ├── budget_summary_bar.dart      # NEW
│   │           └── budget_pie_chart.dart         # NEW
│   └── dashboard/
│       └── presentation/
│           ├── dashboard_screen.dart            # MODIFY (+budget section)
│           └── widgets/
│               └── budget_summary_section.dart  # NEW
├── routing/
│   └── app_router.dart                          # MODIFY (+budget routes)
└── pubspec.yaml                                 # MODIFY (+fl_chart)
```

**Structure Decision**: Feature module `budgets/` suivant le pattern existant (application/data/presentation). Intégration dans le dashboard via widget dédié.

## Complexity Tracking

> Aucune violation de constitution détectée. Tableau non applicable.
