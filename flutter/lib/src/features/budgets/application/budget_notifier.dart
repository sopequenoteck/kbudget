import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/repositories/budget_repository.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';

final budgetNotifierProvider =
    NotifierProvider<BudgetNotifier, BudgetListState>(
  BudgetNotifier.new,
);

class BudgetNotifier extends Notifier<BudgetListState> {
  static const _pageSize = 20;
  List<Budget> _allItems = [];

  @override
  BudgetListState build() => const BudgetListState();

  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  Future<void> loadItems({bool includeInactive = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _allItems = await _repo.getAll(includeInactive: includeInactive);
      _allItems.sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
      _refreshPage(resetPage: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les budgets: $e',
      );
    }
  }

  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final overview = await _repo.getOverview();
      state = state.copyWith(overview: overview, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger l\'aperçu: $e',
      );
    }
  }

  Future<void> loadHistory(String month) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _repo.getHistory(month);
      state = state.copyWith(history: history, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger l\'historique: $e',
      );
    }
  }

  Future<void> refresh() async {
    await loadItems();
    await loadOverview();
  }

  void loadMore() {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.currentPage + 1;
    final end = (nextPage + 1) * _pageSize;
    final page = _allItems.take(end).toList();
    state = state.copyWith(
      items: page,
      currentPage: nextPage,
      hasMore: end < _allItems.length,
    );
  }

  Future<void> create(Budget item) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repo.create(item);
      _allItems.add(created);
      _refreshPage();
      await loadOverview();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création: $e',
      );
    }
  }

  Future<void> update(Budget item) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, item.id},
      error: null,
    );
    try {
      final updated = await _repo.update(item);
      final index = _allItems.indexWhere((e) => e.id == item.id);
      if (index != -1) _allItems[index] = updated;
      _refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(item.id),
      );
      await loadOverview();
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(item.id),
        error: 'Erreur lors de la modification: $e',
      );
    }
  }

  Future<void> delete(String id) async {
    final index = _allItems.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final saved = _allItems[index];

    _allItems.removeAt(index);
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    _refreshPage();

    try {
      await _repo.delete(id);
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
      await loadOverview();
    } on Exception catch (e) {
      _allItems.insert(index, saved);
      _refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur lors de la suppression: $e',
      );
    }
  }

  void _refreshPage({bool resetPage = false}) {
    final page = resetPage ? 0 : state.currentPage;
    final end = (page + 1) * _pageSize;
    final items = _allItems.take(end).toList();
    state = state.copyWith(
      items: items,
      isLoading: false,
      currentPage: page,
      hasMore: end < _allItems.length,
    );
  }
}
