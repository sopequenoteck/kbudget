import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/auth/data/auth_repository_impl.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioAsync = ref.watch(authenticatedDioProvider);
  return dioAsync.when(
    data: (dio) => AuthRemoteDataSource(dio),
    loading: () => AuthRemoteDataSource(Dio()),
    error: (_, _) => AuthRemoteDataSource(Dio()),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
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

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> checkAuth() async {
    final hasToken = await _repo.hasValidToken();
    if (hasToken) {
      state = const AuthState.authenticated();
    } else {
      state = const AuthState.unauthenticated();
    }
    _notifyListeners();
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.authenticating();
    try {
      await _repo.login(email, password);
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
      await _repo.register(email, password, name);
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
    await _repo.logout();
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
