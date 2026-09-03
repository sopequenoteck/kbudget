// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/debt_payment.dart';
import 'package:k_budget/src/domain/repositories/debt_repository.dart';
import 'package:k_budget/src/features/debts/application/debt_list_state.dart';

final debtNotifierProvider =
    NotifierProvider<DebtNotifier, DebtListState>(
  DebtNotifier.new,
);

class DebtNotifier extends Notifier<DebtListState> {
  static const _pageSize = 20;
  List<Debt> _allItems = [];

  @override
  DebtListState build() => const DebtListState();

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

  void setFilter(DebtStatusFilter filter) {
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

  Future<bool> repay(String debtId, String accountId, double? amount) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, debtId},
      error: null,
    );
    try {
      final updated = await _repo.repay(debtId, accountId, amount);
      final index = _allItems.indexWhere((e) => e.id == debtId);
      if (index != -1) _allItems[index] = updated;
      _allItems.sort((a, b) => b.date.compareTo(a.date));
      _refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(debtId),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(debtId),
        error: 'Erreur lors du remboursement: $e',
      );
      return false;
    }
  }

  Future<bool> snooze(
      String debtId, String reminderDate, String reminderTime) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, debtId},
      error: null,
    );
    try {
      final updated = await _repo.snooze(debtId, reminderDate, reminderTime);
      final index = _allItems.indexWhere((e) => e.id == debtId);
      if (index != -1) _allItems[index] = updated;
      _refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(debtId),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(debtId),
        error: 'Erreur lors du report: $e',
      );
      return false;
    }
  }

  Debt? getDebtById(String id) {
    final index = _allItems.indexWhere((e) => e.id == id);
    return index != -1 ? _allItems[index] : null;
  }

  List<Debt> _applyFilter(List<Debt> items, DebtStatusFilter filter) {
    return switch (filter) {
      DebtStatusFilter.all => items,
      DebtStatusFilter.enCours => items.where((d) => !d.rembourse).toList(),
      DebtStatusFilter.rembourse => items.where((d) => d.rembourse).toList(),
    };
  }

  Map<Currency, DebtCurrencySummary> _computeSummary(List<Debt> allItems) {
    final result = <Currency, ({double totalEmprunts, double totalPrets})>{};
    for (final debt in allItems.where((d) => !d.rembourse)) {
      final prev = result[debt.currency] ??
          (totalEmprunts: 0.0, totalPrets: 0.0);
      if (debt.sens == DebtType.emprunt) {
        result[debt.currency] = (
          totalEmprunts: prev.totalEmprunts + (debt.remainingAmount ?? debt.montant),
          totalPrets: prev.totalPrets,
        );
      } else {
        result[debt.currency] = (
          totalEmprunts: prev.totalEmprunts,
          totalPrets: prev.totalPrets + (debt.remainingAmount ?? debt.montant),
        );
      }
    }
    return result;
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
      summary: _computeSummary(_allItems),
    );
  }
}

final debtPaymentsProvider =
    FutureProvider.family<List<DebtPayment>, String>((ref, debtId) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getPayments(debtId);
});
