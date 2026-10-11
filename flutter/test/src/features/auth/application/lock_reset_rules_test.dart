import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/app_lock_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/display_locale.dart';
import '../../../../helpers/fake_app_config_repository.dart';
import '../../../../helpers/lock_test_helpers.dart';
import '../../../../helpers/mocks.mocks.dart';

/// The lock is reset only where the tokens are erased (`logout()`, and the
/// server change tested in `data_settings_notifier_test.dart`), never where
/// they are kept (`forceUnauthenticated()`, a failed `checkAuth()`).
void main() {
  late FakeAppConfigRepository repo;
  late MockAuthRepository authRepo;
  late ProviderContainer container;

  AuthNotifier auth() => container.read(authNotifierProvider.notifier);

  AppLockState lock() => container.read(appLockNotifierProvider);

  /// A container whose lock is on and unlocked, with an open session.
  Future<void> startUnlockedSession() async {
    repo.config = lockedConfig();
    lock();
    await pumpEventQueue();
    await container
        .read(appLockNotifierProvider.notifier)
        .unlockWithPin('1234');
    when(authRepo.hasValidToken()).thenAnswer((_) async => true);
    await auth().checkAuth();
    expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
  }

  setUp(() {
    repo = FakeAppConfigRepository();
    authRepo = MockAuthRepository();
    when(authRepo.logout()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        displayLocaleOverride(),
        appConfigRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWith((_) async => authRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('logout', () {
    test('should_resetLock_when_logoutSucceeds', () async {
      await startUnlockedSession();

      await auth().logout();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      expect(repo.config.lockEnabled, isFalse);
      expect(repo.config.hashedPin, isNull);
      expect(repo.config.pinSalt, isNull);
      expect(lock().enabled, isFalse);
      expect(lock().status, LockStatus.unlocked);
    });

    test('should_eraseTokensBeforeResettingLock_when_logout', () async {
      await startUnlockedSession();
      var lockStillOnWhenTokensErased = false;
      when(authRepo.logout()).thenAnswer((_) async {
        lockStillOnWhenTokensErased = repo.config.lockEnabled;
      });

      await auth().logout();

      expect(lockStillOnWhenTokensErased, isTrue);
      expect(repo.config.lockEnabled, isFalse);
    });

    test('should_signOutAndUnlock_when_resetThrowsAnError', () async {
      await startUnlockedSession();
      repo.readError = TypeError();

      await auth().logout();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      expect(lock().status, LockStatus.unlocked);
      expect(lock().enabled, isFalse);
    });

    test('should_keepLockAndSession_when_tokensCannotBeErased', () async {
      await startUnlockedSession();
      when(authRepo.logout()).thenThrow(Exception('clearTokens failed'));
      final writesBefore = repo.writes;

      await expectLater(auth().logout(), throwsA(isA<Exception>()));

      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
      expect(repo.config.lockEnabled, isTrue);
      expect(repo.config.hashedPin, isNotNull);
      expect(repo.writes, writesBefore);
      expect(lock().enabled, isTrue);
    });
  });

  group('paths that keep the tokens', () {
    test('should_keepLock_when_forceUnauthenticated', () async {
      await startUnlockedSession();
      final before = repo.config;
      final writesBefore = repo.writes;

      auth().forceUnauthenticated();
      await pumpEventQueue();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      expect(repo.config, before);
      expect(repo.config.lockEnabled, isTrue);
      expect(repo.config.hashedPin, before.hashedPin);
      expect(repo.writes, writesBefore);
      expect(lock().enabled, isTrue);
    });

    test('should_keepLock_when_checkAuthFails', () async {
      repo.config = lockedConfig();
      lock();
      await pumpEventQueue();
      when(authRepo.hasValidToken()).thenAnswer((_) async => false);
      when(authRepo.refresh()).thenThrow(Exception('offline'));

      await auth().checkAuth();
      await pumpEventQueue();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      expect(repo.config.lockEnabled, isTrue);
      expect(repo.config.hashedPin, isNotNull);
      expect(repo.writes, 0);
      expect(lock().status, LockStatus.locked);
    });

    test('should_notBypassLock_when_sessionResumesAfterForcedLogout', () async {
      await startUnlockedSession();
      auth().forceUnauthenticated();
      await container
          .read(appLockNotifierProvider.notifier)
          .unlockWithPin('0000');

      when(authRepo.hasValidToken()).thenAnswer((_) async => true);
      await auth().checkAuth();

      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
      expect(lock().enabled, isTrue);
      expect(repo.config.failedPinAttempts, 1);
    });
  });

  group('sign-in with the password', () {
    setUp(() async {
      repo.config = lockedConfig();
      lock();
      await pumpEventQueue();
    });

    test('should_unlockWithoutDisablingLock_when_loginSucceeds', () async {
      expect(lock().status, LockStatus.locked);
      when(authRepo.login('a@b.c', 'secret')).thenAnswer(
        (_) async => const AuthResult(
          accessToken: 'a',
          refreshToken: 'r',
          email: 'a@b.c',
        ),
      );

      await auth().login('a@b.c', 'secret');

      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
      expect(lock().status, LockStatus.unlocked);
      expect(lock().enabled, isTrue);
      expect(repo.config.lockEnabled, isTrue);
      expect(repo.config.hashedPin, isNotNull);
      expect(repo.writes, 0);
    });

    test('should_stayLocked_when_loginFails', () async {
      when(authRepo.login(any, any)).thenThrow(Exception('bad credentials'));

      await auth().login('a@b.c', 'wrong');

      expect(container.read(authNotifierProvider), isA<AuthLoginFailed>());
      expect(lock().status, LockStatus.locked);
    });

    test('should_unlock_when_firstLoginResetCompletes', () async {
      when(
        authRepo.firstLoginReset(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        ),
      ).thenAnswer(
        (_) async => const AuthResult(
          accessToken: 'a',
          refreshToken: 'r',
          email: 'a@b.c',
        ),
      );

      await auth().completeFirstLoginReset(
        email: 'a@b.c',
        password: 'new-secret',
        displayName: 'A',
      );

      expect(lock().status, LockStatus.unlocked);
      expect(lock().enabled, isTrue);
      expect(repo.config.lockEnabled, isTrue);
    });
  });
}
