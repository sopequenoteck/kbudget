import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  final FlutterSecureStorage _storage;

  static const _configKey = 'app_config';

  AppConfigRepositoryImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<AppConfig> getConfig() async {
    final json = await _storage.read(key: _configKey);
    if (json == null) {
      return const AppConfig(dataMode: DataMode.local);
    }
    return AppConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
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
  Future<DataMode> getDataMode() async {
    final config = await getConfig();
    return config.dataMode;
  }

  @override
  Future<void> setDataMode(DataMode mode) async {
    final config = await getConfig();
    await saveConfig(config.copyWith(dataMode: mode));
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
}
