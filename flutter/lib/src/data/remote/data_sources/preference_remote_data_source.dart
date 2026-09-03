// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_response.dart';

class PreferenceRemoteDataSource {
  final Dio _dio;

  PreferenceRemoteDataSource(this._dio);

  Future<UserPreferenceResponse> getPreferences() async {
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
}

final preferenceRemoteDataSourceProvider =
    FutureProvider<PreferenceRemoteDataSource>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return PreferenceRemoteDataSource(dio);
});
