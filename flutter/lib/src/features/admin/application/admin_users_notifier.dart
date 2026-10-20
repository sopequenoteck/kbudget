// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/admin/application/admin_users_list_state.dart';
import 'package:k_budget/src/features/admin/data/admin_remote_repository.dart';
import 'package:k_budget/src/features/admin/data/admin_repository.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';

final adminUsersNotifierProvider =
    NotifierProvider<AdminUsersNotifier, AdminUsersListState>(
  AdminUsersNotifier.new,
);

/// Liste des utilisateurs pour l'administration, activation et desactivation.
class AdminUsersNotifier extends Notifier<AdminUsersListState>
    with SessionGuard {
  @override
  AdminUsersListState build() {
    // L'etat appartient a la session : reconstruit a chaque connexion et
    // deconnexion, sinon B heriterait des donnees de A (KKS-546).
    watchSession(ref);
    return const AdminUsersListState();
  }

  AdminRepository get _repo =>
      ref.read(adminRepositoryProvider).requireValue;

  Future<void> loadItems() async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.listUsers();
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(items: items, isLoading: false);
    } on Exception {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).usersFeedbackLoadUsersError,
      );
    }
  }

  Future<void> disable(String id) async {
    final token = session;
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    try {
      await _repo.disableUser(id);
      if (isStale(token)) {
        return;
      }
      await loadItems();
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
      );
      rethrow;
    }
  }

  Future<void> enable(String id) async {
    final token = session;
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    try {
      await _repo.enableUser(id);
      if (isStale(token)) {
        return;
      }
      await loadItems();
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
        error: ref.read(appLocalizationsProvider).usersFeedbackUserEnableError,
      );
    }
  }
}
