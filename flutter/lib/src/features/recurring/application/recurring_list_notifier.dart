import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/dtos/recurring_transaction_create_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/domain/repositories/recurring_transaction_repository.dart';
import 'package:k_budget/src/features/recurring/data/recurring_transaction_repository_remote.dart';

final recurringListNotifierProvider =
    NotifierProvider<RecurringListNotifier, ListState<RecurringTransaction>>(
  RecurringListNotifier.new,
);

class RecurringListNotifier
    extends Notifier<ListState<RecurringTransaction>> {
  @override
  ListState<RecurringTransaction> build() =>
      const ListState<RecurringTransaction>();

  Future<RecurringTransactionRepository> get _repo async =>
      ref.read(recurringTransactionRepositoryProvider.future);

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = await _repo;
      final items = await repo.listActive();
      final sorted = _sortItems(items);
      state = state.copyWith(items: sorted, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les récurrences: $e',
      );
    }
  }

  Future<void> create(RecurringTransactionCreateRequest req) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = await ref.read(recurringTransactionRepositoryProvider.future);
      await repo.create(req);
      await _refreshList();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> validate(String id) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final repo = await _repo;
      await repo.validate(id);
      await _refreshList();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: e.toString(),
      );
    }
  }

  Future<void> skip(String id) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final repo = await _repo;
      await repo.skip(id);
      await _refreshList();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: e.toString(),
      );
    }
  }

  Future<void> validateAll(List<String> ids) async {
    if (ids.isEmpty) return;
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, '__all__'},
      error: null,
    );
    try {
      for (final id in ids) {
        await validate(id);
      }
    } on Exception {
      // ignore: individual validate() handles its own error state
    } finally {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove('__all__'),
      );
    }
  }

  Future<void> deactivate(String id) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final repo = await _repo;
      await repo.deactivate(id);
      await _refreshList();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: e.toString(),
      );
    }
  }

  Future<void> _refreshList() async {
    final repo = await _repo;
    final items = await repo.listActive();
    final sorted = _sortItems(items);
    state = state.copyWith(items: sorted, isLoading: false);
  }

  List<RecurringTransaction> _sortItems(List<RecurringTransaction> items) {
    final overdue =
        items.where((i) => i.status == RecurringStatus.overdue).toList();
    final today =
        items.where((i) => i.status == RecurringStatus.today).toList();
    final upcoming =
        items.where((i) => i.status == RecurringStatus.upcoming).toList();

    int byDate(RecurringTransaction a, RecurringTransaction b) =>
        a.nextOccurrence.compareTo(b.nextOccurrence);

    overdue.sort(byDate);
    today.sort(byDate);
    upcoming.sort(byDate);

    return [...overdue, ...today, ...upcoming];
  }
}
