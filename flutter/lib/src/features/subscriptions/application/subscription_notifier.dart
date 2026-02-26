import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/repositories/subscription_repository.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_list_state.dart';

final subscriptionNotifierProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionListState>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends Notifier<SubscriptionListState> {
  static const _pageSize = 20;
  List<Subscription> _allItems = [];

  @override
  SubscriptionListState build() => const SubscriptionListState();

  SubscriptionRepository get _repo =>
      ref.read(subscriptionRepositoryProvider);

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _allItems = await _repo.getAll();
      _allItems.sort((a, b) => a.nom.compareTo(b.nom));
      _refreshPage(resetPage: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les abonnements: $e',
      );
    }
  }

  Future<void> refresh() async => loadItems();

  void setFilter(SubscriptionStatusFilter filter) {
    state = state.copyWith(activeFilter: filter);
    _refreshPage(resetPage: true);
  }

  void loadMore() {
    if (!state.hasMore || state.isLoading) return;
    final filtered = _applyFilter(_allItems, state.activeFilter);
    final nextPage = state.currentPage + 1;
    final end = (nextPage + 1) * _pageSize;
    final page = filtered.take(end).toList();
    state = state.copyWith(
      items: page,
      currentPage: nextPage,
      hasMore: end < filtered.length,
    );
  }

  Future<void> create(Subscription item) async {
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

  Future<void> update(Subscription item) async {
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

  Future<void> toggleActif(String id) async {
    final item = _allItems.where((e) => e.id == id).firstOrNull;
    if (item == null) return;
    await update(item.copyWith(actif: !item.actif));
  }

  List<Subscription> _applyFilter(
    List<Subscription> items,
    SubscriptionStatusFilter filter,
  ) {
    return switch (filter) {
      SubscriptionStatusFilter.all => items,
      SubscriptionStatusFilter.actif =>
        items.where((s) => s.actif).toList(),
      SubscriptionStatusFilter.inactif =>
        items.where((s) => !s.actif).toList(),
    };
  }

  Map<Currency, double> _computeMonthlyTotals(List<Subscription> allItems) {
    final totals = <Currency, double>{};
    for (final sub in allItems.where((s) => s.actif)) {
      final monthly = switch (sub.frequence) {
        Frequency.mensuel => sub.montant,
        Frequency.annuel => sub.montant / 12,
      };
      totals[sub.currency] = (totals[sub.currency] ?? 0) + monthly;
    }
    return totals;
  }

  void _refreshPage({bool resetPage = false}) {
    final filtered = _applyFilter(_allItems, state.activeFilter);
    final page = resetPage ? 0 : state.currentPage;
    final end = (page + 1) * _pageSize;
    final items = filtered.take(end).toList();
    state = state.copyWith(
      items: items,
      isLoading: false,
      currentPage: page,
      hasMore: end < filtered.length,
      monthlyTotals: _computeMonthlyTotals(_allItems),
    );
  }
}
