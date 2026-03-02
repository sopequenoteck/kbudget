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
      state = const AuthState.authenticated();
    } else {
      // Access token expiré ou absent — tenter un refresh
      try {
        await repo.refresh();
        state = const AuthState.authenticated();
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

  Future<void> login(String email, String password) async {
    state = const AuthState.authenticating();
    try {
      final repo = await _repo;
      await repo.login(email, password);
      state = const AuthState.authenticated();
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

  Future<void> register(
      String email, String password, String? name) async {
    state = const AuthState.authenticating();
    try {
      final repo = await _repo;
      await repo.register(email, password, name);
      state = const AuthState.authenticated();
    } on DioException catch (e) {
      final message = e.response?.statusCode == 409
          ? 'Email déjà utilisé'
          : 'Erreur lors de l\'inscription';
      state = AuthState.unauthenticated(error: message);
    } on Exception catch (e) {
      state = AuthState.unauthenticated(error: 'Erreur: $e');
    }
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
