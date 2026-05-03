# Quickstart: Flutter Notifiers Riverpod CRUD

**Feature**: 041-flutter-riverpod-notifiers
**Date**: 2026-02-22

## Prerequis

- Flutter SDK >= 3.27 installe
- Dependances du projet installees (`cd flutter && flutter pub get`)
- Build runner operationnel (`dart run build_runner build`)

## Ordre d'implementation

```
1. ListState<T>              # Modele generique (aucune dependance)
2. TransactionNotifier        # Premier notifier (patron de reference)
3. TransactionNotifier tests  # Valider le pattern avant de le repliquer
4. AccountNotifier            # + setDefault()
5. CategoryNotifier           # + protection isSystem
6. SubscriptionNotifier       # + toggle actif
7. DebtNotifier               # + markAsRepaid
8. Tests restants (4 notifiers)
```

## Commandes cles

```bash
# Generer le code Freezed apres creation de ListState
cd flutter && dart run build_runner build --delete-conflicting-outputs

# Lancer les tests
cd flutter && flutter test

# Lancer un test specifique
cd flutter && flutter test test/src/features/transactions/application/transaction_notifier_test.dart

# Verifier le linting
cd flutter && flutter analyze
```

## Pattern de reference : TransactionNotifier

```dart
// flutter/lib/src/features/transactions/application/transaction_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/transaction.dart';

final transactionNotifierProvider =
    NotifierProvider<TransactionNotifier, ListState<Transaction>>(
  TransactionNotifier.new,
);

class TransactionNotifier extends Notifier<ListState<Transaction>> {
  static const _pageSize = 20;
  List<Transaction> _allItems = [];

  @override
  ListState<Transaction> build() {
    return const ListState<Transaction>();
  }

  TransactionRepository get _repo =>
      ref.read(transactionRepositoryProvider);

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _allItems = await _repo.getAll();
      _allItems.sort((a, b) => b.date.compareTo(a.date));
      final page = _allItems.take(_pageSize).toList();
      state = state.copyWith(
        items: page,
        isLoading: false,
        currentPage: 0,
        hasMore: _allItems.length > _pageSize,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les transactions: $e',
      );
    }
  }

  void loadMore() {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.currentPage + 1;
    final start = 0;
    final end = (nextPage + 1) * _pageSize;
    final page = _allItems.take(end).toList();
    state = state.copyWith(
      items: page,
      currentPage: nextPage,
      hasMore: end < _allItems.length,
    );
  }

  Future<void> create(Transaction item) async {
    state = state.copyWith(error: null);
    try {
      final created = await _repo.create(item);
      _allItems.insert(0, created);
      _allItems.sort((a, b) => b.date.compareTo(a.date));
      _refreshPage();
    } on Exception catch (e) {
      state = state.copyWith(error: 'Erreur lors de la creation: $e');
    }
  }

  // ... update, delete (optimiste), refresh
}
```

## Pattern de test

```dart
// Meme pattern que auth_notifier_test.dart
late MockTransactionRepository mockRepo;
late ProviderContainer container;

setUp(() {
  mockRepo = MockTransactionRepository();
  container = ProviderContainer(overrides: [
    transactionRepositoryProvider.overrideWithValue(mockRepo),
  ]);
});

test('should_showItems_when_loadSucceeds', () async {
  when(mockRepo.getAll()).thenAnswer((_) async => [mockTransaction]);
  await container.read(transactionNotifierProvider.notifier).loadItems();
  final state = container.read(transactionNotifierProvider);
  expect(state.items, [mockTransaction]);
  expect(state.isLoading, false);
});
```

## Checklist de validation par notifier

- [ ] `loadItems()` : charge et trie les donnees, gere loading/error
- [ ] `loadMore()` : pagination client-side par pages de 20
- [ ] `create()` : ajoute a la liste apres confirmation, trie
- [ ] `update()` : remplace dans la liste apres confirmation
- [ ] `delete()` : optimiste (retrait immediat, rollback si echec)
- [ ] `refresh()` : recharge depuis le repository
- [ ] `mutatingIds` : set/clear autour de chaque mutation
- [ ] Action specifique (si applicable)
- [ ] Tests unitaires avec mocks
