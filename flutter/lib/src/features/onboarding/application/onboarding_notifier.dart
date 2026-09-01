import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/compatibility_service.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_state.dart';
import 'package:k_budget/src/features/onboarding/data/app_config_repository_impl.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  /// Valide l'URL saisie via `/api/meta` (KKS-314).
  ///
  /// Remplace l'ancien `HEAD` sur l'URL brute, qui acceptait tout
  /// statut < 500 :
  /// n'importe quel serveur web passait ce test, y compris une box internet ou
  /// une page d'erreur de reverse proxy. Interroger `/meta` prouve a la
  /// fois que
  /// le serveur repond, qu'il s'agit bien d'une instance K-Budget, et que sa
  /// version est exploitable par cette application.
  Future<bool> checkServerConnectivity(String url) async {
    state = state.copyWith(isCheckingServer: true, error: null);

    final info = await PackageInfo.fromPlatform();
    final status = await ref
        .read(compatibilityServiceProvider)
        .check(baseUrl: url, clientVersion: info.version);

    final message = status.userMessage();

    state = state.copyWith(
      isCheckingServer: false,
      isServerReachable: message == null,
      error: message,
    );
    return message == null;
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
