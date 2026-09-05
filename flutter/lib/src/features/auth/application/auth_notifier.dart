// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/auth/data/auth_repository_impl.dart';

final authRemoteDataSourceProvider =
    FutureProvider<AuthRemoteDataSource>((ref) async {
  final dio = await ref.watch(apiClientProvider.future);
  return AuthRemoteDataSource(dio);
});

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final dataSource = await ref.watch(authRemoteDataSourceProvider.future);
  return AuthRepositoryImpl(dataSource);
});

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> implements Listenable {
  final List<VoidCallback> _listeners = [];

  @override
  AuthState build() {
    return const AuthState.initial();
  }

  Future<AuthRepository> get _repo => ref.read(authRepositoryProvider.future);

  Future<void> checkAuth() async {
    final repo = await _repo;
    final hasToken = await repo.hasValidToken();
    if (hasToken) {
      // Le token local ne porte pas mustResetCredentials — un compte encore
      // soumis au reset sera intercepté au premier appel métier (KKS-309).
      state = const AuthState.authenticated();
    } else {
      // Access token expiré ou absent — tenter un refresh
      try {
        final result = await repo.refresh();
        state = result.mustResetCredentials
            ? const AuthState.passwordResetRequired()
            : const AuthState.authenticated();
      } on Exception {
        state = const AuthState.unauthenticated();
      }
    }
    _notifyListeners();
  }

  void forceUnauthenticated() {
    state = const AuthState.unauthenticated();
    _notifyListeners();
  }

  /// Fait basculer l'état auth quand un 403 `PASSWORD_RESET_REQUIRED`
  /// est intercepté en cours de session (KKS-309).
  void requirePasswordReset() {
    state = const AuthState.passwordResetRequired();
    _notifyListeners();
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.authenticating();
    try {
      final repo = await _repo;
      final result = await repo.login(email, password);
      state = result.mustResetCredentials
          ? const AuthState.passwordResetRequired()
          : const AuthState.authenticated();
    } on DioException catch (e) {
      final message = e.response?.statusCode == 401
          ? 'Email ou mot de passe incorrect'
          : 'Erreur de connexion';
      state = AuthState.unauthenticated(error: message);
    } on Exception catch (e) {
      state = AuthState.unauthenticated(error: 'Erreur: $e');
    }
    _notifyListeners();
  }

  /// Termine le flux de première connexion (KKS-309) : sauvegarde les
  /// nouveaux tokens et repasse en authentifié normal. Laisse toute
  /// [DioException] remonter à l'appelant pour affichage dans l'écran.
  Future<void> completeFirstLoginReset({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final repo = await _repo;
    await repo.firstLoginReset(
      email: email,
      password: password,
      displayName: displayName,
    );
    state = const AuthState.authenticated();
    _notifyListeners();
  }

  Future<void> logout() async {
    final repo = await _repo;
    await repo.logout();
    state = const AuthState.unauthenticated();
    _notifyListeners();
  }

  // Listenable implementation for GoRouter refreshListenable
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
