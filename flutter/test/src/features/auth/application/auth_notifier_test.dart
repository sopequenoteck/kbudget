import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((_) async => mockAuthRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  AuthNotifier notifier() =>
      container.read(authNotifierProvider.notifier);

  AuthState state() => container.read(authNotifierProvider);

  group('AuthNotifier', () {
    test('should_haveInitialState_when_created', () {
      expect(state(), isA<AuthInitial>());
    });

    test('should_beAuthenticated_when_tokenExists', () async {
      when(mockAuthRepo.hasValidToken()).thenAnswer((_) async => true);

      await notifier().checkAuth();

      expect(state(), isA<AuthAuthenticated>());
      verify(mockAuthRepo.hasValidToken()).called(1);
    });

    test('should_beAuthenticated_when_noTokenButRefreshSucceeds', () async {
      when(mockAuthRepo.hasValidToken()).thenAnswer((_) async => false);
      when(mockAuthRepo.refresh()).thenAnswer((_) async => const AuthResult(
            accessToken: 'new_access',
            refreshToken: 'new_refresh',
            email: 'test@test.com',
          ));

      await notifier().checkAuth();

      expect(state(), isA<AuthAuthenticated>());
      verify(mockAuthRepo.refresh()).called(1);
    });

    test('should_beUnauthenticated_when_noTokenAndRefreshFails', () async {
      when(mockAuthRepo.hasValidToken()).thenAnswer((_) async => false);
      when(mockAuthRepo.refresh()).thenThrow(Exception('No refresh token'));

      await notifier().checkAuth();

      expect(state(), isA<AuthUnauthenticated>());
    });

    test('should_beAuthenticated_when_loginSucceeds', () async {
      when(mockAuthRepo.login('test@test.com', 'password'))
          .thenAnswer((_) async => const AuthResult(
                accessToken: 'access',
                refreshToken: 'refresh',
                email: 'test@test.com',
              ));

      await notifier().login('test@test.com', 'password');

      expect(state(), isA<AuthAuthenticated>());
    });

    test('should_showError_when_loginFails401', () async {
      when(mockAuthRepo.login('test@test.com', 'wrong'))
          .thenThrow(DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 401,
        ),
      ));

      await notifier().login('test@test.com', 'wrong');

      final s = state();
      expect(s, isA<AuthUnauthenticated>());
      expect((s as AuthUnauthenticated).error,
          'Email ou mot de passe incorrect');
    });

    test('should_showGenericError_when_loginFailsNetwork', () async {
      when(mockAuthRepo.login('test@test.com', 'pass'))
          .thenThrow(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      ));

      await notifier().login('test@test.com', 'pass');

      final s = state();
      expect(s, isA<AuthUnauthenticated>());
      expect((s as AuthUnauthenticated).error, 'Erreur de connexion');
    });

    test('should_beUnauthenticated_when_forceUnauthenticatedCalled', () async {
      // Login first
      when(mockAuthRepo.login('test@test.com', 'password'))
          .thenAnswer((_) async => const AuthResult(
                accessToken: 'access',
                refreshToken: 'refresh',
                email: 'test@test.com',
              ));
      await notifier().login('test@test.com', 'password');
      expect(state(), isA<AuthAuthenticated>());

      // Force unauthenticated
      notifier().forceUnauthenticated();

      expect(state(), isA<AuthUnauthenticated>());
    });

    test('should_beUnauthenticated_when_logoutCalled', () async {
      // Login first
      when(mockAuthRepo.login('test@test.com', 'password'))
          .thenAnswer((_) async => const AuthResult(
                accessToken: 'access',
                refreshToken: 'refresh',
                email: 'test@test.com',
              ));
      await notifier().login('test@test.com', 'password');
      expect(state(), isA<AuthAuthenticated>());

      // Logout
      when(mockAuthRepo.logout()).thenAnswer((_) async {});
      await notifier().logout();

      expect(state(), isA<AuthUnauthenticated>());
      verify(mockAuthRepo.logout()).called(1);
    });

    test('should_bePasswordResetRequired_when_loginReturnsMustReset',
        () async {
      when(mockAuthRepo.login('provisioned@test.com', 'password'))
          .thenAnswer((_) async => const AuthResult(
                accessToken: 'access',
                refreshToken: 'refresh',
                email: 'provisioned@test.com',
                mustResetCredentials: true,
              ));

      await notifier().login('provisioned@test.com', 'password');

      expect(state(), isA<AuthPasswordResetRequired>());
    });

    test(
        'should_bePasswordResetRequired_when_checkAuthRefreshReturnsMustReset',
        () async {
      when(mockAuthRepo.hasValidToken()).thenAnswer((_) async => false);
      when(mockAuthRepo.refresh()).thenAnswer((_) async => const AuthResult(
            accessToken: 'new_access',
            refreshToken: 'new_refresh',
            email: 'provisioned@test.com',
            mustResetCredentials: true,
          ));

      await notifier().checkAuth();

      expect(state(), isA<AuthPasswordResetRequired>());
    });

    test('should_setPasswordResetRequired_when_requirePasswordResetCalled',
        () async {
      // Authenticated first
      when(mockAuthRepo.login('test@test.com', 'password'))
          .thenAnswer((_) async => const AuthResult(
                accessToken: 'access',
                refreshToken: 'refresh',
                email: 'test@test.com',
              ));
      await notifier().login('test@test.com', 'password');
      expect(state(), isA<AuthAuthenticated>());

      notifier().requirePasswordReset();

      expect(state(), isA<AuthPasswordResetRequired>());
    });

    test('should_beAuthenticated_when_completeFirstLoginResetSucceeds',
        () async {
      when(mockAuthRepo.firstLoginReset(
        email: 'test@test.com',
        password: 'a-very-long-password',
        displayName: 'Test User',
      )).thenAnswer((_) async => const AuthResult(
            accessToken: 'new_access',
            refreshToken: 'new_refresh',
            email: 'test@test.com',
            name: 'Test User',
          ));

      await notifier().completeFirstLoginReset(
        email: 'test@test.com',
        password: 'a-very-long-password',
        displayName: 'Test User',
      );

      expect(state(), isA<AuthAuthenticated>());
      verify(mockAuthRepo.firstLoginReset(
        email: 'test@test.com',
        password: 'a-very-long-password',
        displayName: 'Test User',
      )).called(1);
    });
  });
}
