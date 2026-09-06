// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.authenticating() = AuthAuthenticating;
  const factory AuthState.authenticated() = AuthAuthenticated;
  /// Non authentifie, avec le **code** d'erreur eventuel — jamais un libelle.
  ///
  /// Un `Notifier` Riverpod n'a pas de `BuildContext` et ne peut donc pas
  /// resoudre un texte localise. Le state porte la donnee, le widget porte le
  /// texte : c'est deja le pattern du reste de l'application (KKS-324).
  const factory AuthState.unauthenticated({String? errorCode}) =
      AuthUnauthenticated;

  /// Une tentative de connexion vient d'échouer, avec le **code** d'erreur
  /// éventuel — jamais un libellé.
  ///
  /// Distinct d'[AuthState.unauthenticated] : ce dernier est aussi l'état du
  /// premier rendu de l'écran de connexion et de l'état après déconnexion,
  /// où aucun message d'erreur ne doit apparaître. `errorCode` nullable ne
  /// suffit pas à distinguer ces deux cas — un échec sans code exploitable
  /// (serveur injoignable) est indiscernable d'un premier rendu. Un variant
  /// dédié rend l'échec visible dans les `is`, là où un champ optionnel
  /// s'oublie (KKS-309, même raisonnement que
  /// [AuthState.passwordResetRequired]).
  const factory AuthState.loginFailed({String? errorCode}) = AuthLoginFailed;

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
