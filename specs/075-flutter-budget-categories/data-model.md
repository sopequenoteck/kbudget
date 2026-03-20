# Data Model — 075-flutter-budget-categories

## Domain Models (Freezed)

### Budget

```dart
@freezed
class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String categoryId,
    required double montant,
    required Frequency frequence,
    @Default(Currency.eur) Currency currency,
    @Default(80) int seuilNotification,
    @Default(true) bool actif,
    // Denormalized category fields (from API response)
    String? categoryNom,
    String? categoryIcone,
    String? categoryCouleur,
    // Computed by backend for current month
    double? spent,
    DateTime? updatedAt,
  }) = _Budget;
}
```

**Validation**: `montant > 0`, `seuilNotification` in [0, 100], `categoryId` non-null.
**Uniqueness**: 1 budget par catégorie par user (enforced backend).

### BudgetOverview

```dart
@freezed
class BudgetOverview with _$BudgetOverview {
  const factory BudgetOverview({
    required String month,
    required double totalBudget,
    required double totalSpent,
    required double percentage,
    required String currency,
    required List<BudgetOverviewItem> items,
  }) = _BudgetOverview;
}
```

### BudgetOverviewItem

```dart
@freezed
class BudgetOverviewItem with _$BudgetOverviewItem {
  const factory BudgetOverviewItem({
    required String budgetId,
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantBudget,
    required double montantBudgetNormalise,
    required String currency,
    required double montantDepense,
    required double percentage,
    required String frequence,
  }) = _BudgetOverviewItem;
}
```

### BudgetHistory

```dart
@freezed
class BudgetHistory with _$BudgetHistory {
  const factory BudgetHistory({
    required String month,
    required double totalBudget,
    required double totalSpent,
    required double percentage,
    required String currency,
    required List<BudgetHistoryItem> items,
  }) = _BudgetHistory;
}
```

### BudgetHistoryItem

```dart
@freezed
class BudgetHistoryItem with _$BudgetHistoryItem {
  const factory BudgetHistoryItem({
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantBudget,
    required String currency,
    double? tauxChange,
    required double montantDepense,
    required double percentage,
    DateTime? createdAt,
  }) = _BudgetHistoryItem;
}
```

## Drift Tables

### Budgets (SQLite)

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | TEXT | No | — | PK |
| category_id | TEXT | No | — | FK categories |
| montant | REAL | No | — | Budget amount |
| frequence | TEXT | No | — | Enum as string |
| currency | TEXT | No | 'eur' | Enum as string |
| seuil_notification | INTEGER | No | 80 | 0-100 |
| actif | INTEGER | No | 1 | Boolean |
| updated_at | INTEGER | Yes | — | DateTime |

### BudgetSnapshots (SQLite)

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | TEXT | No | — | PK (auto-generated) |
| category_id | TEXT | No | — | FK categories |
| montant_budget | REAL | No | — | Normalized monthly |
| currency | TEXT | No | — | Enum as string |
| taux_change | REAL | Yes | — | Exchange rate |
| montant_depense | REAL | No | — | Spent amount |
| mois | TEXT | No | — | 'YYYY-MM' |
| created_at | INTEGER | No | — | DateTime |

## DTOs (Remote — Freezed + json_serializable)

### BudgetRequest

```dart
@freezed
class BudgetRequest with _$BudgetRequest {
  const factory BudgetRequest({
    required String categoryId,
    required double montant,
    required String frequence,
    String? currency,
    int? seuilNotification,
    bool? actif,
  }) = _BudgetRequest;
}
```

### BudgetResponse

```dart
@freezed
class BudgetResponse with _$BudgetResponse {
  const factory BudgetResponse({
    required String id,
    required double montant,
    required String currency,
    required String frequence,
    required int seuilNotification,
    required bool actif,
    @JsonKey(name: 'category') required Map<String, dynamic> category,
    double? spent,
    String? updatedAt,
  }) = _BudgetResponse;
}
```

### BudgetOverviewResponse / BudgetHistoryResponse

Mêmes structures que les domain models, avec `fromJson` factory.

## State

### BudgetListState (Freezed)

```dart
@freezed
class BudgetListState with _$BudgetListState {
  const factory BudgetListState({
    @Default([]) List<Budget> items,
    @Default(false) bool isLoading,
    String? error,
    @Default(0) int currentPage,
    @Default(true) bool hasMore,
    @Default({}) Set<String> mutatingIds,
    // Budget-specific
    BudgetOverview? overview,
    BudgetHistory? history,
    int? selectedMonth,
    int? selectedYear,
  }) = _BudgetListState;
}
```

## Relationships

```
Budget ──→ Category (via categoryId, denormalized fields)
BudgetOverview ──→ List<BudgetOverviewItem>
BudgetHistory ──→ List<BudgetHistoryItem>
BudgetSnapshot ──→ Category (via categoryId)
```

## State Transitions

- **Budget lifecycle**: Created (actif=true) → Updated → Deactivated (actif=false) → Deleted
- **BudgetSnapshot**: Created lazily by backend on first history request for a past month. Immutable once created.
