// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/auth/application/app_lock_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:k_budget/src/features/auth/application/pin_hashing.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';

/// Number of digits of the PIN.
const pinLength = 4;

/// Wrong PIN entries in a row after which the user is signed out.
const maxPinAttempts = 5;

/// Time spent away from the app after which it locks again.
const lockGracePeriod = Duration(minutes: 1);

/// Time the app stays hidden after a sign-out from the lock screen, waiting
/// for the router to leave the screen that was covered. When it has passed
/// without the location changing, the router is sent to the sign-in screen and
/// the app stays hidden until the location changes: a stuck router is
/// unusable already, and showing data without the PIN would defeat the lock.
const lockHoldTimeout = Duration(seconds: 3);

final _pinFormat = RegExp(r'^\d{4}$');

/// The clock the lock uses to time the absence. Tests override it.
final lockClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Outcome of checking a PIN.
class PinCheckResult {
  /// Creates a result.
  const PinCheckResult({required this.isValid, required this.attemptsLeft});

  /// The PIN was right.
  final bool isValid;

  /// Wrong entries still allowed before the user is signed out. Meaningless
  /// when [isValid] is `true`.
  final int attemptsLeft;
}

/// The app lock. See `docs/architecture.md`, "Frontière Angular / Flutter".
final appLockNotifierProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);

/// Holds whether the app is locked and runs every operation of the lock.
///
/// The lock is reset (turned off, PIN erased) only where the tokens are
/// erased: `AuthNotifier.logout()` and
/// `DataSettingsNotifier.changeServerUrl()`. Never from
/// `forceUnauthenticated()` or a failed `checkAuth()`, which keep the tokens:
/// resetting there would let a session resume without PIN.
class AppLockNotifier extends Notifier<AppLockState> {
  late Future<void> _loading;
  var _active = true;
  var _readFailed = false;
  var _retrying = false;
  DateTime? _leftAt;

  @override
  AppLockState build() {
    _active = true;
    _readFailed = false;
    _leftAt = null;
    ref.onDispose(() => _active = false);
    _loading = _load();
    return const AppLockState();
  }

  AppConfigRepository get _repository => ref.read(appConfigRepositoryProvider);

  DateTime _now() => ref.read(lockClockProvider)();

  Future<void> _load() async {
    final loaded = await _readInitialState();
    if (_active && state.status == LockStatus.unknown) {
      state = loaded;
    }
  }

  Future<AppLockState> _readInitialState() async {
    try {
      final config = await _repository.getConfig();
      _readFailed = false;
      return _stateOf(config);
    } on Object {
      // Any failure, an Error such as a TypeError from a malformed JSON
      // included. The tokens live in the same secure storage: an unreadable
      // configuration goes with an unreadable session, which the barrier does
      // not cover. Staying unknown would hide the app for good. The read is
      // tried again when the app comes back (see [onLifecycleChanged]).
      _readFailed = true;
      return const AppLockState(status: LockStatus.unlocked);
    }
  }

  AppLockState _stateOf(AppConfig config) => AppLockState(
        status: config.lockEnabled ? LockStatus.locked : LockStatus.unlocked,
        enabled: config.lockEnabled,
        biometricEnabled: _biometricOf(config),
      );

  // After a failed first read the app runs unlocked, even if a lock is stored.
  // Read again: if the lock is there, lock now.
  Future<void> _retryRead() async {
    if (_retrying) {
      return;
    }
    _retrying = true;
    try {
      final config = await _repository.getConfig();
      if (!_active || !_readFailed) {
        return;
      }
      _readFailed = false;
      if (config.lockEnabled) {
        state = _stateOf(config);
      }
    } on Object {
      // Still unreadable: stay as is, and try again at the next return.
    } finally {
      _retrying = false;
    }
  }

  bool _biometricOf(AppConfig config) =>
      config.lockEnabled && config.lockMethod == LockMethod.biometric;

