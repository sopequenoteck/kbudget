// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: LoginRequest(email: email, password: password).toJson(),
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<AuthResponse> register(
    String email,
    String password,
    String? name, {
    String? invitationToken,
    String? currency,
    String? timezone,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: RegisterRequest(
        email: email,
        password: password,
        name: name,
        invitationToken: invitationToken,
        currency: currency,
        timezone: timezone,
      ).toJson(),
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: RefreshRequest(refreshToken: refreshToken).toJson(),
    );
    return AuthResponse.fromJson(response.data!);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: LogoutRequest(refreshToken: refreshToken).toJson(),
    );
  }

  /// Requiert un JWT valide : [accessToken] est attaché manuellement en
  /// en-tête car ce data source utilise le Dio non authentifié
  /// (`apiClientProvider`), partagé avec login/register qui n'en ont pas
  /// besoin.
  Future<AuthResponse> firstLoginReset({
    required String email,
    required String password,
    required String displayName,
    required String accessToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/first-login-reset',
      data: FirstLoginResetRequest(
        email: email,
        password: password,
        displayName: displayName,
      ).toJson(),
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return AuthResponse.fromJson(response.data!);
  }
}
