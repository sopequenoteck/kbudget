// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/repositories/budget_repository.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';

final budgetNotifierProvider =
    NotifierProvider<BudgetNotifier, BudgetListState>(
  BudgetNotifier.new,
);

class BudgetNotifier extends Notifier<BudgetListState>
    with SessionGuard {
  static const _pageSize = 20;
  List<Budget> _allItems = [];

  @override
  BudgetListState build() {
    // L'etat appartient a la session : reconstruit a chaque connexion et
    // deconnexion, sinon B heriterait des donnees de A (KKS-546). Le notifier
    // survit a la reconstruction : le cache local doit etre vide avec l'etat.
    watchSession(ref);
    _allItems = [];
    return const BudgetListState();
  }

  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  Future<void> loadItems({bool includeInactive = false}) async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getAll(includeInactive: includeInactive);
      if (isStale(token)) {
        return;
      }
      _allItems = items;
      _allItems.sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
      _refreshPage(resetPage: true);
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).commonFeedbackLoadError,
      );
    }
  }

  Future<void> loadOverview() async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final overview = await _repo.getOverview();
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(overview: overview, isLoading: false);
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).commonFeedbackLoadError,
      );
    }
  }

  Future<void> loadHistory(String month) async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _repo.getHistory(month);
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(history: history, isLoading: false);
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).commonFeedbackLoadError,
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
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repo.create(item);
      if (isStale(token)) {
        return;
      }
      _allItems.add(created);
      _refreshPage();
      await loadOverview();
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).commonFeedbackSaveError,
      );
    }
  }

  Future<void> update(Budget item) async {
    final token = session;
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, item.id},
      error: null,
    );
    try {
      final updated = await _repo.update(item);
      if (isStale(token)) {
        return;
      }
      final index = _allItems.indexWhere((e) => e.id == item.id);
      if (index != -1) _allItems[index] = updated;
      _refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(item.id),
      );
      await loadOverview();
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(item.id),
        error: ref.read(appLocalizationsProvider).commonFeedbackSaveError,
      );
    }
  }

  Future<void> delete(String id) async {
    final index = _allItems.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final saved = _allItems[index];
    final token = session;

    _allItems.removeAt(index);
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    _refreshPage();

    try {
      await _repo.delete(id);
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
      await loadOverview();
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      _allItems.insert(index, saved);
      _refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: ref.read(appLocalizationsProvider).commonFeedbackDeleteError,
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
