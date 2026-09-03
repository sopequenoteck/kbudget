// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/features/user_profile/domain/models/avatar_metadata.dart';
import 'package:k_budget/src/features/user_profile/domain/models/change_password_request.dart';
import 'package:k_budget/src/features/user_profile/domain/models/delete_account_request.dart';

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

  /// Exporte toutes les données utilisateur au format JSON
  /// (GET /users/me/export?format=json).
  /// Sauvegarde le fichier localement et retourne le [File].
  Future<File> exportJson();

  /// Exporte les transactions au format CSV
  /// (GET /users/me/export?format=csv).
  /// Sauvegarde le fichier localement et retourne le [File].
  Future<File> exportCsv();

  /// Supprime le compte utilisateur (DELETE /users/me).
  /// [req] doit contenir le mot de passe actuel et confirmed = true.
  Future<void> deleteAccount(DeleteAccountRequest req);
}
