// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// The kind of biometric available on the device, to pick the key icon.
enum BiometricKind {
  /// Face recognition.
  face,

  /// Fingerprint, or any other biometric.
  fingerprint,
}

/// What the lock needs from the device biometrics.
///
/// Behind an interface so that no widget or notifier touches the
/// `local_auth` plugin, which is missing on web and desktop.
abstract class BiometricAuthenticator {
  /// The kind of biometric that can be used right now, or `null` when the
  /// hardware is missing, nothing is enrolled, or the platform has no
  /// biometrics.
  Future<BiometricKind?> availableKind();

  /// Asks the system to authenticate the user with a biometric, showing
  /// [reason]. Returns `false` when it fails, is cancelled or is not
  /// possible: the PIN remains the fallback.
  Future<bool> authenticate(String reason);
}

/// [BiometricAuthenticator] backed by the `local_auth` plugin.
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  /// Creates the authenticator. [auth] is only replaceable for tests.
  LocalAuthBiometricAuthenticator({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricKind?> availableKind() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) {
        return null;
      }
      return types.contains(BiometricType.face)
          ? BiometricKind.face
          : BiometricKind.fingerprint;
    } on Exception {
      // Includes MissingPluginException on platforms without the plugin.
      return null;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on Exception {
      return false;
    }
  }
}

/// The device biometrics. Tests override it with a fake.
final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => LocalAuthBiometricAuthenticator(),
);

/// The biometric kind available on this device, `null` when none.
final AutoDisposeFutureProvider<BiometricKind?> biometricKindProvider =
    FutureProvider.autoDispose<BiometricKind?>(
      (ref) => ref.watch(biometricAuthenticatorProvider).availableKind(),
    );
