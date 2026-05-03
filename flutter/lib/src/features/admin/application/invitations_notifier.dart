import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/admin/application/invitation_list_state.dart';
import 'package:k_budget/src/features/admin/data/admin_remote_repository.dart';
import 'package:k_budget/src/features/admin/data/admin_repository.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';

final invitationsNotifierProvider =
    NotifierProvider<InvitationsNotifier, InvitationListState>(
  InvitationsNotifier.new,
);

class InvitationsNotifier extends Notifier<InvitationListState> {
  @override
  InvitationListState build() => const InvitationListState();

  AdminRepository get _repo =>
      ref.read(adminRepositoryProvider).requireValue;

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.listInvitations();
      state = state.copyWith(items: items, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les invitations: $e',
      );
    }
  }

  Future<InvitationCreated> createInvitation(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repo.createInvitation(email);
      await loadItems();
      return created;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création de l\'invitation: $e',
      );
      rethrow;
    }
  }

  Future<void> revoke(int id) async {
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    try {
      await _repo.revokeInvitation(id);
      await loadItems();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur lors de la révocation: $e',
      );
    }
  }
}
