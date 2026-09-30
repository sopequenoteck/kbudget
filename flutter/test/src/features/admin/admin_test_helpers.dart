import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/admin/data/admin_remote_repository.dart';
import 'package:k_budget/src/features/admin/data/admin_user_model.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';

import '../../../helpers/display_locale.dart';
import '../../../helpers/mocks.mocks.dart';

/// Utilisateur actif de test.
AdminUser adminUser({
  String id = 'u1',
  String displayName = 'Alice',
  String email = 'alice@example.com',
  bool isAdmin = false,
  DateTime? disabledAt,
}) => AdminUser(
  id: id,
  email: email,
  displayName: displayName,
  createdAt: DateTime(2026, 1, 1),
  disabledAt: disabledAt,
  isAdmin: isAdmin,
);

/// Invitation de test.
Invitation invitation({
  int id = 1,
  String email = 'new@example.com',
  InvitationStatus status = InvitationStatus.active,
  String? token = 'tok',
}) => Invitation(
  id: id,
  email: email,
  invitedByEmail: 'boss@example.com',
  status: status,
  token: token,
  createdAt: DateTime(2026, 1, 1),
  expiresAt: DateTime(2026, 2, 1),
);

/// Surcharge resolue de `adminRepositoryProvider`.
Override adminRepoOverride(MockAdminRepository repo) =>
    adminRepositoryProvider.overrideWith((ref) async => repo);

/// Conteneur dont le repository admin est deja resolu (`requireValue`).
Future<ProviderContainer> adminContainer(MockAdminRepository repo) async {
  final container = ProviderContainer(
    overrides: [displayLocaleOverride(), adminRepoOverride(repo)],
  );
  await container.read(adminRepositoryProvider.future);
  return container;
}
