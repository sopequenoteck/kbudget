// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/onboarding/data/app_config_repository_impl.dart';

void main() {
  group('AppConfigRepositoryImpl language', () {
    late AppConfigRepositoryImpl repo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      repo = AppConfigRepositoryImpl();
    });

    test('should_returnNull_when_noLanguageStored', () async {
      expect(await repo.getLanguage(), isNull);
    });

    test('should_returnLanguage_when_stored', () async {
      await repo.setLanguage('fr');

      expect(await repo.getLanguage(), 'fr');
    });

    test('should_clearLanguage_when_setToNull', () async {
      await repo.setLanguage('fr');

      await repo.setLanguage(null);

      expect(await repo.getLanguage(), isNull);
    });

    test('should_keepOtherSettings_when_languageStored', () async {
      await repo.setServerUrl('https://budget.example.com/api');

      await repo.setLanguage('en');

      expect(await repo.getServerUrl(), 'https://budget.example.com/api');
      expect((await repo.getConfig()).language, 'en');
    });
  });

  group('AppConfigRepositoryImpl configuration state', () {
    late int deleteCalls;

    AppConfigRepositoryImpl buildRepo(Map<String, dynamic>? stored) {
      FlutterSecureStorage.setMockInitialValues({
        if (stored != null) 'app_config': jsonEncode(stored),
      });
      deleteCalls = 0;
      return AppConfigRepositoryImpl(
        deleteLegacyDatabase: () async => deleteCalls++,
      );
    }

    Future<Map<String, dynamic>> storedJson() async {
      final raw = await const FlutterSecureStorage().read(key: 'app_config');
      return jsonDecode(raw!) as Map<String, dynamic>;
    }

    test('should_returnNotConfigured_when_nothingStored', () async {
      final repo = buildRepo(null);

      final config = await repo.getConfig();

      expect(config.onboardingCompleted, isFalse);
      expect(config.serverUrl, isNull);
      expect(deleteCalls, 0);
    });

    test('should_returnConfigured_when_serverUrlAndOnboardingCompleted',
        () async {
      final repo = buildRepo({
        'serverUrl': 'https://budget.example.com/api',
        'onboardingCompleted': true,
      });

      expect(await repo.isOnboardingCompleted(), isTrue);
      expect(await repo.getServerUrl(), 'https://budget.example.com/api');
      expect(deleteCalls, 0);
    });

    test('should_returnNotConfigured_when_onboardingCompletedWithoutServerUrl',
        () async {
      final repo = buildRepo({'onboardingCompleted': true});

      expect(await repo.isOnboardingCompleted(), isFalse);
    });

    test('should_returnNotConfigured_when_serverUrlBlank', () async {
      final repo = buildRepo({
        'serverUrl': '   ',
        'onboardingCompleted': true,
      });

      expect(await repo.isOnboardingCompleted(), isFalse);
    });

    test('should_returnNotConfigured_when_legacyLocalModeStored', () async {
      final repo = buildRepo({
        'dataMode': 'local',
        'onboardingCompleted': true,
      });

      expect(await repo.isOnboardingCompleted(), isFalse);
    });

    test('should_returnNotConfigured_when_legacyLocalModeKeepsOldServerUrl',
        () async {
      final repo = buildRepo({
        'dataMode': 'local',
        'serverUrl': 'https://budget.example.com/api',
        'onboardingCompleted': true,
      });

      expect(await repo.isOnboardingCompleted(), isFalse);
    });

    test('should_deleteLegacyDatabaseOnce_when_legacyLocalModeStored',
        () async {
      final repo = buildRepo({
        'dataMode': 'local',
        'onboardingCompleted': true,
      });

      await repo.getConfig();
      await repo.getConfig();

      expect(deleteCalls, 1);
    });

    test('should_rewriteStoredConfigWithoutDataMode_when_legacyLocalModeStored',
        () async {
      final repo = buildRepo({
        'dataMode': 'local',
        'onboardingCompleted': true,
        'language': 'fr',
      });

      await repo.getConfig();

      final json = await storedJson();
      expect(json.containsKey('dataMode'), isFalse);
      expect(json['onboardingCompleted'], isFalse);
      expect(json['language'], 'fr');
    });

    test('should_keepConfigured_when_legacyServerModeWithServerUrl', () async {
      final repo = buildRepo({
        'dataMode': 'server',
        'serverUrl': 'https://budget.example.com/api',
        'onboardingCompleted': true,
      });

      final config = await repo.getConfig();

      expect(config.onboardingCompleted, isTrue);
      expect(config.serverUrl, 'https://budget.example.com/api');
      expect((await storedJson()).containsKey('dataMode'), isFalse);
    });

    test('should_returnNotConfigured_when_legacyServerModeWithoutServerUrl',
        () async {
      final repo = buildRepo({
        'dataMode': 'server',
        'onboardingCompleted': true,
      });

      expect(await repo.isOnboardingCompleted(), isFalse);
    });

    test('should_keepOtherSettings_when_legacyLocalModeStored', () async {
      final repo = buildRepo({
        'dataMode': 'local',
        'onboardingCompleted': true,
        'theme': 'dark',
        'language': 'en',
      });

      final config = await repo.getConfig();

      expect(config.theme, AppTheme.dark);
      expect(config.language, 'en');
    });
  });
}
