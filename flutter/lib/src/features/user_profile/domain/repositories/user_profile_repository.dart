import 'dart:io';

import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/features/user_profile/domain/models/avatar_metadata.dart';
import 'package:k_budget/src/features/user_profile/domain/models/change_password_request.dart';

/// Repository server-only pour les opérations de profil avancées.
/// Pas d'implémentation Local — décision RES-013.
abstract class UserProfileRepository {
  /// Upload un avatar (POST /users/me/avatar).
  Future<AvatarMetadata> uploadAvatar(File file);

  /// Supprime l'avatar (DELETE /users/me/avatar).
  Future<void> deleteAvatar();

  /// Change le mot de passe (POST /users/me/password).
  /// Retourne un nouvel [AuthResponse] avec les nouveaux tokens.
  Future<AuthResponse> changePassword(ChangePasswordRequest req);

  /// Met à jour le nom de profil (PUT /users/me).
  Future<void> updateName(String name);
}
