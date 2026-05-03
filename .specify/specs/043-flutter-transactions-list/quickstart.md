# Quickstart: Écran Transactions Liste (Flutter)

**Feature**: `043-flutter-transactions-list` | **Date**: 2026-02-22

## Prérequis

- Flutter >= 3.27 installé
- Branche `043-flutter-transactions-list` checkoutée

## Lancer le projet

```bash
cd flutter
flutter pub get
flutter run
```

## Fichiers à modifier

| Fichier | Action |
|---------|--------|
| `flutter/lib/src/domain/repositories/transaction_repository.dart` | Ajouter `getByMonth(int month, int year)` |
| `flutter/lib/src/data/local/daos/transaction_dao.dart` | Ajouter `getTransactionsByMonth()` requête Drift |
| `flutter/lib/src/data/remote/data_sources/transaction_remote_data_source.dart` | Ajouter `getByMonth()` endpoint |
| `flutter/lib/src/features/transactions/data/transaction_repository_local.dart` | Implémenter `getByMonth()` |
| `flutter/lib/src/features/transactions/data/transaction_repository_remote.dart` | Implémenter `getByMonth()` |
| `flutter/lib/src/domain/models/monthly_summary.dart` | Renommer `solde` → `bilan` |
| `flutter/lib/src/data/remote/dtos/transaction_dtos.dart` | Adapter `MonthlySummaryResponse` (`@JsonKey(name: 'solde')` → `bilan`) |
| `flutter/lib/src/data/local/daos/transaction_dao.dart` | Exclure `ajustement` dans `getMonthlySummary()` |
| `flutter/lib/src/features/transactions/data/transaction_repository_local.dart` | `solde` → `bilan` dans mapper |
| `flutter/lib/src/features/transactions/data/transaction_repository_remote.dart` | `solde` → `bilan` dans mapper |
| `flutter/lib/src/features/dashboard/**` | Mettre à jour les accès `.solde` → `.bilan` |
| `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart` | Remplacer le stub par l'écran complet |

## Fichiers à créer

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/features/transactions/application/transaction_list_notifier.dart` | Notifier dédié pour la liste |
| `flutter/lib/src/features/transactions/application/transaction_list_state.dart` | State Freezed + enum `TransactionTypeFilter` |
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_summary_card.dart` | Widget résumé mensuel (recettes/dépenses/bilan + skeleton) |
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_day_group.dart` | Widget groupement par jour (en-tête + items) |
| `flutter/lib/src/utils/day_header_formatter.dart` | Helper format en-tête jour ("Aujourd'hui", "Hier", "Lundi 20 février") |

## Fichiers tests

| Fichier | Description |
|---------|-------------|
| `flutter/test/src/features/transactions/application/transaction_list_notifier_test.dart` | Tests unitaires du notifier |
| `flutter/test/src/features/transactions/presentation/transaction_list_screen_test.dart` | Widget tests de l'écran |
| `flutter/test/src/utils/day_header_formatter_test.dart` | Tests du formatter |

## Widgets existants réutilisés

| Widget | Import |
|--------|--------|
| `MonthSelector` | `package:k_budget/src/common_widgets/month_selector.dart` |
| `SegmentedFilter<T>` | `package:k_budget/src/common_widgets/segmented_filter.dart` |
| `ListItem` / `ListItem.skeleton()` | `package:k_budget/src/common_widgets/list_item.dart` |

## Utilitaires réutilisés

| Utilitaire | Usage |
|------------|-------|
| `AmountFormatter.format()` | Formatage montant avec devise et signe |
| `AmountFormatter.amountColor()` | Couleur sémantique (vert=recette, rouge=dépense) |
| `parseHexColor()` | Conversion couleur hex catégorie → Color |

## Régénération code

```bash
cd flutter
dart run build_runner build --delete-conflicting-outputs
```

Nécessaire après modification de `MonthlySummary`, `TransactionListState`, `MonthlySummaryResponse`.

## Vérification

```bash
cd flutter
flutter analyze
flutter test test/src/features/transactions/
flutter test test/src/utils/day_header_formatter_test.dart
```

## Architecture du screen

```
TransactionListScreen (ConsumerStatefulWidget)
│
├── initState() → WidgetsBinding.addPostFrameCallback → loadMonth(now)
│
├── build()
│   └── RefreshIndicator
│       └── CustomScrollView
│           ├── SliverToBoxAdapter: MonthSelector(onChanged → changeMonth)
│           ├── SliverToBoxAdapter: TransactionSummaryCard(summary, isLoading)
│           ├── SliverToBoxAdapter: SegmentedFilter<TransactionTypeFilter>(onChanged → setFilter)
│           │
│           ├── [si isLoading] SliverToBoxAdapter: Column(ListItem.skeleton() x 5)
│           ├── [si error] SliverToBoxAdapter: ErrorState(retry)
│           ├── [si vide] SliverToBoxAdapter: EmptyState(message)
│           └── [si données] SliverList.builder: TransactionDayGroup[] → ListItem[]
│
└── Interactions
    ├── MonthSelector.onChanged → notifier.changeMonth(month, year)
    ├── SegmentedFilter.onChanged → notifier.setFilter(filter)
    ├── ListItem.onPressed → context.push('/transactions/${id}').then(refresh)
    └── Pull-to-refresh → notifier.refresh()
```
