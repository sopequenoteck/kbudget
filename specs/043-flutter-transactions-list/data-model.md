# Data Model: Écran Transactions Liste (Flutter)

**Feature**: `043-flutter-transactions-list` | **Date**: 2026-02-22

## Entités existantes

### Transaction (Freezed) — pas de modification

```
Transaction
├── id: String (required, UUID)
├── montant: double (required, toujours positif)
├── libelle: String (required)
├── type: TransactionType (required) — depense | recette | ajustement
├── date: DateTime (required)
├── note: String? (optional)
├── transferId: String? (optional, UUID)
├── categoryId: String? (optional, FK → Category)
├── accountId: String? (optional, FK → Account)
└── updatedAt: DateTime? (optional)
```

**Fichier**: `flutter/lib/src/domain/models/transaction.dart`

### Category (Freezed) — pas de modification

```
Category
├── id: String (required, UUID)
├── nom: String (required)
├── icone: String (required, emoji)
├── couleur: String (required, hex color)
├── isSystem: bool (default: false)
└── updatedAt: DateTime? (optional)
```

**Fichier**: `flutter/lib/src/domain/models/category.dart`

### MonthlySummary (Freezed) — MODIFICATION : `solde` → `bilan`

```
MonthlySummary
├── month: int (required, 1-12)
├── year: int (required)
├── totalRecettes: double (required, somme des transactions type=recette)
├── totalDepenses: double (required, somme des transactions type=depense)
├── bilan: double (required, = totalRecettes - totalDepenses)  ← RENOMMÉ
└── currency: Currency (required)
```

**Fichier**: `flutter/lib/src/domain/models/monthly_summary.dart`

**Note** : Les transactions de type `ajustement` sont **exclues** des trois métriques.

## Nouveau modèle : TransactionListState (Freezed)

```
TransactionListState
├── allMonthTransactions: List<Transaction> (default: [])
├── filteredTransactions: List<Transaction> (default: [])
├── activeFilter: TransactionTypeFilter (default: all)
├── selectedMonth: int (required, 1-12)
├── selectedYear: int (required)
├── summary: MonthlySummary? (optional, null pendant le chargement)
├── isLoading: bool (default: true)
└── error: String? (optional)
```

**Fichier**: `flutter/lib/src/features/transactions/application/transaction_list_state.dart`

## Nouveau enum : TransactionTypeFilter

```
TransactionTypeFilter { all, depense, recette }
```

**Fichier**: `flutter/lib/src/features/transactions/application/transaction_list_state.dart` (dans le même fichier)

## Relations

```
Transaction ──── categoryId ────> Category (0..1)
Transaction ──── accountId ─────> Account (0..1)
MonthlySummary ← calculé depuis ─ Transaction[] (agrégation par mois/année, ajustements exclus)

TransactionListState
  ├── allMonthTransactions ──> Transaction[] (chargé via getByMonth)
  ├── filteredTransactions ──> Transaction[] (sous-ensemble filtré par type)
  └── summary ──────────────> MonthlySummary (chargé via getMonthlySummary)
```

## Modifications interface repository

### TransactionRepository — AJOUT méthode

```diff
abstract class TransactionRepository {
  Future<List<Transaction>> getAll();
+ Future<List<Transaction>> getByMonth(int month, int year);
  Stream<List<Transaction>> watchAll();
  Future<Transaction> getById(String id);
  Future<Transaction> create(Transaction transaction);
  Future<Transaction> update(Transaction transaction);
  Future<void> delete(String id);
  Future<List<MonthlySummary>> getMonthlySummary(int month, int year);
}
```

### TransactionDao — AJOUT requête

```dart
Future<List<Transaction>> getTransactionsByMonth(int month, int year)
// SELECT * FROM transactions WHERE date >= startOfMonth AND date < startOfNextMonth
// ORDER BY date DESC
```

### TransactionRemoteDataSource — AJOUT endpoint

```dart
Future<List<TransactionResponse>> getByMonth(int month, int year)
// GET /transactions?month=M&year=Y
```

### getMonthlySummary — MODIFICATION SQL

```diff
  'SELECT type, SUM(montant) as total FROM transactions '
- 'WHERE date >= ? AND date < ? '
+ 'WHERE date >= ? AND date < ? AND type != ? '
  'GROUP BY type',
  variables: [
    Variable.withDateTime(startDate),
    Variable.withDateTime(endDate),
+   Variable.withString('ajustement'),
  ],
```

## Providers

### Existants (réutilisés)

| Provider | Type | Usage |
|----------|------|-------|
| `transactionRepositoryProvider` | `Provider<TransactionRepository>` | Accès repository (strategy local/remote) |
| `categoryNotifierProvider` | `NotifierProvider<CategoryNotifier, ListState<Category>>` | Catégories pour affichage |
| `monthlySummaryProvider` | `FutureProvider.family` | Résumé mensuel |

### Nouveau

| Provider | Type | Usage |
|----------|------|-------|
| `transactionListNotifierProvider` | `NotifierProvider<TransactionListNotifier, TransactionListState>` | State de l'écran liste |

## Aucune migration Drift

Le schéma de la base Drift ne change pas (`schemaVersion` reste à 1). Les ajouts sont des **requêtes** sur les tables existantes, pas des modifications de structure.
