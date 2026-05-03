import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/admin/application/admin_users_list_state.dart';
import 'package:k_budget/src/features/admin/data/admin_remote_repository.dart';
import 'package:k_budget/src/features/admin/data/admin_repository.dart';

final adminUsersNotifierProvider =
    NotifierProvider<AdminUsersNotifier, AdminUsersListState>(
  AdminUsersNotifier.new,
);

class AdminUsersNotifier extends Notifier<AdminUsersListState> {
  @override
  AdminUsersListState build() => const AdminUsersListState();

  AdminRepository get _repo =>
      ref.read(adminRepositoryProvider).requireValue;

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.listUsers();
      state = state.copyWith(items: items, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les utilisateurs: $e',
      );
    }
  }

  Future<void> disable(String id) async {
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    try {
      await _repo.disableUser(id);
      await loadItems();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
      rethrow;
    }
  }

  Future<void> enable(String id) async {
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    try {
      await _repo.enableUser(id);
      await loadItems();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur lors de la réactivation: $e',
      );
    }
  }
}
