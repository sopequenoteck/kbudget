// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/data/remote/api_error.dart';

/// Dio interceptor that manages JWT authentication.
///
/// - Adds `Authorization: Bearer <accessToken>` header on every request.
/// - On 401 response, renews the session through [refreshSession], unless
///   another call already did: the stored access token then differs from the
///   one the request was sent with and is used as is.
/// - Replays the original request with the new access token, on a client
///   without interceptors. The result of the replay, success or error, is the
///   result of the call: a business 401 (e.g. `PASSWORD_INCORRECT`) reaches
///   the screen untouched.
/// - If the session cannot be renewed, calls [onAuthFailure] and forwards the
///   original error.
/// - On 403 `PASSWORD_RESET_REQUIRED`, calls [onPasswordResetRequired]
///   (KKS-309) — a provisioned account (or the admin seed) that reached the
///   dashboard before completing its first-login reset gets rejected on every
///   business call by the server's `PasswordResetRequiredFilter`, without a
///   dedicated screen to break out of the loop.
class JwtInterceptor extends Interceptor {
  JwtInterceptor({
    required this.dio,
    required this.secureStorage,
    required this.refreshSession,
    this.onAuthFailure,
    this.onPasswordResetRequired,
  });

  final Dio dio;
  final FlutterSecureStorage secureStorage;

  /// Renews the session and returns the new access token.
  ///
  /// Throws when the session cannot be renewed.
  final Future<String> Function() refreshSession;
  final VoidCallback? onAuthFailure;
  /// Appelé quand le serveur exige une réinitialisation des identifiants.
  ///
  /// Déclenché par un 403 `PASSWORD_RESET_REQUIRED`, c'est-à-dire quand le
  /// flag n'a pas été vu à la connexion — jetons restaurés au démarrage.
  final VoidCallback? onPasswordResetRequired;

  static const _accessTokenKey = 'access_token';

  // Same adapter as [dio], no interceptor: a replay must not loop back here.
  late final _replayDio = Dio(dio.options.copyWith())
    ..httpClientAdapter = dio.httpClientAdapter;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await secureStorage.read(key: _accessTokenKey);
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 403) {
      // Discriminer du 403 ordinaire (ex: ACCESS_DENIED sur une route admin) :
      // seul le code d'erreur PASSWORD_RESET_REQUIRED doit rediriger.
      if (apiErrorCode(err) == 'PASSWORD_RESET_REQUIRED') {
        onPasswordResetRequired?.call();
      }
      return handler.next(err);
    }

    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final String accessToken;
    try {
      final stored = await secureStorage.read(key: _accessTokenKey);
      final sent = err.requestOptions.headers['Authorization'];
      accessToken = stored != null && 'Bearer $stored' != sent
          ? stored
          : await refreshSession();
    } on Object {
      // The request ends first: a failing callback must not leave it pending.
      handler.next(err);
      onAuthFailure?.call();
      return;
    }

    try {
      final original = err.requestOptions;
      final headers = {
        ...original.headers,
        'Authorization': 'Bearer $accessToken',
      };
      final response = await _replayDio
          .fetch<dynamic>(original.copyWith(headers: headers));
      return handler.resolve(response);
    } on DioException catch (replayError) {
      return handler.next(replayError);
    } on Object {
      return handler.next(err);
    }
  }
}
