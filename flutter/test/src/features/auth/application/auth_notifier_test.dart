import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/repositories/auth_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

DioException _dioError(int statusCode, Object? data) => DioException(
      requestOptions: RequestOptions(),
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: statusCode,
        data: data,
      ),
    );

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

    test('should_exposeErrorCode_when_loginFailsWithBadRequest', () async {
      when(mockAuthRepo.login('test@test.com', 'wrong'))
          .thenThrow(_dioError(400, {'error': 'BAD_REQUEST'}));

      await notifier().login('test@test.com', 'wrong');

      final s = state();
      expect(s, isA<AuthLoginFailed>());
      expect((s as AuthLoginFailed).errorCode, 'BAD_REQUEST');
    });

    test('should_distinguishTokenExpired_from_unauthenticated', () async {
      // Les deux etaient servis sous un meme 401, donc sous un meme texte :
      // le serveur les distingue, le client le doit aussi (KKS-324).
      when(mockAuthRepo.login('a@test.com', 'p'))
          .thenThrow(_dioError(401, {'error': 'TOKEN_EXPIRED'}));
      await notifier().login('a@test.com', 'p');
      final expired = (state() as AuthLoginFailed).errorCode;

      when(mockAuthRepo.login('b@test.com', 'p'))
          .thenThrow(_dioError(401, {'error': 'UNAUTHENTICATED'}));
      await notifier().login('b@test.com', 'p');
      final unauthenticated = (state() as AuthLoginFailed).errorCode;

      expect(expired, 'TOKEN_EXPIRED');
      expect(unauthenticated, 'UNAUTHENTICATED');
      expect(expired, isNot(unauthenticated));
    });

    test('should_exposeNullCode_when_loginFailsNetwork', () async {
      when(mockAuthRepo.login('test@test.com', 'pass'))
          .thenThrow(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      ));

      await notifier().login('test@test.com', 'pass');

      final s = state();
      expect(s, isA<AuthLoginFailed>());
      expect((s as AuthLoginFailed).errorCode, isNull);
    });

    test('should_exposeNullCode_when_errorBodyIsNotAMap', () async {
      // Un 502 de reverse proxy renvoie du HTML : aucun code exploitable,
      // aucune exception levee.
      when(mockAuthRepo.login('test@test.com', 'pass'))
          .thenThrow(_dioError(502, '<html>Bad Gateway</html>'));

      await notifier().login('test@test.com', 'pass');

      final s = state();
      expect(s, isA<AuthLoginFailed>());
      expect((s as AuthLoginFailed).errorCode, isNull);
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
