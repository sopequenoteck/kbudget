import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/app_lock_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:k_budget/src/features/auth/application/pin_hashing.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/display_locale.dart';
import '../../../../helpers/fake_app_config_repository.dart';
import '../../../../helpers/lock_test_helpers.dart';
import '../../../../helpers/mocks.mocks.dart';

void main() {
  late FakeAppConfigRepository repo;
  late MockAuthRepository authRepo;
  late FakeBiometricAuthenticator biometrics;
  late ProviderContainer container;
  late DateTime now;

  ProviderContainer buildContainer() => ProviderContainer(
    overrides: [
      displayLocaleOverride(),
      appConfigRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWith((_) async => authRepo),
      biometricAuthenticatorProvider.overrideWithValue(biometrics),
      lockClockProvider.overrideWithValue(() => now),
    ],
  );

  AppLockNotifier notifier() =>
      container.read(appLockNotifierProvider.notifier);

  AppLockState state() => container.read(appLockNotifierProvider);

  /// Reads the notifier and lets its configuration load.
  Future<void> loaded() async {
    state();
    await pumpEventQueue();
  }

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    repo = FakeAppConfigRepository();
    authRepo = MockAuthRepository();
    when(authRepo.logout()).thenAnswer((_) async {});
    biometrics = FakeBiometricAuthenticator();
    container = buildContainer();
  });

  tearDown(() => container.dispose());

  group('initial state', () {
    test('should_beUnknown_when_configurationNotReadYet', () {
      repo.config = lockedConfig();

      expect(state().status, LockStatus.unknown);
    });

    test('should_beLocked_when_lockEnabled', () async {
      repo.config = lockedConfig();

      await loaded();

      expect(state().status, LockStatus.locked);
      expect(state().enabled, isTrue);
      expect(state().biometricEnabled, isFalse);
    });

    test('should_beUnlocked_when_lockDisabled', () async {
      await loaded();

      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isFalse);
    });

    test('should_exposeBiometric_when_methodIsBiometric', () async {
      repo.config = lockedConfig(method: LockMethod.biometric);

      await loaded();

      expect(state().biometricEnabled, isTrue);
    });

    test('should_beUnlocked_when_configurationUnreadable', () async {
      repo.readError = const FormatException('corrupted');

      await loaded();

      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isFalse);
    });

    test('should_readConfigurationOnce_when_loaded', () async {
      await loaded();

      expect(repo.reads, 1);
      expect(repo.writes, 0);
    });
  });

  group('unlockWithPin', () {
    setUp(() => repo.config = lockedConfig());

    test('should_unlockAndResetCounter_when_pinRight', () async {
      repo.config = lockedConfig(failedPinAttempts: 3);
      await loaded();

      final result = await notifier().unlockWithPin('1234');

      expect(result.isValid, isTrue);
      expect(state().status, LockStatus.unlocked);
      expect(repo.config.failedPinAttempts, 0);
    });

    test('should_notWrite_when_pinRightAndCounterAlreadyZero', () async {
      await loaded();
      final readsBefore = repo.reads;

      await notifier().unlockWithPin('1234');

      expect(repo.reads - readsBefore, 1);
      expect(repo.writes, 0);
    });

    test('should_stayLockedAndReturnAttemptsLeft_when_pinWrong', () async {
      await loaded();

      final result = await notifier().unlockWithPin('0000');

      expect(result.isValid, isFalse);
      expect(result.attemptsLeft, 4);
      expect(state().status, LockStatus.locked);
    });

    test('should_decreaseAttemptsLeft_when_wrongPinsFollow', () async {
      await loaded();

      final left = <int>[];
      for (var i = 0; i < 4; i++) {
        left.add((await notifier().unlockWithPin('0000')).attemptsLeft);
      }

      expect(left, [4, 3, 2, 1]);
    });

    test('should_persistCounter_when_pinWrong', () async {
      await loaded();

      await notifier().unlockWithPin('0000');

      expect(repo.config.failedPinAttempts, 1);
    });

    test('should_readOnceAndWriteOnce_when_pinWrong', () async {
      await loaded();
      final readsBefore = repo.reads;

      await notifier().unlockWithPin('0000');

      expect(repo.reads - readsBefore, 1);
      expect(repo.writes, 1);
    });

    test('should_writeCounterBeforeReturning_when_pinWrong', () async {
      await loaded();
      final gate = repo.writeGate = Completer<void>();
      var returned = false;

      final pending = notifier().unlockWithPin('0000').then((result) {
        returned = true;
        return result;
      });
      await pumpEventQueue();

      expect(returned, isFalse);
      expect(repo.writes, 1);

      gate.complete();
      await pending;
      expect(returned, isTrue);
      expect(repo.config.failedPinAttempts, 1);
    });

    test('should_keepCounter_when_applicationRestarts', () async {
      await loaded();
      await notifier().unlockWithPin('0000');
      await notifier().unlockWithPin('0000');
      container.dispose();

      container = buildContainer();
      await loaded();
      final result = await notifier().unlockWithPin('0000');

      expect(result.attemptsLeft, 2);
      expect(state().status, LockStatus.locked);
    });

    test('should_notCountOrWrite_when_saltMissing', () async {
      repo.config = lockedConfig().copyWith(pinSalt: null);
      await loaded();

      final result = await notifier().unlockWithPin('1234');

      expect(result.isValid, isFalse);
      expect(result.attemptsLeft, 5);
      expect(repo.config.failedPinAttempts, 0);
      expect(repo.writes, 0);
      expect(state().status, LockStatus.locked);
    });

    test('should_notCountOrWrite_when_hashMissing', () async {
      repo.config = lockedConfig().copyWith(hashedPin: null);
      await loaded();

      final result = await notifier().unlockWithPin('1234');

      expect(result.isValid, isFalse);
      expect(repo.writes, 0);
    });

    test('should_signOutAndResetLock_when_fifthWrongPin', () async {
      repo.config = lockedConfig(failedPinAttempts: 4);
      await loaded();

      final result = await notifier().unlockWithPin('0000');

      expect(result.isValid, isFalse);
      expect(result.attemptsLeft, 0);
      verify(authRepo.logout()).called(1);
      expect(
        container.read(authNotifierProvider),
        const AuthState.unauthenticated(),
      );
      expect(repo.config.lockEnabled, isFalse);
      expect(repo.config.hashedPin, isNull);
      expect(repo.config.pinSalt, isNull);
      expect(repo.config.lockMethod, isNull);
      expect(repo.config.failedPinAttempts, 0);
      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isFalse);
    });

    test('should_notSignOut_when_fourthWrongPin', () async {
      repo.config = lockedConfig(failedPinAttempts: 3);
      await loaded();

      await notifier().unlockWithPin('0000');

      verifyNever(authRepo.logout());
      expect(state().status, LockStatus.locked);
    });

    test(
      'should_signOutAfterFiveWrongPinsInARow_when_enteredOneByOne',
      () async {
        await loaded();

        for (var i = 0; i < 5; i++) {
          await notifier().unlockWithPin('0000');
        }

        verify(authRepo.logout()).called(1);
        expect(repo.config.lockEnabled, isFalse);
      },
    );

    test('should_stayLockedAndRetry_when_signOutFails', () async {
      repo.config = lockedConfig(failedPinAttempts: 4);
      when(authRepo.logout()).thenThrow(Exception('clearTokens failed'));
      await loaded();

      final first = await notifier().unlockWithPin('0000');
      final second = await notifier().unlockWithPin('0000');

      expect(first.attemptsLeft, 0);
      expect(second.attemptsLeft, 0);
      verify(authRepo.logout()).called(2);
      expect(state().status, LockStatus.locked);
      expect(repo.config.lockEnabled, isTrue);
      expect(repo.config.hashedPin, isNotNull);
      expect(repo.config.failedPinAttempts, 6);
    });

    test('should_failClosed_when_counterCannotBeWritten', () async {
      await loaded();
      repo.writeError = Exception('disk full');

      await expectLater(
        notifier().unlockWithPin('0000'),
        throwsA(isA<Exception>()),
      );

      expect(state().status, LockStatus.locked);
    });
  });

  group('verifyPin', () {
    setUp(() => repo.config = lockedConfig());

    test('should_returnValidAndKeepLocked_when_pinRight', () async {
      await loaded();

      final result = await notifier().verifyPin('1234');

      expect(result.isValid, isTrue);
      expect(state().status, LockStatus.locked);
    });

    test('should_shareCounterWithUnlock_when_pinWrong', () async {
      await loaded();

      await notifier().unlockWithPin('0000');
      await notifier().verifyPin('0000');
      final result = await notifier().verifyPin('0000');

      expect(result.attemptsLeft, 2);
      expect(repo.config.failedPinAttempts, 3);
    });

    test('should_resetCounter_when_pinRight', () async {
      repo.config = lockedConfig(failedPinAttempts: 2);
      await loaded();

      await notifier().verifyPin('1234');

      expect(repo.config.failedPinAttempts, 0);
    });

    test('should_signOut_when_fifthWrongPinInSettings', () async {
      repo.config = lockedConfig(failedPinAttempts: 4);
      await loaded();

      await notifier().verifyPin('0000');

      verify(authRepo.logout()).called(1);
      expect(repo.config.lockEnabled, isFalse);
    });
  });

  group('without a stored PIN', () {
    test('should_neverWriteOrSignOut_when_pinCheckedFiveTimes', () async {
      await loaded();

      for (var i = 0; i < 6; i++) {
        final result = await notifier().verifyPin('0000');
        expect(result.isValid, isFalse);
      }

      expect(repo.writes, 0);
      verifyNever(authRepo.logout());
      expect(state().status, LockStatus.unlocked);
      expect(repo.config.failedPinAttempts, 0);
    });

    test('should_neverWriteOrSignOut_when_disableAskedFiveTimes', () async {
      await loaded();

      for (var i = 0; i < 5; i++) {
        await notifier().disable('0000');
      }

      expect(repo.writes, 0);
      verifyNever(authRepo.logout());
    });
  });

  group('unreadable configuration', () {
    test('should_beUnlocked_when_readThrowsAnError', () async {
      repo.readError = TypeError();

      await loaded();

      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isFalse);
    });

    test('should_notFail_when_unlockAfterLoginAndReadThrowsAnError', () async {
      repo.readError = TypeError();

      await notifier().unlockAfterLogin();

      expect(state().status, LockStatus.unlocked);
    });

    test('should_lock_when_resumedAndReadNowSucceedsWithLockStored', () async {
      repo.readError = Exception('keychain unavailable');
      await loaded();
      expect(state().status, LockStatus.unlocked);
      repo
        ..readError = null
        ..config = lockedConfig(method: LockMethod.biometric);

      notifier().onLifecycleChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(state().status, LockStatus.locked);
      expect(state().enabled, isTrue);
      expect(state().biometricEnabled, isTrue);
    });

    test(
      'should_stayUnlockedWithoutError_when_resumedAndReadStillFails',
      () async {
        repo.readError = TypeError();
        await loaded();

        notifier().onLifecycleChanged(AppLifecycleState.resumed);
        await pumpEventQueue();
        notifier().onLifecycleChanged(AppLifecycleState.resumed);
        await pumpEventQueue();

        expect(state().status, LockStatus.unlocked);
        expect(repo.reads, 3);
      },
    );

    test('should_retryAtNextReturn_when_firstRetryFailed', () async {
      repo.readError = Exception('keychain unavailable');
      await loaded();
      notifier().onLifecycleChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      repo
        ..readError = null
        ..config = lockedConfig();

      notifier().onLifecycleChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(state().status, LockStatus.locked);
    });

    test('should_stopReading_when_retrySucceedsWithoutLock', () async {
      repo.readError = Exception('keychain unavailable');
      await loaded();
      repo.readError = null;
      notifier().onLifecycleChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      final readsBefore = repo.reads;

      notifier().onLifecycleChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(state().status, LockStatus.unlocked);
      expect(repo.reads, readsBefore);
    });

    test('should_notLock_when_lockEnabledMeanwhile', () async {
      repo.readError = Exception('keychain unavailable');
      await loaded();
      repo.readError = null;
      await notifier().enable('4827');

      notifier().onLifecycleChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isTrue);
    });

    test('should_notRetry_when_readSucceededAtLaunch', () async {
      await loaded();

      notifier().onLifecycleChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(repo.reads, 1);
    });
  });

  group('unlockWithBiometrics', () {
    test('should_unlockWithoutCounting_when_biometricsSucceed', () async {
      repo.config = lockedConfig(
        method: LockMethod.biometric,
        failedPinAttempts: 3,
      );
      await loaded();

      final unlocked = await notifier().unlockWithBiometrics();

      expect(unlocked, isTrue);
      expect(state().status, LockStatus.unlocked);
      expect(biometrics.lastReason, 'Déverrouillez K-Budget');
      expect(repo.config.failedPinAttempts, 3);
    });

    test('should_stayLockedWithoutCounting_when_biometricsFail', () async {
      repo.config = lockedConfig(method: LockMethod.biometric);
      biometrics.succeeds = false;
      await loaded();

      final unlocked = await notifier().unlockWithBiometrics();

      expect(unlocked, isFalse);
      expect(state().status, LockStatus.locked);
      expect(repo.config.failedPinAttempts, 0);
      expect(repo.writes, 0);
    });

    test('should_notAsk_when_methodIsPin', () async {
      repo.config = lockedConfig();
      await loaded();

      final unlocked = await notifier().unlockWithBiometrics();

      expect(unlocked, isFalse);
      expect(biometrics.authenticateCalls, 0);
      expect(state().status, LockStatus.locked);
    });
  });

  group('lifecycle', () {
    final left = DateTime(2026, 1, 1, 12);

    setUp(() async {
      repo.config = lockedConfig();
      await loaded();
      await notifier().unlockWithPin('1234');
      now = left;
    });

    void away(AppLifecycleState leaving, Duration duration) {
      now = left;
      notifier().onLifecycleChanged(leaving);
      now = left.add(duration);
      notifier().onLifecycleChanged(AppLifecycleState.resumed);
    }

    test('should_lock_when_awayExactlyOneMinute', () {
      away(AppLifecycleState.paused, const Duration(seconds: 60));

      expect(state().status, LockStatus.locked);
    });

    test('should_stayUnlocked_when_awayFiftyNineSeconds', () {
      away(AppLifecycleState.paused, const Duration(seconds: 59));

      expect(state().status, LockStatus.unlocked);
    });

    test('should_lock_when_awayOverOneMinute', () {
      away(AppLifecycleState.paused, const Duration(minutes: 30));

      expect(state().status, LockStatus.locked);
    });

    test('should_lock_when_clockWentBackwards', () {
      away(AppLifecycleState.paused, const Duration(seconds: -5));

      expect(state().status, LockStatus.locked);
    });

    test('should_lock_when_hiddenForOneMinute', () {
      away(AppLifecycleState.hidden, const Duration(seconds: 60));

      expect(state().status, LockStatus.locked);
    });

    test('should_stayUnlocked_when_onlyInactive', () {
      away(AppLifecycleState.inactive, const Duration(hours: 1));

      expect(state().status, LockStatus.unlocked);
    });

    test('should_stayUnlocked_when_resumedWithoutLeaving', () {
      now = left.add(const Duration(hours: 1));

      notifier().onLifecycleChanged(AppLifecycleState.resumed);

      expect(state().status, LockStatus.unlocked);
    });

    test('should_keepEarliestTime_when_pausedFollowsHidden', () {
      notifier().onLifecycleChanged(AppLifecycleState.hidden);
      now = left.add(const Duration(seconds: 30));
      notifier().onLifecycleChanged(AppLifecycleState.paused);
      now = left.add(const Duration(seconds: 60));
      notifier().onLifecycleChanged(AppLifecycleState.resumed);

      expect(state().status, LockStatus.locked);
    });

    test('should_timeEachAbsenceSeparately_when_backgroundedTwice', () {
      away(AppLifecycleState.paused, const Duration(seconds: 10));
      now = left.add(const Duration(minutes: 5));
      notifier().onLifecycleChanged(AppLifecycleState.paused);
      now = left.add(const Duration(minutes: 5, seconds: 10));
      notifier().onLifecycleChanged(AppLifecycleState.resumed);

      expect(state().status, LockStatus.unlocked);
    });

    test('should_ignoreDetached_when_appDetaches', () {
      away(AppLifecycleState.detached, const Duration(hours: 1));

      expect(state().status, LockStatus.unlocked);
    });

    test('should_notLock_when_lockDisabled', () async {
      await notifier().disable('1234');

      away(AppLifecycleState.paused, const Duration(hours: 1));

      expect(state().status, LockStatus.unlocked);
    });
  });

  group('enable', () {
    test('should_storeSaltedHashAndUnlock_when_pinChosen', () async {
      await loaded();

      await notifier().enable('4827');

      final config = repo.config;
      expect(config.lockEnabled, isTrue);
      expect(config.lockMethod, LockMethod.pin);
      expect(config.pinSalt, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(config.hashedPin, hashPin(config.pinSalt!, '4827'));
      expect(config.hashedPin, isNot(contains('4827')));
      expect(config.failedPinAttempts, 0);
      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isTrue);
      expect(state().biometricEnabled, isFalse);
    });

    test('should_readOnceAndWriteOnce_when_enabled', () async {
      await loaded();
      final readsBefore = repo.reads;

      await notifier().enable('4827');

      expect(repo.reads - readsBefore, 1);
      expect(repo.writes, 1);
    });

    test('should_useNewSaltAndHash_when_samePinSetTwice', () async {
      await loaded();

      await notifier().enable('4827');
      final first = repo.config;
      await notifier().disable('4827');
      await notifier().enable('4827');
      final second = repo.config;

      expect(second.pinSalt, isNot(first.pinSalt));
      expect(second.hashedPin, isNot(first.hashedPin));
    });

    test('should_unlockWithPin_when_enabledThenRestarted', () async {
      await loaded();
      await notifier().enable('4827');
      container.dispose();

      container = buildContainer();
      await loaded();

      expect(state().status, LockStatus.locked);
      expect((await notifier().unlockWithPin('4827')).isValid, isTrue);
    });

    test('should_leaveConfigUntouched_when_alreadyEnabled', () async {
      repo.config = lockedConfig();
      await loaded();
      final before = repo.config;

      await notifier().enable('9999');

      expect(repo.config, before);
      expect(repo.writes, 0);
    });

    test('should_keepFailureCount_when_enabled', () async {
      repo.config = const AppConfig(failedPinAttempts: 2);
      await loaded();

      await notifier().enable('4827');

      expect(repo.config.failedPinAttempts, 2);
    });

    for (final bad in ['', '123', '12345', 'abcd', '12a4', ' 123']) {
      test('should_throwWithoutPin_when_pinIs_"$bad"', () async {
        await loaded();

        await expectLater(
          notifier().enable(bad),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              isNot(contains(bad.isEmpty ? '\u0000' : bad)),
            ),
          ),
        );

        expect(repo.writes, 0);
      });
    }
  });

  group('disable', () {
    setUp(() async {
      repo.config = lockedConfig(method: LockMethod.biometric);
      await loaded();
      await notifier().unlockWithPin('1234');
    });

    test('should_eraseLock_when_currentPinRight', () async {
      final result = await notifier().disable('1234');

      expect(result.isValid, isTrue);
      expect(repo.config.lockEnabled, isFalse);
      expect(repo.config.lockMethod, isNull);
      expect(repo.config.hashedPin, isNull);
      expect(repo.config.pinSalt, isNull);
      expect(repo.config.failedPinAttempts, 0);
      expect(state().enabled, isFalse);
      expect(state().biometricEnabled, isFalse);
      expect(state().status, LockStatus.unlocked);
    });

    test('should_keepLockAndCount_when_currentPinWrong', () async {
      final result = await notifier().disable('0000');

      expect(result.isValid, isFalse);
      expect(result.attemptsLeft, 4);
      expect(repo.config.lockEnabled, isTrue);
      expect(repo.config.hashedPin, isNotNull);
      expect(repo.config.failedPinAttempts, 1);
      expect(state().enabled, isTrue);
    });

    test('should_readOnceAndWriteOnce_when_disabled', () async {
      final readsBefore = repo.reads;
      final writesBefore = repo.writes;

      await notifier().disable('1234');

      expect(repo.reads - readsBefore, 1);
      expect(repo.writes - writesBefore, 1);
    });

    test('should_signOut_when_fifthWrongCurrentPin', () async {
      for (var i = 0; i < 5; i++) {
        await notifier().disable('0000');
      }

      verify(authRepo.logout()).called(1);
      expect(repo.config.lockEnabled, isFalse);
    });
  });

  group('changePin', () {
    setUp(() async {
      repo.config = lockedConfig(failedPinAttempts: 2);
      await loaded();
      await notifier().unlockWithPin('1234');
    });

    test('should_replacePinWithNewSalt_when_currentPinRight', () async {
      final before = repo.config;

      final result = await notifier().changePin('1234', '5678');

      expect(result.isValid, isTrue);
      expect(repo.config.pinSalt, isNot(before.pinSalt));
      expect(repo.config.hashedPin, hashPin(repo.config.pinSalt!, '5678'));
      expect(repo.config.lockEnabled, isTrue);
      expect(repo.config.failedPinAttempts, 0);
    });

    test('should_acceptNewPinAndRefuseOld_when_changed', () async {
      await notifier().changePin('1234', '5678');

      expect((await notifier().verifyPin('1234')).isValid, isFalse);
      expect((await notifier().verifyPin('5678')).isValid, isTrue);
    });

    test('should_keepOldPinAndCount_when_currentPinWrong', () async {
      final before = repo.config;

      final result = await notifier().changePin('0000', '5678');

      expect(result.isValid, isFalse);
      expect(repo.config.hashedPin, before.hashedPin);
      expect(repo.config.pinSalt, before.pinSalt);
      expect(repo.config.failedPinAttempts, 1);
    });

    test('should_keepBiometric_when_pinChanged', () async {
      await notifier().setBiometricEnabled(enabled: true);

      await notifier().changePin('1234', '5678');

      expect(repo.config.lockMethod, LockMethod.biometric);
      expect(state().biometricEnabled, isTrue);
    });

    test('should_throwAndWriteNothing_when_newPinMalformed', () async {
      final writesBefore = repo.writes;

      await expectLater(
        notifier().changePin('1234', '12'),
        throwsArgumentError,
      );

      expect(repo.writes, writesBefore);
    });
  });

  group('setBiometricEnabled', () {
    setUp(() async {
      repo.config = lockedConfig();
      await loaded();
      await notifier().unlockWithPin('1234');
    });

    test('should_enable_when_biometricAuthenticationSucceeds', () async {
      final changed = await notifier().setBiometricEnabled(enabled: true);

      expect(changed, isTrue);
      expect(biometrics.authenticateCalls, 1);
      expect(repo.config.lockMethod, LockMethod.biometric);
      expect(state().biometricEnabled, isTrue);
    });

    test('should_notEnable_when_biometricAuthenticationFails', () async {
      biometrics.succeeds = false;
      final writesBefore = repo.writes;

      final changed = await notifier().setBiometricEnabled(enabled: true);

      expect(changed, isFalse);
      expect(repo.config.lockMethod, LockMethod.pin);
      expect(repo.writes, writesBefore);
      expect(state().biometricEnabled, isFalse);
    });

    test('should_disableWithoutAsking_when_turnedOff', () async {
      await notifier().setBiometricEnabled(enabled: true);
      biometrics.authenticateCalls = 0;

      final changed = await notifier().setBiometricEnabled(enabled: false);

      expect(changed, isTrue);
      expect(biometrics.authenticateCalls, 0);
      expect(repo.config.lockMethod, LockMethod.pin);
      expect(state().biometricEnabled, isFalse);
    });

    test('should_refuse_when_lockDisabled', () async {
      await notifier().disable('1234');
      biometrics.authenticateCalls = 0;

      final changed = await notifier().setBiometricEnabled(enabled: true);

      expect(changed, isFalse);
      expect(biometrics.authenticateCalls, 0);
    });

    test('should_keepPin_when_biometricEnabled', () async {
      await notifier().setBiometricEnabled(enabled: true);

      expect(repo.config.hashedPin, isNotNull);
      expect((await notifier().verifyPin('1234')).isValid, isTrue);
    });
  });

  group('reset', () {
    test('should_eraseEverythingAndUnlock_when_lockEnabled', () async {
      repo.config = lockedConfig(
        method: LockMethod.biometric,
        failedPinAttempts: 3,
      );
      await loaded();

      await notifier().reset();

      expect(repo.config.lockEnabled, isFalse);
      expect(repo.config.lockMethod, isNull);
      expect(repo.config.hashedPin, isNull);
      expect(repo.config.pinSalt, isNull);
      expect(repo.config.failedPinAttempts, 0);
      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isFalse);
      expect(state().biometricEnabled, isFalse);
    });

    test('should_keepOtherSettings_when_reset', () async {
      repo.config = lockedConfig().copyWith(
        serverUrl: 'https://budget.example.com/api',
        language: 'en',
        onboardingCompleted: true,
      );
      await loaded();

      await notifier().reset();

      expect(repo.config.serverUrl, 'https://budget.example.com/api');
      expect(repo.config.language, 'en');
      expect(repo.config.onboardingCompleted, isTrue);
    });

    test('should_notWrite_when_nothingToErase', () async {
      await loaded();

      await notifier().reset();

      expect(repo.writes, 0);
      expect(state().status, LockStatus.unlocked);
    });

    test('should_changeStateAfterWrite_when_resetting', () async {
      repo.config = lockedConfig();
      await loaded();
      final gate = repo.writeGate = Completer<void>();

      final pending = notifier().reset();
      await pumpEventQueue();

      expect(state().status, LockStatus.locked);
      expect(repo.config.lockEnabled, isTrue);

      gate.complete();
      await pending;
      expect(state().status, LockStatus.unlocked);
      expect(repo.config.lockEnabled, isFalse);
    });

    test('should_unlockInMemory_when_writeFails', () async {
      repo.config = lockedConfig();
      await loaded();
      repo.writeError = Exception('disk full');

      await notifier().reset();

      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isFalse);
    });
  });

  group('unlockAfterLogin', () {
    test(
      'should_unlockWithoutTouchingConfig_when_signedInWithPassword',
      () async {
        repo.config = lockedConfig();
        await loaded();
        final before = repo.config;

        await notifier().unlockAfterLogin();

        expect(state().status, LockStatus.unlocked);
        expect(state().enabled, isTrue);
        expect(repo.config, before);
        expect(repo.writes, 0);
      },
    );

    test('should_waitForConfiguration_when_stillLoading', () async {
      repo.config = lockedConfig();

      await notifier().unlockAfterLogin();

      expect(state().status, LockStatus.unlocked);
      expect(state().enabled, isTrue);
    });
  });

  group('secrets', () {
    test('should_notExposePinSaltOrHash_when_stateIsPrinted', () async {
      await loaded();
      await notifier().enable('4827');

      final printed = [
        state().toString(),
        const PinCheckResult(isValid: false, attemptsLeft: 3).toString(),
      ].join(' ');

      expect(printed, isNot(contains('4827')));
      expect(printed, isNot(contains(repo.config.pinSalt!)));
      expect(printed, isNot(contains(repo.config.hashedPin!)));
    });
  });
}
