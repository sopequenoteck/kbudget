# Quickstart: Flutter Dashboard Complet

**Date**: 2026-02-22 | **Feature**: 042-flutter-dashboard

## Prerequisites

- Flutter >= 3.27 (stable)
- Projet Flutter existant dans `flutter/`
- Widgets disponibles : MonthSelector, ListItem (common_widgets/)
- Notifiers CRUD existants : account, transaction, subscription, debt, category
- Endpoint API : `GET /api/transactions/summary?month=X&year=Y`

## Fichiers a creer

| Fichier | Description |
|---------|-------------|
| `domain/models/monthly_summary.dart` | Modele domaine MonthlySummary (Freezed) |
| `features/dashboard/application/dashboard_state.dart` | State Freezed du dashboard |
| `features/dashboard/application/dashboard_notifier.dart` | Notifier orchestre le chargement |
| `features/dashboard/presentation/widgets/hero_account_section.dart` | Section hero compte |
| `features/dashboard/presentation/widgets/monthly_summary_section.dart` | Section resume mensuel |
| `features/dashboard/presentation/widgets/mini_cards_section.dart` | Section mini-cards modules |
| `features/dashboard/presentation/widgets/recent_transactions_section.dart` | Section dernieres operations |

## Fichiers a modifier

| Fichier | Modification |
|---------|-------------|
| `data/remote/dtos/transaction_dtos.dart` | Ajouter `MonthlySummaryResponse` DTO |
| `data/remote/data_sources/transaction_remote_data_source.dart` | Ajouter `getMonthlySummary()` |
| `data/local/daos/transaction_dao.dart` | Ajouter query agregation mensuelle locale |
| `features/transactions/data/transaction_repository_remote.dart` | Ajouter mapping summary |
| `features/transactions/data/transaction_repository_local.dart` | Ajouter mapping summary local |
| `domain/repositories/transaction_repository.dart` | Ajouter methode `getMonthlySummary()` |
| `data/data_mode_provider.dart` | Ajouter `monthlySummaryProvider` |
| `features/dashboard/presentation/dashboard_screen.dart` | Refonte complete (ConsumerWidget) |

## Sequence de build

1. **Modeles** : Creer `MonthlySummary`, `DashboardState`, `MonthlySummaryResponse` DTO
2. **Code gen** : `dart run build_runner build --delete-conflicting-outputs`
3. **Data layer** : Ajouter `getMonthlySummary()` dans data source, repository, DAO, provider
4. **Notifier** : Creer `DashboardNotifier` avec logique de chargement et calculs
5. **Widgets** : Creer les 4 widgets de section
6. **Screen** : Refondre `DashboardScreen` pour assembler les sections avec `RefreshIndicator`
7. **Tests** : Widget tests + unit tests notifier

## Commandes

```bash
# Code generation apres creation des modeles Freezed
cd flutter && dart run build_runner build --delete-conflicting-outputs

# Lancer les tests
cd flutter && flutter test

# Lancer l'app en dev
cd flutter && flutter run
```

## Patterns a suivre

- **Widget type** : `ConsumerWidget` pour les sections qui lisent des providers
- **State** : `DashboardState` Freezed avec `copyWith()`
- **Loading** : `Shimmer` pour skeletons (package shimmer ^3.0.0)
- **Navigation** : `context.push('/transactions')`, `context.push('/subscriptions')`, `context.push('/debts')`
- **Formatage** : `AmountFormatter.format()` + `RelativeDateFormatter.format()`
- **Design tokens** : `AppSpacing`, `AppColors`, `AppTypography`, `AppRadius`
- **Theme** : `Theme.of(context)` + `AppThemeExtension`
