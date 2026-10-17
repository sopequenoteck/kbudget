// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/domain/repositories/user_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_providers.dart';

import '../../settings/application/language_notifier_test.dart'
    show FakeAuthNotifier;

/// Depot dont chaque lecture du profil est pilotee par le test.
class _FakeUserRepository extends Fake implements UserRepository {
  final reads = <Completer<User>>[];

  @override
  Future<User> getProfile() {
    final read = Completer<User>();
    reads.add(read);
    return read.future;
  }
}

void main() {
  const userA = User(id: 'a', email: 'a@example.com', name: 'Alice');
  const userB = User(id: 'b', email: 'b@example.com', name: 'Bob');

  group('UserProfileNotifier', () {
    test('should_resetState_when_sessionEnds', () async {
      final repo = _FakeUserRepository();
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((ref) async => repo),
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthState.authenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final loading = container.read(userProfileNotifierProvider.future);
      await pumpEventQueue();
      repo.reads.single.complete(userA);
      expect(await loading, userA);
      expect(container.read(userProfileNotifierProvider).value, userA);

      (container.read(authNotifierProvider.notifier) as FakeAuthNotifier)
          .emit(const AuthState.unauthenticated());

      // Riverpod garde la valeur precedente pendant le rechargement : seul
      // l'etat de chargement et la nouvelle lecture sont verifiables ici.
      expect(container.read(userProfileNotifierProvider).isLoading, isTrue);
      final reloading = container.read(userProfileNotifierProvider.future);
      await pumpEventQueue();
      expect(repo.reads, hasLength(2));
      repo.reads.last.complete(userB);
      expect(await reloading, userB);
    });
  });
}
