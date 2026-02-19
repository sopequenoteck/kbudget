import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/auth/data/auth_repository_impl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<AuthRemoteDataSource>(),
  MockSpec<FlutterSecureStorage>(),
])
import 'auth_repository_impl_test.mocks.dart';

/// Génère un JWT factice avec le claim `exp` donné.
/// Ne signe pas le token (pas nécessaire pour le décodage côté client).
String _buildFakeJwt({required int exp}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final payload = base64Url.encode(utf8.encode('{"sub":"test@test.fr","exp":$exp}'));
  const signature = 'fake-signature';
  return '$header.$payload.$signature';
}

void main() {
  late MockAuthRemoteDataSource mockDataSource;
  late MockFlutterSecureStorage mockStorage;
  late AuthRepositoryImpl repository;

  const testAuthResponse = AuthResponse(
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    email: 'test@test.com',
    name: 'Test User',
  );

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    mockStorage = MockFlutterSecureStorage();
    repository = AuthRepositoryImpl(
      mockDataSource,
      storage: mockStorage,
    );
  });

  group('AuthRepositoryImpl', () {
    test('should_returnAuthResult_when_loginSucceeds', () async {
      when(mockDataSource.login('test@test.com', 'password'))
          .thenAnswer((_) async => testAuthResponse);
      when(mockStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      final result = await repository.login('test@test.com', 'password');

      expect(result.accessToken, 'test-access-token');
      expect(result.refreshToken, 'test-refresh-token');
      expect(result.email, 'test@test.com');
      expect(result.name, 'Test User');

      verify(mockStorage.write(
              key: 'access_token', value: 'test-access-token'))
          .called(1);
      verify(mockStorage.write(
              key: 'refresh_token', value: 'test-refresh-token'))
          .called(1);
    });

    test('should_returnAuthResult_when_registerSucceeds', () async {
      when(mockDataSource.register('new@test.com', 'password', 'New'))
          .thenAnswer((_) async => testAuthResponse);
      when(mockStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      final result =
          await repository.register('new@test.com', 'password', 'New');

      expect(result.accessToken, 'test-access-token');
      verify(mockDataSource.register('new@test.com', 'password', 'New'))
          .called(1);
    });

    test('should_refreshTokens_when_refreshCalled', () async {
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'old-refresh');
      when(mockDataSource.refresh('old-refresh'))
          .thenAnswer((_) async => testAuthResponse);
      when(mockStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      final result = await repository.refresh();

      expect(result.accessToken, 'test-access-token');
      verify(mockStorage.write(
              key: 'access_token', value: 'test-access-token'))
          .called(1);
    });

    test('should_throwException_when_noRefreshToken', () async {
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => null);

      expect(() => repository.refresh(), throwsException);
    });

    test('should_clearTokens_when_logoutSucceeds', () async {
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refresh');
      when(mockDataSource.logout('refresh')).thenAnswer((_) async {});
      when(mockStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async {});

      await repository.logout();

      verify(mockDataSource.logout('refresh')).called(1);
      verify(mockStorage.delete(key: 'access_token')).called(1);
      verify(mockStorage.delete(key: 'refresh_token')).called(1);
    });

    test('should_clearTokensLocally_when_serverLogoutFails', () async {
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refresh');
      when(mockDataSource.logout('refresh'))
          .thenThrow(Exception('Network error'));
      when(mockStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async {});

      await repository.logout();

      verify(mockStorage.delete(key: 'access_token')).called(1);
      verify(mockStorage.delete(key: 'refresh_token')).called(1);
    });
  });

  group('hasValidToken', () {
    test('should_returnFalse_when_noTokenStored', () async {
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => null);

      expect(await repository.hasValidToken(), isFalse);
    });

    test('should_returnFalse_when_tokenIsEmpty', () async {
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => '');

      expect(await repository.hasValidToken(), isFalse);
    });

    test('should_returnFalse_when_tokenIsExpired', () async {
      final expiredExp = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final token = _buildFakeJwt(exp: expiredExp);
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => token);

      expect(await repository.hasValidToken(), isFalse);
    });

    test('should_returnFalse_when_tokenExpiresWithin30Seconds', () async {
      final soonExp = DateTime.now().add(const Duration(seconds: 15)).millisecondsSinceEpoch ~/ 1000;
      final token = _buildFakeJwt(exp: soonExp);
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => token);

      expect(await repository.hasValidToken(), isFalse);
    });

    test('should_returnTrue_when_tokenIsValid', () async {
      final validExp = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;
      final token = _buildFakeJwt(exp: validExp);
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => token);

      expect(await repository.hasValidToken(), isTrue);
    });

    test('should_returnFalse_when_tokenIsMalformed', () async {
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => 'not-a-jwt');

      expect(await repository.hasValidToken(), isFalse);
    });
  });
}
