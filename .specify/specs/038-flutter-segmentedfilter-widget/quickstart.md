# Quickstart: SegmentedFilter

**Feature**: 038-flutter-segmentedfilter-widget

## Usage basique

```dart
import 'package:k_budget/src/common_widgets/segmented_filter.dart';

// Avec un enum
enum TransactionType { all, depense, recette }

SegmentedFilter<TransactionType>(
  items: const [
    SegmentedFilterItem(value: TransactionType.all, label: 'Tous'),
    SegmentedFilterItem(value: TransactionType.depense, label: 'Dépenses'),
    SegmentedFilterItem(value: TransactionType.recette, label: 'Recettes'),
  ],
  selectedValue: currentFilter,
  onChanged: (value) => setState(() => currentFilter = value),
)
```

## Usage avec Riverpod

```dart
// Dans un écran avec signal/provider
final typeFilter = useState(TransactionType.all);

SegmentedFilter<TransactionType>(
  items: const [
    SegmentedFilterItem(value: TransactionType.all, label: 'Tous'),
    SegmentedFilterItem(value: TransactionType.depense, label: 'Dépenses'),
    SegmentedFilterItem(value: TransactionType.recette, label: 'Recettes'),
  ],
  selectedValue: typeFilter.value,
  onChanged: (value) => typeFilter.value = value,
)
```

## Cas d'usage prévus

| Écran | Segments | Type |
|-------|----------|------|
| Transactions | Tous / Dépenses / Recettes | `TransactionType` ou `String` |
| Abonnements | Tous / Actifs / Inactifs | `StatusFilter` ou `String` |
| Dettes | Tous / En cours / Remboursé | `DebtStatusFilter` ou `String` |

## Lancer les tests

```bash
cd flutter && flutter test test/src/common_widgets/segmented_filter_test.dart
```
