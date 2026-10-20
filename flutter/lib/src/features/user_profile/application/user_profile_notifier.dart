// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/domain/repositories/user_repository.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_providers.dart';

final userProfileNotifierProvider =
    AsyncNotifierProvider<UserProfileNotifier, User>(
  UserProfileNotifier.new,
);

/// Profil du compte connecte.
class UserProfileNotifier extends AsyncNotifier<User>
    with SessionGuard {
  UserRepository get _repo => ref.read(userRepositoryProvider).requireValue;

  @override
  Future<User> build() async {
    // Le profil appartient a la session : reconstruit a chaque connexion et
    // deconnexion, sinon B heriterait des donnees de A (KKS-546).
    watchSession(ref);
    final repo = await ref.watch(userRepositoryProvider.future);
    return repo.getProfile();
  }

  Future<void> loadProfile() async {
    final token = session;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repo.getProfile());
    if (isStale(token)) {
      return;
    }
    state = result;
  }

  Future<bool> updateCurrency(Currency currency) async {
    final previous = state.valueOrNull;
    if (previous == null) return false;

    final token = session;
    state = AsyncData(previous.copyWith(defaultCurrency: currency));

    try {
      final updated = await _repo.updateProfile(defaultCurrency: currency);
      if (isStale(token)) {
        return true;
      }
      state = AsyncData(updated);
      return true;
    } on Exception {
      if (isStale(token)) {
        return false;
      }
      state = AsyncData(previous);
      return false;
    }
  }
}