  /// Reacts to the app going to the background or coming back.
  ///
  /// The time is taken on `paused` and `hidden`, not on `inactive`: the
  /// Face ID sheet and the control center make the app inactive without
  /// leaving it. Coming back, the app locks if it was away at least
  /// [lockGracePeriod], or if the clock went backwards. If the configuration
  /// could not be read at launch, it is read again on each return until it
  /// can be, and the app locks if a lock is stored.
  void onLifecycleChanged(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _leftAt ??= _now();
      case AppLifecycleState.resumed:
        final leftAt = _leftAt;
        _leftAt = null;
        if (leftAt != null && _shouldLockAfter(leftAt)) {
          state = state.copyWith(status: LockStatus.locked);
        }
        if (_readFailed) {
          unawaited(_retryRead());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  bool _shouldLockAfter(DateTime leftAt) {
    if (!state.enabled || state.status != LockStatus.unlocked) {
      return false;
    }
    final away = _now().difference(leftAt);
    return away.isNegative || away >= lockGracePeriod;
  }

  /// Unlocks with [pin]. A wrong PIN is counted before the result is
  /// returned; the [maxPinAttempts]th one signs the user out.
  Future<PinCheckResult> unlockWithPin(String pin) async {
    final result = await _checkPin(pin, (config) => config);
    if (result.isValid) {
      state = state.copyWith(status: LockStatus.unlocked);
    }
    return result;
  }

  /// Unlocks with the device biometrics. Does nothing when biometric unlock
  /// is off. A failure is not counted: the system has its own limit.
  Future<bool> unlockWithBiometrics() async {
    if (!state.biometricEnabled) {
      return false;
    }
    final unlocked = await _authenticateWithBiometrics();
    if (unlocked) {
      state = state.copyWith(status: LockStatus.unlocked);
    }
    return unlocked;
  }

  Future<bool> _authenticateWithBiometrics() => ref
      .read(biometricAuthenticatorProvider)
      .authenticate(
        ref.read(appLocalizationsProvider).authActionUnlockBiometricReason,
      );

  /// Checks [pin] against the stored one, counting a wrong entry. Shared by
  /// every place that asks for the current PIN, so none of them can be used
  /// to guess it.
  Future<PinCheckResult> verifyPin(String pin) =>
      _checkPin(pin, (config) => config);

  /// Turns the lock on with [pin], PIN only. Does nothing if it is on.
  ///
  /// Throws an [ArgumentError] if [pin] is not [pinLength] digits.
  Future<void> enable(String pin) async {
    _requirePinFormat(pin);
    final config = await _repository.getConfig();
    if (config.lockEnabled) {
      return;
    }
    final updated = _withNewPin(
      config,
      pin,
    ).copyWith(lockEnabled: true, lockMethod: LockMethod.pin);
    await _repository.saveConfig(updated);
    _readFailed = false;
    state = const AppLockState(status: LockStatus.unlocked, enabled: true);
  }

  /// Turns the lock off after checking [currentPin].
  Future<PinCheckResult> disable(String currentPin) async {
    final result = await _checkPin(
      currentPin,
      (config) => config.copyWith(
        lockEnabled: false,
        lockMethod: null,
        hashedPin: null,
        pinSalt: null,
      ),
    );
    if (result.isValid) {
      state = const AppLockState(status: LockStatus.unlocked);
    }
    return result;
  }

  /// Replaces the PIN by [newPin] after checking [currentPin]. A new salt is
  /// generated.
  ///
  /// Throws an [ArgumentError] if [newPin] is not [pinLength] digits.
  Future<PinCheckResult> changePin(String currentPin, String newPin) async {
    _requirePinFormat(newPin);
    final result = await _checkPin(
      currentPin,
      (config) => _withNewPin(config, newPin),
    );
    return result;
  }

  /// Turns biometric unlock on or off. Turning it on requires a successful
  /// biometric authentication. Returns whether the setting changed.
  Future<bool> setBiometricEnabled({required bool enabled}) async {
    if (!state.enabled) {
      return false;
    }
    if (enabled && !await _authenticateWithBiometrics()) {
      return false;
    }
    final config = await _repository.getConfig();
    if (!config.lockEnabled) {
      return false;
    }
    await _repository.saveConfig(
      config.copyWith(
        lockMethod: enabled ? LockMethod.biometric : LockMethod.pin,
      ),
    );
    state = state.copyWith(biometricEnabled: enabled);
    return true;
  }

  /// Turns the lock off and erases the PIN, its salt and the failure count.
  ///
  /// To be called only once the tokens are erased. The configuration is
  /// written before the state changes, so an observer never sees an unlocked
  /// app while the lock is still stored.
  Future<void> reset() async {
    try {
      final config = await _repository.getConfig();
      final cleared = config.copyWith(
        lockEnabled: false,
        lockMethod: null,
        hashedPin: null,
        pinSalt: null,
        failedPinAttempts: 0,
      );
      if (cleared != config) {
        await _repository.saveConfig(cleared);
      }
    } on Object {
      // The tokens are gone, the session is over: the app must not stay
      // locked in memory. A lock that could not be erased stays on disk, and
      // "Forgot PIN" remains the way out.
    }
    _leftAt = null;
    _readFailed = false;
    state = const AppLockState(status: LockStatus.unlocked);
  }

  /// Unlocks after a successful sign-in with the password, which proves more
  /// than the PIN. The lock settings are left as they are.
  Future<void> unlockAfterLogin() async {
    await _loading;
    state = state.copyWith(status: LockStatus.unlocked);
  }

  void _requirePinFormat(String pin) {
    if (!_pinFormat.hasMatch(pin)) {
      throw ArgumentError('The PIN must be $pinLength digits.');
    }
  }

  AppConfig _withNewPin(AppConfig config, String pin) {
    final salt = generatePinSalt();
    return config.copyWith(hashedPin: hashPin(salt, pin), pinSalt: salt);
  }

  /// One read, one write. A right [pin] writes the config returned by
  /// [onValid] with the failure count at zero. A wrong one writes the
  /// incremented count, and that write is awaited before the result is
  /// returned. At [maxPinAttempts] the user is signed out.
  Future<PinCheckResult> _checkPin(
    String pin,
    AppConfig Function(AppConfig config) onValid,
  ) async {
    final config = await _repository.getConfig();
    final salt = config.pinSalt;
    final hash = config.hashedPin;
    if (salt == null || hash == null) {
      // No PIN is stored (the lock is off, or the configuration is broken):
      // nothing to check, so nothing to count and nothing to write.
      return PinCheckResult(
        isValid: false,
        attemptsLeft: max(0, maxPinAttempts - config.failedPinAttempts),
      );
    }
    if (constantTimeEquals(hashPin(salt, pin), hash)) {
      final updated = onValid(config).copyWith(failedPinAttempts: 0);
      if (updated != config) {
        await _repository.saveConfig(updated);
      }
      _syncFlags(updated);
      return const PinCheckResult(isValid: true, attemptsLeft: maxPinAttempts);
    }
    final failures = config.failedPinAttempts + 1;
    await _repository.saveConfig(config.copyWith(failedPinAttempts: failures));
    if (failures >= maxPinAttempts) {
      await _signOut();
    }
    return PinCheckResult(
      isValid: false,
      attemptsLeft: max(0, maxPinAttempts - failures),
    );
  }

  void _syncFlags(AppConfig config) {
    state = state.copyWith(
      enabled: config.lockEnabled,
      biometricEnabled: _biometricOf(config),
    );
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authNotifierProvider.notifier).logout();
    } on Exception {
      // The tokens could not be erased, so the lock stays: the count stays at
      // the limit and the next wrong PIN tries again.
    }
  }
}
