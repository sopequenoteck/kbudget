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
}
