// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:k_budget/src/features/auth/application/pin_hashing.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:mockito/mockito.dart';

import 'display_locale.dart';
import 'fake_app_config_repository.dart';
import 'mocks.mocks.dart';

/// A salt that tests can recognize.
const testPinSalt = '0123456789abcdef0123456789abcdef';

/// A configuration with the lock turned on and [pin] as its PIN.
AppConfig lockedConfig({
  String pin = '1234',
  int failedPinAttempts = 0,
  LockMethod method = LockMethod.pin,
}) => AppConfig(
  lockEnabled: true,
  lockMethod: method,
  hashedPin: hashPin(testPinSalt, pin),
  pinSalt: testPinSalt,
  failedPinAttempts: failedPinAttempts,
);

/// A [BiometricAuthenticator] whose answers the test decides.
class FakeBiometricAuthenticator implements BiometricAuthenticator {
  /// Creates the fake, with biometrics available as [kind] by default.
  FakeBiometricAuthenticator({
    this.kind = BiometricKind.fingerprint,
    this.succeeds = true,
  });

  /// What `availableKind` returns.
  BiometricKind? kind;

  /// What `authenticate` returns.
  bool succeeds;

  /// Number of `authenticate` calls.
  var authenticateCalls = 0;

  /// The reason of the last `authenticate` call.
  String? lastReason;

  @override
  Future<BiometricKind?> availableKind() async => kind;

  @override
  Future<bool> authenticate(String reason) async {
    authenticateCalls++;
    lastReason = reason;
    return succeeds;
  }
}

/// The pieces a lock test plugs into a `ProviderContainer`.
class LockHarness {
  /// Creates the harness. [config] is what the device stores.
  LockHarness({
    AppConfig? config,
    BiometricKind? kind = BiometricKind.fingerprint,
  }) : repo = FakeAppConfigRepository(config ?? lockedConfig()),
       authRepo = MockAuthRepository(),
       biometrics = FakeBiometricAuthenticator(kind: kind) {
    when(authRepo.logout()).thenAnswer((_) async {});
  }

  /// The stored configuration.
  final FakeAppConfigRepository repo;

  /// The authentication repository behind `AuthNotifier`.
  final MockAuthRepository authRepo;

  /// The device biometrics.
  final FakeBiometricAuthenticator biometrics;

  /// The time the lock sees.
  DateTime now = DateTime(2026, 1, 1, 12);

  /// The overrides that wire the harness in.
  List<Override> get overrides => [
    displayLocaleOverride(),
    appConfigRepositoryProvider.overrideWithValue(repo),
    authRepositoryProvider.overrideWith((_) async => authRepo),
    biometricAuthenticatorProvider.overrideWithValue(biometrics),
    lockClockProvider.overrideWithValue(() => now),
  ];
}
