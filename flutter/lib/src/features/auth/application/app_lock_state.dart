// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_lock_state.freezed.dart';

/// Where the app lock stands.
enum LockStatus {
  /// The configuration is not read yet: nothing may be shown.
  unknown,

  /// The app is locked, a PIN (or biometric) is required.
  locked,

  /// The app is unlocked, or no lock is set.
  unlocked,
}

/// State of the app lock. It never holds the PIN, its salt or its hash.
@freezed
class AppLockState with _$AppLockState {
  /// Creates the state. Before the configuration is read, the lock is
  /// [LockStatus.unknown].
  const factory AppLockState({
    /// Whether the app is locked, unlocked, or not known yet.
    @Default(LockStatus.unknown) LockStatus status,

    /// The lock is turned on in the settings.
    @Default(false) bool enabled,

    /// Biometric unlock is turned on, on top of the PIN.
    @Default(false) bool biometricEnabled,
  }) = _AppLockState;
}
