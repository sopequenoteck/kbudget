abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(String email, String password, String? name,
      {String? currency, String? timezone});
  Future<AuthResult> refresh();
  Future<void> logout();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clearTokens();
  Future<bool> hasValidToken();
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String email;
  final String? name;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    this.name,
  });
}
