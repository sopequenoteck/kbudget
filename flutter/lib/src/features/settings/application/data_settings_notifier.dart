// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/data/remote/compatibility_provider.dart';
import 'package:k_budget/src/data/remote/compatibility_service.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/env_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Switches the app to the server at [url] and signs the user out.
  ///
  /// The server is checked first, like on first launch. If it is offline or
  /// incompatible, nothing changes (URL and tokens untouched), the error is
  /// set on the state and `false` is returned. Otherwise the tokens of the
  /// previous instance are cleared before the URL changes, so they never
  /// reach the new host, and the router is sent back to the sign-in screen.
  Future<bool> changeServerUrl(String url) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final l10n = ref.read(appLocalizationsProvider);
    try {
      return await _switchServer(url, l10n);
    } finally {
      // An unexpected failure must not leave the save button disabled.
      if (state.isLoading) {
        state = state.copyWith(
          isLoading: false,
          error: l10n.commonFeedbackSaveError,
        );
      }
    }
  }

  Future<bool> _switchServer(String url, AppLocalizations l10n) async {
    final info = await PackageInfo.fromPlatform();
    final status = await ref
        .read(compatibilityServiceProvider)
        .check(baseUrl: url, clientVersion: info.version);
    final message = status.userMessage(l10n);
    if (message != null) {
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }

    var tokensCleared = false;
    try {
      final authRepository = await ref.read(authRepositoryProvider.future);
      final refreshToken = await authRepository.getRefreshToken();
      // Taken before the invalidation below: it holds the old instance's Dio.
      final dataSource = await ref.read(authRemoteDataSourceProvider.future);
      await authRepository.clearTokens();
      tokensCleared = true;
      if (refreshToken != null) {
        unawaited(_revokeOnPreviousServer(dataSource, refreshToken));
      }
      await _repository.setServerUrl(url);
    } on Exception {
      state = state.copyWith(
        isLoading: false,
        error: l10n.commonFeedbackSaveError,
      );
      if (tokensCleared) {
        // The tokens are already gone: keep the auth state consistent.
        ref.read(authNotifierProvider.notifier).forceUnauthenticated();
      }
      return false;
    }

    ref.read(compatibilityNotifierProvider.notifier).reset();
    ref.invalidate(apiClientProvider);
    state = DataSettingsState(serverUrl: url);
    // Last: the router redirects to sign-in and must see the new URL.
    ref.read(authNotifierProvider.notifier).forceUnauthenticated();
    return true;
  }

  Future<void> _revokeOnPreviousServer(
    AuthRemoteDataSource dataSource,
    String refreshToken,
  ) async {
    try {
      await dataSource.logout(refreshToken);
    } on Exception {
      // Best effort: the previous instance may be unreachable.
    }
  }
}
