import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_state.dart';
import 'package:k_budget/src/features/onboarding/data/app_config_repository_impl.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepositoryImpl();
});

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  AppConfigRepository get _repository =>
      ref.read(appConfigRepositoryProvider);

  Future<bool> isOnboardingCompleted() async {
    return _repository.isOnboardingCompleted();
  }

  void selectMode(DataMode mode) {
    state = state.copyWith(selectedMode: mode, error: null);
  }

  void setServerUrl(String url) {
    state = state.copyWith(serverUrl: url, error: null);
  }

  Future<bool> checkServerConnectivity(String url) async {
    state = state.copyWith(isCheckingServer: true, error: null);
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.head(url);
      final isReachable =
          response.statusCode != null && response.statusCode! < 500;
      state = state.copyWith(
        isCheckingServer: false,
        isServerReachable: isReachable,
        error: isReachable ? null : 'Serveur injoignable',
      );
      return isReachable;
    } on DioException {
      state = state.copyWith(
        isCheckingServer: false,
        isServerReachable: false,
        error: 'Serveur injoignable',
      );
      return false;
    }
  }

  Future<AppConfig> getConfig() async {
    return _repository.getConfig();
  }

  Future<void> updateLockSettings({
    required bool enabled,
    LockMethod? method,
    String? pin,
  }) async {
    await _repository.setLockEnabled(enabled);
    await _repository.setLockMethod(method);
    await _repository.setHashedPin(pin);
  }

  Future<void> completeOnboarding() async {
    final mode = state.selectedMode;
    if (mode == null) return;

    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repository.setDataMode(mode);
      if (mode == DataMode.server && state.serverUrl != null) {
        await _repository.setServerUrl(state.serverUrl!);
      }
      await _repository.setOnboardingCompleted(true);
      state = state.copyWith(isSaving: false, isCompleted: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erreur lors de la sauvegarde: $e',
      );
    }
  }
}
