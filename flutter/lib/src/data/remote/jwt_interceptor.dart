import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';

/// Dio interceptor that manages JWT authentication.
///
/// - Adds `Authorization: Bearer <accessToken>` header on every request.
/// - On 401 response, attempts a token refresh via `/auth/refresh`.
/// - Replays the original request with the new access token.
/// - If the refresh fails, calls [onAuthFailure] and forwards the error.
class JwtInterceptor extends Interceptor {
  JwtInterceptor({
    required this.dio,
    required this.secureStorage,
    this.onAuthFailure,
  });

  final Dio dio;
  final FlutterSecureStorage secureStorage;
  final VoidCallback? onAuthFailure;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Completer<String?>? _refreshCompleter;

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
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Si un refresh est déjà en cours, attendre son résultat
    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final refreshDio = Dio(BaseOptions(
          baseUrl: dio.options.baseUrl,
          contentType: 'application/json',
          connectTimeout: dio.options.connectTimeout,
          receiveTimeout: dio.options.receiveTimeout,
        ));
        try {
          final retryResponse = await refreshDio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } on DioException {
          return handler.next(err);
        }
      }
      return handler.next(err);
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        _refreshCompleter!.complete(null);
        _refreshCompleter = null;
        onAuthFailure?.call();
        return handler.next(err);
      }

      // Use a separate Dio instance to avoid interceptor loop
      final refreshDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        contentType: 'application/json',
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
      ));

      final refreshRequest = RefreshRequest(refreshToken: refreshToken);
      final response = await refreshDio.post(
        '/auth/refresh',
        data: refreshRequest.toJson(),
      );

      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Store new tokens
      await secureStorage.write(
        key: _accessTokenKey,
        value: authResponse.accessToken,
      );
      await secureStorage.write(
        key: _refreshTokenKey,
        value: authResponse.refreshToken,
      );

      _refreshCompleter!.complete(authResponse.accessToken);
      _refreshCompleter = null;

      // Replay original request with new token
      final originalRequest = err.requestOptions;
      originalRequest.headers['Authorization'] =
          'Bearer ${authResponse.accessToken}';

      final retryResponse = await refreshDio.fetch(originalRequest);
      return handler.resolve(retryResponse);
    } on DioException {
      _refreshCompleter!.complete(null);
      _refreshCompleter = null;
      onAuthFailure?.call();
      return handler.next(err);
    } catch (_) {
      _refreshCompleter!.complete(null);
      _refreshCompleter = null;
      onAuthFailure?.call();
      return handler.next(err);
    }
  }
}
