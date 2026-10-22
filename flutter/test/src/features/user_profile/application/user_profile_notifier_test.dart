// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
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
  final updates = <Currency>[];
  Exception? updateError;

  @override
  Future<User> getProfile() {
    final read = Completer<User>();
    reads.add(read);
    return read.future;
  }

  @override
  Future<User> updateProfile({required Currency defaultCurrency}) async {
    final error = updateError;
    if (error != null) {
      throw error;
    }
    updates.add(defaultCurrency);
    return User(
      id: 'a',
      email: 'a@example.com',
      name: 'Alice',
      defaultCurrency: defaultCurrency,
    );
  }
}

void main() {
  const userA = User(id: 'a', email: 'a@example.com', name: 'Alice');
  const userB = User(id: 'b', email: 'b@example.com', name: 'Bob');

  // Conteneur authentifie dont le profil de A est deja charge.
  Future<(ProviderContainer, _FakeUserRepository)> loadedContainer() async {
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
    await loading;
    return (container, repo);
  }

  group('UserProfileNotifier', () {
    test('should_reloadProfile_when_loadProfileCalled', () async {
      final (container, repo) = await loadedContainer();

      final reloading =
          container.read(userProfileNotifierProvider.notifier).loadProfile();
      expect(container.read(userProfileNotifierProvider).isLoading, isTrue);
      repo.reads.last.complete(userB);
      await reloading;

      final state = container.read(userProfileNotifierProvider);
      expect(state, isA<AsyncData<User>>());
      expect(state.value, userB);
    });

    test('should_setError_when_loadProfileFails', () async {
      final (container, repo) = await loadedContainer();

      final reloading =
          container.read(userProfileNotifierProvider.notifier).loadProfile();
      repo.reads.last.completeError(Exception('Server error'));
      await reloading;

      expect(
        container.read(userProfileNotifierProvider),
        isA<AsyncError<User>>(),
      );
    });

    test('should_updateCurrency_when_updateSucceeds', () async {
      final (container, repo) = await loadedContainer();

      final result = await container
          .read(userProfileNotifierProvider.notifier)
          .updateCurrency(Currency.usd);

      expect(result, isTrue);
      expect(repo.updates, [Currency.usd]);
      expect(
        container.read(userProfileNotifierProvider).value?.defaultCurrency,
        Currency.usd,
      );
    });

    test('should_restorePreviousProfile_when_updateFails', () async {
      final (container, repo) = await loadedContainer();
      repo.updateError = Exception('Server error');

      final result = await container
          .read(userProfileNotifierProvider.notifier)
          .updateCurrency(Currency.usd);

      expect(result, isFalse);
      expect(container.read(userProfileNotifierProvider).value, userA);
    });

    test('should_returnFalse_when_updateCurrencyWithoutLoadedProfile',
        () async {
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
      await container.read(userRepositoryProvider.future);
      // Le profil est encore en cours de chargement : aucune valeur.
      container.read(userProfileNotifierProvider);

      final result = await container
          .read(userProfileNotifierProvider.notifier)
          .updateCurrency(Currency.usd);

      expect(result, isFalse);
      expect(repo.updates, isEmpty);
    });

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

    test('should_ignoreStaleResponse_when_sessionChangesDuringLoad', () async {
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
      await container.read(userRepositoryProvider.future);
      final loading =
          container.read(userProfileNotifierProvider.notifier).loadProfile();
      expect(repo.reads, hasLength(1));

      // A se deconnecte et B se connecte avant la reponse de A.
      final auth = container.read(authNotifierProvider.notifier)
          as FakeAuthNotifier;
      auth.emit(const AuthState.unauthenticated());
      auth.emit(const AuthState.authenticated());
      // Un widget qui observe l'etat reconstruit le notifier pour B.
      container.read(userProfileNotifierProvider);
      repo.reads.first.complete(userA);
      await loading;

      expect(container.read(userProfileNotifierProvider).valueOrNull, isNull);
    });
  });
}
