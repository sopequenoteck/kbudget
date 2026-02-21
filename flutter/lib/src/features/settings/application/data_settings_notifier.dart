import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/utils/env_config.dart';

class DataSettingsState {
  final DataMode dataMode;
  final String? serverUrl;
  final bool isLoading;
  final String? error;

  const DataSettingsState({
    this.dataMode = DataMode.local,
    this.serverUrl,
    this.isLoading = false,
    this.error,
  });

  DataSettingsState copyWith({
    DataMode? dataMode,
    String? serverUrl,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearServerUrl = false,
  }) {
    return DataSettingsState(
      dataMode: dataMode ?? this.dataMode,
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
    state = DataSettingsState(
      dataMode: config.dataMode,
      serverUrl: config.serverUrl,
    );
  }

  String? validateUrl(String url) {
    if (url.trim().isEmpty) {
      return "L'URL du serveur est requise";
    }
    final allowHttp = EnvConfig.isDev;
    if (!url.startsWith('https://') &&
        !(allowHttp && url.startsWith('http://'))) {
      return "L'URL doit commencer par https://";
    }
    return null;
  }

  Future<bool> checkConnectivity(String url) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.head(url);
      final isReachable =
          response.statusCode != null && response.statusCode! < 500;
      state = state.copyWith(
        isLoading: false,
        error: isReachable ? null : 'Serveur injoignable',
        clearError: isReachable,
      );
      return isReachable;
    } on DioException {
      state = state.copyWith(
        isLoading: false,
        error: 'Serveur injoignable',
      );
      return false;
    }
  }

  Future<void> saveServerUrl(String url) async {
    await _repository.setServerUrl(url);
    state = state.copyWith(serverUrl: url);
  }

  Future<void> switchDataMode(DataMode newMode) async {
    await _repository.setDataMode(newMode);
    state = state.copyWith(dataMode: newMode);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
