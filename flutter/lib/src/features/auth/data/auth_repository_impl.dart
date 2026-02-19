import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  AuthRepositoryImpl(this._dataSource, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<AuthResult> login(String email, String password) async {
    final response = await _dataSource.login(email, password);
    final result = AuthResult(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      email: response.email,
      name: response.name,
    );
    await saveTokens(result.accessToken, result.refreshToken);
    return result;
  }

  @override
  Future<AuthResult> register(
      String email, String password, String? name) async {
    final response = await _dataSource.register(email, password, name);
    final result = AuthResult(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      email: response.email,
      name: response.name,
    );
    await saveTokens(result.accessToken, result.refreshToken);
    return result;
  }

  @override
  Future<AuthResult> refresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }
    final response = await _dataSource.refresh(refreshToken);
    final result = AuthResult(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      email: response.email,
      name: response.name,
    );
    await saveTokens(result.accessToken, result.refreshToken);
    return result;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      try {
        await _dataSource.logout(refreshToken);
      } on Exception {
        // Server logout failed, clear local tokens anyway
      }
    }
    await clearTokens();
  }

  @override
  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  @override
  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  @override
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    return !_isTokenExpired(token);
  }

  /// Décode le payload JWT (base64) et vérifie le claim `exp`.
  /// Retourne `true` si le token est expiré ou malformé.
  /// Marge de sécurité de 30 secondes pour éviter les race conditions.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Le payload JWT est en base64url — normaliser le padding
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = map['exp'] as int?;
      if (exp == null) return true;

      // exp est en secondes Unix, on ajoute 30s de marge
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
    } on Exception {
      return true;
    }
  }
}
