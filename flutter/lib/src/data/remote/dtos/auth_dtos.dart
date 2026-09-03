import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_dtos.freezed.dart';
part 'auth_dtos.g.dart';

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
    String? name,
    String? invitationToken,
    String? currency,
    String? timezone,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

@freezed
class RefreshRequest with _$RefreshRequest {
  const factory RefreshRequest({
    required String refreshToken,
  }) = _RefreshRequest;

  factory RefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestFromJson(json);
}

@freezed
class LogoutRequest with _$LogoutRequest {
  const factory LogoutRequest({
    required String refreshToken,
  }) = _LogoutRequest;

  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      _$LogoutRequestFromJson(json);
}

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    @JsonKey(name: 'token') required String accessToken,
    required String refreshToken,
    required String email,
    String? name,
    @Default(false) bool mustResetCredentials,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

/// Requête pour `POST /auth/first-login-reset` (KKS-309).
///
/// Exige un JWT valide en en-tête `Authorization` — porté séparément par
/// `AuthRemoteDataSource.firstLoginReset`, pas par ce DTO.
@freezed
class FirstLoginResetRequest with _$FirstLoginResetRequest {
  /// Identifiants définitifs choisis par l'utilisateur.
  ///
  /// [password] doit faire au moins 12 caractères : c'est la contrainte
  /// serveur de `FirstLoginResetRequest`, plus stricte que celle de
  /// l'acceptation d'invitation.
  const factory FirstLoginResetRequest({
    required String email,
    required String password,
    required String displayName,
  }) = _FirstLoginResetRequest;

  /// Construit la requête depuis sa représentation JSON.
  factory FirstLoginResetRequest.fromJson(Map<String, dynamic> json) =>
      _$FirstLoginResetRequestFromJson(json);
}
