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

  /// Réinitialise email/mot de passe/nom d'un compte provisionné (KKS-309).
  ///
  /// Requiert un JWT valide (celui obtenu au login). En cas de succès, sauve
  /// les nouveaux tokens comme [login].
  Future<AuthResult> firstLoginReset({
    required String email,
    required String password,
    required String displayName,
  });
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String email;
  final String? name;

  /// `true` si le compte a été provisionné par un admin et doit passer par
  /// l'écran de première connexion avant de pouvoir utiliser l'app (KKS-309).
  final bool mustResetCredentials;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    this.name,
    this.mustResetCredentials = false,
  });
}
