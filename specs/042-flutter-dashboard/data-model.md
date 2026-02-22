# Data Model: Flutter Dashboard Complet

**Date**: 2026-02-22 | **Feature**: 042-flutter-dashboard

## Nouveaux modeles

### MonthlySummary (domain model)

```dart
@freezed
class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    required int month,
    required int year,
    required double totalRecettes,
    required double totalDepenses,
    required double solde,
    required Currency currency,
  }) = _MonthlySummary;
}
```

**Fichier**: `flutter/lib/src/domain/models/monthly_summary.dart`
**Relations**: Aucune FK — modele calcule/agrege.
**Validation**: month ∈ [1,12], year > 0, currency ∈ Currency enum.

### MonthlySummaryResponse (DTO remote)

```dart
@freezed
class MonthlySummaryResponse with _$MonthlySummaryResponse {
  const factory MonthlySummaryResponse({
    required int month,
    required int year,
    required double totalRecettes,
    required double totalDepenses,
    required double solde,
    required String currency,
  }) = _MonthlySummaryResponse;

  factory MonthlySummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryResponseFromJson(json);
}
```

**Fichier**: `flutter/lib/src/data/remote/dtos/transaction_dtos.dart` (ajoute au fichier existant)

### DashboardState (state model)

```dart
@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState({
    // Comptes
    @Default([]) List<Account> accounts,
    Account? defaultAccount,

    // Resume mensuel
    @Default([]) List<MonthlySummary> monthlySummaries,
    @Default(0) int selectedMonth,   // 1-12
    @Default(0) int selectedYear,

    // Mini-cards
    @Default(0.0) double subscriptionMonthlyTotal,
    @Default(0) int activeSubscriptionCount,
    @Default(0.0) double debtNetBalance,
    @Default(0) int activeDebtCount,

    // Dernieres transactions
    @Default([]) List<Transaction> recentTransactions,

    // User
    String? userName,

    // Loading / Error
    @Default(true) bool isLoading,
    String? error,
  }) = _DashboardState;
}
```

**Fichier**: `flutter/lib/src/features/dashboard/application/dashboard_state.dart`

## Entites existantes utilisees (lecture seule)

| Entite | Fichier | Usage dashboard |
|--------|---------|-----------------|
| `Account` | `domain/models/account.dart` | Hero + liste comptes (filtrer `actif == true`) |
| `Transaction` | `domain/models/transaction.dart` | 5 dernieres transactions |
| `Subscription` | `domain/models/subscription.dart` | Calcul montant mensuel normalise |
| `Debt` | `domain/models/debt.dart` | Calcul solde net |
| `Category` | `domain/models/category.dart` | Emoji + nom dans les transactions recentes |
| `Currency` | `domain/enums/currency.dart` | Symbol devise pour formatage montants |

## Enums existants utilises

| Enum | Fichier | Usage |
|------|---------|-------|
| `Frequency` | `domain/enums/frequency.dart` | Normalisation abonnements (mensuel/annuel) |
| `DebtType` | `domain/enums/debt_type.dart` | Calcul solde net (emprunt/pret) |
| `TransactionType` | `domain/enums/transaction_type.dart` | Couleur montant (depense/recette) |
| `Currency` | `domain/enums/currency.dart` | Formatage montants multi-devises |
| `DataMode` | `domain/enums/data_mode.dart` | Switch local/server pour summary provider |

## Relations de donnees

```
DashboardNotifier
  ├── watches → accountNotifierProvider (ListState<Account>)
  ├── watches → transactionNotifierProvider (ListState<Transaction>)
  ├── watches → subscriptionNotifierProvider (ListState<Subscription>)
  ├── watches → debtNotifierProvider (ListState<Debt>)
  ├── watches → categoryNotifierProvider (ListState<Category>)
  ├── calls  → monthlySummaryProvider(month, year) → List<MonthlySummary>
  └── reads  → currentUserNameProvider → String?
```

## Calculs derives

### Montant mensuel abonnements
```
subscriptionMonthlyTotal = SUM(
  for s in subscriptions where s.actif:
    s.frequence == mensuel ? s.montant : s.montant / 12
)
```

### Solde net dettes
```
debtNetBalance = SUM(d.montant for d where d.sens == pret AND !d.rembourse)
              - SUM(d.montant for d where d.sens == emprunt AND !d.rembourse)
activeDebtCount = COUNT(d where !d.rembourse)
```

### Barre de progression (ratio)
```
maxRef = max(totalRecettes, totalDepenses)
ratioRecettes = maxRef > 0 ? totalRecettes / maxRef : 0
ratioDepenses = maxRef > 0 ? totalDepenses / maxRef : 0
```
