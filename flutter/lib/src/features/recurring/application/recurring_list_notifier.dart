// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/dtos/recurring_transaction_create_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/domain/repositories/recurring_transaction_repository.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/recurring/data/recurring_transaction_repository_remote.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';

final recurringListNotifierProvider =
    NotifierProvider<RecurringListNotifier, ListState<RecurringTransaction>>(
  RecurringListNotifier.new,
);

class RecurringListNotifier
    extends Notifier<ListState<RecurringTransaction>>
    with SessionGuard {
  @override
  ListState<RecurringTransaction> build() {
    // L'etat appartient a la session : reconstruit a chaque connexion et
    // deconnexion, sinon B heriterait des donnees de A (KKS-546).
    watchSession(ref);
    return const ListState<RecurringTransaction>();
  }

  Future<RecurringTransactionRepository> get _repo async =>
      ref.read(recurringTransactionRepositoryProvider.future);

  Future<void> loadItems() async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = await _repo;
      final items = await repo.listActive();
      if (isStale(token)) {
        return;
      }
      final sorted = _sortItems(items);
      state = state.copyWith(items: sorted, isLoading: false);
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

  // isLoading global et non mutatingIds : l'element n'a pas encore d'id a
  // suivre.
  Future<void> create(RecurringTransactionCreateRequest req) async {
    final token = session;
    state = state.copyWith(isLoading: true);
    try {
      final repo = await ref.read(recurringTransactionRepositoryProvider.future);
      await repo.create(req);
      if (isStale(token)) {
        return;
      }
      await _refreshList();
    } on Exception {
      if (isStale(token)) {
        return;
      }
      // L'echec est annonce par l'appelant (KKS-422), pas porte par l'etat.
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> validate(String id) async {
    final token = session;
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final repo = await _repo;
      await repo.validate(id);
      if (isStale(token)) {
        return;
      }
      await _refreshList();
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: ref
            .read(appLocalizationsProvider)
            .recurringFeedbackValidationError,
      );
    }
  }

  Future<void> skip(String id) async {
    final token = session;
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final repo = await _repo;
      await repo.skip(id);
      if (isStale(token)) {
        return;
      }
      await _refreshList();
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: ref.read(appLocalizationsProvider).recurringFeedbackSkipFailed,
      );
    }
  }

  Future<void> validateAll(List<String> ids) async {
    if (ids.isEmpty) return;
    final token = session;
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, '__all__'},
      error: null,
    );
    try {
      for (final id in ids) {
        await validate(id);
        if (isStale(token)) {
          return;
        }
      }
    } on Exception {
      // ignore: individual validate() handles its own error state
    } finally {
      if (!isStale(token)) {
        state = state.copyWith(
          mutatingIds: {...state.mutatingIds}..remove('__all__'),
        );
      }
    }
  }

  Future<void> deactivate(String id) async {
    final token = session;
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final repo = await _repo;
      await repo.deactivate(id);
      if (isStale(token)) {
        return;
      }
      await _refreshList();
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: ref
            .read(appLocalizationsProvider)
            .recurringFeedbackDeactivateError,
      );
    }
  }

  Future<void> _refreshList() async {
    final token = session;
    final repo = await _repo;
    final items = await repo.listActive();
    if (isStale(token)) {
      return;
    }
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
