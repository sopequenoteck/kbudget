import 'package:k_budget/src/features/admin/data/admin_user_model.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';

abstract class AdminRepository {
  Future<InvitationCreated> createInvitation(String email);
  Future<List<Invitation>> listInvitations();
  Future<void> revokeInvitation(int id);
  Future<List<AdminUser>> listUsers();
  Future<void> disableUser(String id);
  Future<void> enableUser(String id);
}
