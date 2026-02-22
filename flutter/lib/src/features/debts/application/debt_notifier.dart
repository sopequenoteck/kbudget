import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/repositories/debt_repository.dart';

final debtNotifierProvider =
    NotifierProvider<DebtNotifier, ListState<Debt>>(
  DebtNotifier.new,
);

class DebtNotifier extends Notifier<ListState<Debt>> {
  static const _pageSize = 20;
  List<Debt> _allItems = [];

  @override
  ListState<Debt> build() => const ListState<Debt>();

  DebtRepository get _repo => ref.read(debtRepositoryProvider);

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _allItems = await _repo.getAll();
      _allItems.sort((a, b) => b.date.compareTo(a.date));
      _refreshPage(resetPage: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les dettes: $e',
      );
    }
  }

  Future<void> refresh() async => loadItems();

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

  Future<void> create(Debt item) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repo.create(item);
      _allItems.add(created);
      _allItems.sort((a, b) => b.date.compareTo(a.date));
      _refreshPage();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création: $e',
      );
    }
  }

  Future<void> update(Debt item) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, item.id},
      error: null,
    );
    try {
      final updated = await _repo.update(item);
      final index = _allItems.indexWhere((e) => e.id == item.id);
      if (index != -1) _allItems[index] = updated;
      _allItems.sort((a, b) => b.date.compareTo(a.date));
      _refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(item.id),
      );
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
    } on Exception catch (e) {
      _allItems.insert(index, saved);
      _allItems.sort((a, b) => b.date.compareTo(a.date));
      _refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur lors de la suppression: $e',
      );
    }
  }

  Future<void> markAsRepaid(String id) async {
    final item = _allItems.where((e) => e.id == id).firstOrNull;
    if (item == null) return;
    await update(item.copyWith(rembourse: true));
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
