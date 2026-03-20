# Quickstart — 075-flutter-budget-categories

## Prérequis

- Backend budget API déployé (073-backend-budget-categories)
- Feature BUDGETS activée dans les préférences utilisateur
- Au moins une catégorie créée

## Structure fichiers à créer

```
flutter/lib/src/
├── domain/
│   ├── models/
│   │   ├── budget.dart                    # Freezed: Budget
│   │   ├── budget_overview.dart           # Freezed: BudgetOverview + BudgetOverviewItem
│   │   └── budget_history.dart            # Freezed: BudgetHistory + BudgetHistoryItem
│   └── repositories/
│       └── budget_repository.dart         # Interface abstraite
├── data/
│   ├── local/
│   │   ├── database.dart                  # MODIFIER: +tables Budgets, BudgetSnapshots +BudgetDao
│   │   ├── daos/
│   │   │   └── budget_dao.dart            # DAO Drift
│   │   └── mappers.dart                   # MODIFIER: +budgetFromDb, budgetToDb, snapshotFromDb
│   └── remote/
│       ├── data_sources/
│       │   └── budget_remote_data_source.dart  # Dio calls
│       └── dtos/
│           └── budget_dtos.dart           # Request/Response DTOs
├── features/
│   └── budgets/
│       ├── application/
│       │   ├── budget_notifier.dart        # CRUD notifier
│       │   └── budget_list_state.dart      # Custom ListState
│       ├── data/
│       │   ├── budget_repository_local.dart
│       │   └── budget_repository_remote.dart
│       └── presentation/
│           ├── budget_list_screen.dart     # Écran principal
│           ├── budget_detail_screen.dart   # Écran camembert détail
│           └── widgets/
│               ├── budget_form.dart        # Formulaire modal
│               ├── budget_item.dart        # Item liste avec barre progression
│               ├── budget_summary_bar.dart # Barre résumé global
│               └── budget_pie_chart.dart   # Widget camembert (fl_chart)
├── features/
│   └── dashboard/
│       └── presentation/
│           └── widgets/
│               └── budget_summary_section.dart  # Section dashboard
└── data/
    └── data_mode_provider.dart            # MODIFIER: +budgetRepositoryProvider
```

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `pubspec.yaml` | Ajouter `fl_chart` |
| `domain/enums/feature.dart` | Ajouter `budgets` avec `@JsonValue('BUDGETS')` |
| `domain/enums/modal_type.dart` | Ajouter `ModalType.budget` + maps |
| `data/local/database.dart` | Ajouter tables + DAO |
| `data/local/mappers.dart` | Ajouter mappers budget |
| `data/data_mode_provider.dart` | Ajouter `budgetRepositoryProvider` |
| `routing/app_router.dart` | Ajouter routes `/budgets` et `/budgets/details` |
| `features/dashboard/presentation/dashboard_screen.dart` | Ajouter `BudgetSummarySection` |
| `features/modal/application/modal_notifier.dart` | Support `ModalType.budget` (si nécessaire) |

## Ordre d'implémentation recommandé

1. **Domain** : models + repository interface + enums
2. **Data remote** : DTOs + data source + repository remote
3. **Data local** : tables Drift + DAO + mappers + repository local
4. **Data mode** : provider + code generation (`build_runner`)
5. **Application** : BudgetListState + BudgetNotifier
6. **Presentation** : widgets (item, progress bar, chart) → screens (list, detail, form)
7. **Integration** : routing, dashboard section, FAB, bottom nav
8. **Tests** : notifier tests, widget tests

## Commandes

```bash
# Code generation après ajout tables Drift + Freezed models
cd flutter && dart run build_runner build --delete-conflicting-outputs

# Tests
cd flutter && flutter test test/src/features/budgets/

# Analyse statique
cd flutter && flutter analyze
```
