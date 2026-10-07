// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/onboarding/data/legacy_local_database.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  final FlutterSecureStorage _storage;
  final Future<void> Function() _deleteLegacyDatabase;

  static const _configKey = 'app_config';

  // Champ des configurations enregistrees avant KKS-335, quand l'application
  // pouvait tourner sans serveur (valeurs `local` / `server`).
  static const _legacyDataModeKey = 'dataMode';
  static const _legacyLocalMode = 'local';

  AppConfigRepositoryImpl({
    FlutterSecureStorage? storage,
    Future<void> Function()? deleteLegacyDatabase,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _deleteLegacyDatabase =
            deleteLegacyDatabase ?? deleteLegacyLocalDatabase;

  /// Lit la configuration. Une configuration sans serveur, ou enregistree en
  /// ancien mode local, est renvoyee comme non configuree
  /// (`onboardingCompleted == false`) : l'application repart sur la
  /// configuration du serveur. Une ancienne configuration est reecrite sans
  /// `dataMode` et la base locale devenue orpheline est effacee, une seule fois.
  @override
  Future<AppConfig> getConfig() async {
    final raw = await _storage.read(key: _configKey);
    if (raw == null) {
      return const AppConfig();
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final stored = AppConfig.fromJson(json);
    final hasServer = stored.serverUrl?.trim().isNotEmpty ?? false;
    final isLegacyLocal = json[_legacyDataModeKey] == _legacyLocalMode;
    final config = hasServer && !isLegacyLocal
        ? stored
        : stored.copyWith(onboardingCompleted: false);

    if (json.containsKey(_legacyDataModeKey)) {
      await saveConfig(config);
      await _deleteLegacyDatabase();
    }
    return config;
  }

  @override
  Future<void> saveConfig(AppConfig config) async {
    await _storage.write(key: _configKey, value: jsonEncode(config.toJson()));
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final config = await getConfig();
    return config.onboardingCompleted;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(onboardingCompleted: completed));
  }

  @override
  Future<void> setServerUrl(String url) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(serverUrl: url));
  }

  @override
  Future<String?> getServerUrl() async {
    final config = await getConfig();
    return config.serverUrl;
  }

  @override
  Future<void> setTheme(AppTheme theme) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(theme: theme));
  }

  @override
  Future<AppTheme> getTheme() async {
    final config = await getConfig();
    return config.theme;
  }

  @override
  Future<void> setTextScale(TextScale textScale) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(textScale: textScale));
  }

  @override
  Future<TextScale> getTextScale() async {
    final config = await getConfig();
    return config.textScale;
  }

  @override
  Future<void> setLockEnabled(bool enabled) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(lockEnabled: enabled));
  }

  @override
  Future<void> setLockMethod(LockMethod? method) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(lockMethod: method));
  }

  @override
  Future<void> setHashedPin(String? pin) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(hashedPin: pin));
  }

  @override
  Future<List<Feature>> getEnabledFeatures() async {
    final config = await getConfig();
    return config.enabledFeatures;
  }

  @override
  Future<void> setEnabledFeatures(List<Feature> features) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(enabledFeatures: features));
  }

  @override
  Future<List<Feature>> getNavOrder() async {
    final config = await getConfig();
    return config.navOrder;
  }

  @override
  Future<void> setNavOrder(List<Feature> order) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(navOrder: order));
  }

  @override
  Future<String?> getLanguage() async {
    final config = await getConfig();
    return config.language;
  }

  @override
  Future<void> setLanguage(String? language) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(language: language));
  }
}
