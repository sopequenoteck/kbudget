import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';

void main() {
  group('AppConfig lock fields', () {
    test('should_defaultToNoSaltAndZeroFailures_when_createdEmpty', () {
      const config = AppConfig();

      expect(config.pinSalt, isNull);
      expect(config.failedPinAttempts, 0);
    });

    test('should_readDefaults_when_configWrittenBeforeTheLock', () {
      final config = AppConfig.fromJson({
        'serverUrl': 'https://budget.example.com/api',
        'lockEnabled': false,
        'onboardingCompleted': true,
      });

      expect(config.pinSalt, isNull);
      expect(config.failedPinAttempts, 0);
      expect(config.serverUrl, 'https://budget.example.com/api');
    });

    test('should_roundTripLockFields_when_serialized', () {
      const config = AppConfig(
        lockEnabled: true,
        lockMethod: LockMethod.biometric,
        hashedPin: 'hash',
        pinSalt: 'salt',
        failedPinAttempts: 3,
      );

      final restored = AppConfig.fromJson(config.toJson());

      expect(restored, config);
      expect(restored.pinSalt, 'salt');
      expect(restored.failedPinAttempts, 3);
    });

    test('should_ignoreUnknownKeys_when_readByThisVersion', () {
      final config = AppConfig.fromJson({'somethingNew': 1});

      expect(config, const AppConfig());
    });
  });

  group('AppConfig.toString', () {
    test('should_notPrintHashOrSalt_when_converted', () {
      const config = AppConfig(
        lockEnabled: true,
        lockMethod: LockMethod.pin,
        hashedPin: 'secret-hash-value',
        pinSalt: 'secret-salt-value',
        failedPinAttempts: 2,
      );

      final printed = config.toString();

      expect(printed, isNot(contains('secret-hash-value')));
      expect(printed, isNot(contains('secret-salt-value')));
      expect(printed, contains('lockEnabled: true'));
      expect(printed, contains('failedPinAttempts: 2'));
    });
  });
}
