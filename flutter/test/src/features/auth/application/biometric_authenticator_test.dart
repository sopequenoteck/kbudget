import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../helpers/lock_test_helpers.dart';

class _FakeLocalAuth extends Fake implements LocalAuthentication {
  List<BiometricType> types = const [];
  Object? error;
  bool result = true;
  String? reason;
  AuthenticationOptions? options;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return types;
  }

  // `authenticate` takes a type that `local_auth` does not export, so it is
  // answered through `noSuchMethod`.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #authenticate) {
      return super.noSuchMethod(invocation);
    }
    reason = invocation.namedArguments[#localizedReason] as String?;
    options = invocation.namedArguments[#options] as AuthenticationOptions?;
    final failure = error;
    if (failure != null) {
      return Future<bool>.error(failure);
    }
    return Future<bool>.value(result);
  }
}

void main() {
  late _FakeLocalAuth plugin;
  late LocalAuthBiometricAuthenticator authenticator;

  setUp(() {
    plugin = _FakeLocalAuth();
    authenticator = LocalAuthBiometricAuthenticator(auth: plugin);
  });

  group('availableKind', () {
    test('should_returnFace_when_faceEnrolled', () async {
      plugin.types = [BiometricType.fingerprint, BiometricType.face];

      expect(await authenticator.availableKind(), BiometricKind.face);
    });

    test('should_returnFingerprint_when_onlyFingerprintEnrolled', () async {
      plugin.types = [BiometricType.fingerprint];

      expect(await authenticator.availableKind(), BiometricKind.fingerprint);
    });

    test('should_returnFingerprint_when_onlyStrongBiometricEnrolled', () async {
      plugin.types = [BiometricType.strong];

      expect(await authenticator.availableKind(), BiometricKind.fingerprint);
    });

    test('should_returnNull_when_nothingEnrolled', () async {
      expect(await authenticator.availableKind(), isNull);
    });

    test('should_returnNull_when_pluginMissing', () async {
      plugin.error = MissingPluginException();

      expect(await authenticator.availableKind(), isNull);
    });

    test('should_returnNull_when_platformFails', () async {
      plugin.error = PlatformException(code: 'NotAvailable');

      expect(await authenticator.availableKind(), isNull);
    });
  });

  group('authenticate', () {
    test(
      'should_returnTrueWithBiometricOnlyOptions_when_userAuthenticates',
      () async {
        final ok = await authenticator.authenticate('Unlock K-Budget');

        expect(ok, isTrue);
        expect(plugin.reason, 'Unlock K-Budget');
        expect(plugin.options?.biometricOnly, isTrue);
        expect(plugin.options?.stickyAuth, isTrue);
      },
    );

    test('should_returnFalse_when_userFails', () async {
      plugin.result = false;

      expect(await authenticator.authenticate('x'), isFalse);
    });

    test('should_returnFalse_when_platformFails', () async {
      plugin.error = PlatformException(code: 'LockedOut');

      expect(await authenticator.authenticate('x'), isFalse);
    });

    test('should_returnFalse_when_pluginMissing', () async {
      plugin.error = MissingPluginException();

      expect(await authenticator.authenticate('x'), isFalse);
    });
  });

  group('providers', () {
    test('should_useLocalAuth_when_notOverridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(biometricAuthenticatorProvider),
        isA<LocalAuthBiometricAuthenticator>(),
      );
    });

    test('should_exposeKind_when_biometricsAvailable', () async {
      final container = ProviderContainer(
        overrides: [
          biometricAuthenticatorProvider.overrideWithValue(
            FakeBiometricAuthenticator(kind: BiometricKind.face),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(biometricKindProvider.future),
        BiometricKind.face,
      );
    });

    test('should_exposeNull_when_biometricsUnavailable', () async {
      final container = ProviderContainer(
        overrides: [
          biometricAuthenticatorProvider.overrideWithValue(
            FakeBiometricAuthenticator(kind: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(biometricKindProvider.future), isNull);
    });
  });
}
