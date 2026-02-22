import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/repositories/category_repository.dart';

final categoryNotifierProvider =
    NotifierProvider<CategoryNotifier, ListState<Category>>(
  CategoryNotifier.new,
);

class CategoryNotifier extends Notifier<ListState<Category>> {
  static const _pageSize = 20;
  List<Category> _allItems = [];

  @override
  ListState<Category> build() => const ListState<Category>();

  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _allItems = await _repo.getAll();
      _allItems.sort((a, b) => a.nom.compareTo(b.nom));
      _refreshPage(resetPage: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les catégories: $e',
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

  Future<void> create(Category item) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repo.create(item);
      _allItems.add(created);
      _allItems.sort((a, b) => a.nom.compareTo(b.nom));
      _refreshPage();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création: $e',
      );
    }
  }

  Future<void> update(Category item) async {
    final existing = _allItems.where((e) => e.id == item.id).firstOrNull;
    if (existing != null && existing.isSystem) {
      state = state.copyWith(
        error: 'Les catégories système ne peuvent pas être modifiées',
      );
      return;
    }
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, item.id},
      error: null,
    );
    try {
      final updated = await _repo.update(item);
      final index = _allItems.indexWhere((e) => e.id == item.id);
      if (index != -1) _allItems[index] = updated;
      _allItems.sort((a, b) => a.nom.compareTo(b.nom));
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

    if (saved.isSystem) {
      state = state.copyWith(
        error: 'Les catégories système ne peuvent pas être supprimées',
      );
      return;
    }

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
      _allItems.sort((a, b) => a.nom.compareTo(b.nom));
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
