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
    return token != null && token.isNotEmpty;
  }
}
