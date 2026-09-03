import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.authenticating() = AuthAuthenticating;
  const factory AuthState.authenticated() = AuthAuthenticated;
  const factory AuthState.unauthenticated({String? error}) =
      AuthUnauthenticated;

  /// Authentifié mais bloqué avant le dashboard : le compte a été provisionné
  /// par un admin (ou est l'admin seed) et doit passer par l'écran de
  /// première connexion avant de pouvoir utiliser l'app (KKS-309).
  ///
  /// État séparé plutôt qu'un champ sur [AuthState.authenticated] : les
  /// nombreux appels existants à `AuthState.authenticated()` restent
  /// inchangés, et les tests qui font `is AuthAuthenticated` continuent de
  /// distinguer clairement les deux cas.
  const factory AuthState.passwordResetRequired() = AuthPasswordResetRequired;
}
