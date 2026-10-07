// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/utils/env_config.dart';

class DataSettingsState {
  final String? serverUrl;
  final bool isLoading;
  final String? error;

  const DataSettingsState({
    this.serverUrl,
    this.isLoading = false,
    this.error,
  });

  DataSettingsState copyWith({
    String? serverUrl,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearServerUrl = false,
  }) {
    return DataSettingsState(
      serverUrl: clearServerUrl ? null : (serverUrl ?? this.serverUrl),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final dataSettingsNotifierProvider =
    NotifierProvider<DataSettingsNotifier, DataSettingsState>(
  DataSettingsNotifier.new,
);

class DataSettingsNotifier extends Notifier<DataSettingsState> {
  @override
  DataSettingsState build() {
    _loadConfig();
    return const DataSettingsState();
  }

  AppConfigRepository get _repository =>
      ref.read(appConfigRepositoryProvider);

  Future<void> _loadConfig() async {
    final config = await _repository.getConfig();
    state = DataSettingsState(serverUrl: config.serverUrl);
  }

  String? validateUrl(String url) {
    final l10n = ref.read(appLocalizationsProvider);
    if (url.trim().isEmpty) {
      return l10n.settingsFormServerUrlRequired;
    }
    final allowHttp = EnvConfig.isDev;
    if (!url.startsWith('https://') &&
        !(allowHttp && url.startsWith('http://'))) {
      return l10n.settingsFormServerUrlHttpsRequired;
    }
    return null;
  }

  Future<bool> checkConnectivity(String url) async {
    final l10n = ref.read(appLocalizationsProvider);
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final healthUrl =
          url.endsWith('/') ? '${url}actuator/health' : '$url/actuator/health';
      final response = await dio.get(healthUrl);
      final isReachable =
          response.statusCode != null && response.statusCode! < 500;
      state = state.copyWith(
        isLoading: false,
        error: isReachable ? null : l10n.settingsFeedbackServerUnreachable,
        clearError: isReachable,
      );
      return isReachable;
    } on DioException catch (e) {
      final String errorMsg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = l10n.settingsFeedbackServerTimeout;
      } else if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        errorMsg = l10n.settingsFeedbackServerAccessDenied;
      } else if (e.response?.statusCode == 404) {
        errorMsg = l10n.settingsFeedbackServerNotFound;
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = l10n.errorsClientNetwork;
      } else {
        errorMsg = l10n.settingsFeedbackServerUnreachable;
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    }
  }

  Future<void> saveServerUrl(String url) async {
    await _repository.setServerUrl(url);
    state = state.copyWith(serverUrl: url);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
