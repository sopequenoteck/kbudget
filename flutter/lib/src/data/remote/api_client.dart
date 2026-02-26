import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/utils/env_config.dart';

/// Dio brut sans intercepteurs d'auth.
/// Utilisé pour les appels publics (health check, etc.).
/// Pour les appels authentifiés, utiliser [authenticatedDioProvider]
/// dans data_mode_provider.dart.
final apiClientProvider = FutureProvider<Dio>((ref) async {
  final configRepo = ref.watch(appConfigRepositoryProvider);
  final serverUrl = await configRepo.getServerUrl();
  final baseUrl = serverUrl ?? EnvConfig.apiBaseUrl;

  return Dio(BaseOptions(
    baseUrl: baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
});

/// Checks API health/version on first successful call.
/// Warns if the server is unreachable or returns an unexpected version.
Future<bool> checkApiHealth(Dio dio) async {
  try {
    final response = await dio.get<Map<String, dynamic>>(
      '/actuator/health',
      options: Options(
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final status = response.data?['status'] as String?;
    return status == 'UP';
  } on DioException catch (e) {
    debugPrint('API health check failed: ${e.message}');
    return false;
  }
}
