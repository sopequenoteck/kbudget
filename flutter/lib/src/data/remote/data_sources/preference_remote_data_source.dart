// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_response.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';

class PreferenceRemoteDataSource {
  final Dio _dio;

  PreferenceRemoteDataSource(this._dio);

  Future<UserPreferenceResponse>? _readInFlight;

  /// Concurrent callers share one request; nothing is kept once it completes.
  Future<UserPreferenceResponse> getPreferences() => _readInFlight ??=
      _getPreferences().whenComplete(() => _readInFlight = null);

  Future<UserPreferenceResponse> _getPreferences() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/users/me/preferences');
    return UserPreferenceResponse.fromJson(response.data!);
  }

  Future<UserPreferenceResponse> updatePreferences(
      UserPreferenceRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/users/me/preferences',
      data: request.toJson(),
    );
    return UserPreferenceResponse.fromJson(response.data!);
  }

  /// Resets the language preference to `null` (automatic).
  Future<void> clearLanguage() async {
    await _dio.delete<void>('/users/me/preferences/language');
  }
}

final preferenceRemoteDataSourceProvider =
    FutureProvider<PreferenceRemoteDataSource>((ref) async {
  // Chaque session a sa propre instance, donc sa propre lecture en vol
  // (KKS-562) : sinon un compte recevrait la reponse du precedent. Pas de
  // `ref.watch` : lu pour la premiere fois depuis un `ref.listen` de
  // connexion, le fournisseur resterait en chargement a jamais.
  ref.listen(authNotifierProvider, (_, _) => ref.invalidateSelf());
  final dio = await ref.watch(authenticatedDioProvider.future);
  return PreferenceRemoteDataSource(dio);
});
