import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/auth/data/auth_repository_impl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([AuthRemoteDataSource, FlutterSecureStorage])
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
  late AuthRepositoryImpl repo;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    mockStorage = MockFlutterSecureStorage();
    repo = AuthRepositoryImpl(mockDataSource, storage: mockStorage);
  });

  group('hasValidToken', () {
    test('should_returnFalse_when_noTokenStored', () async {
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => null);

      expect(await repo.hasValidToken(), isFalse);
    });

    test('should_returnFalse_when_tokenIsEmpty', () async {
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => '');

      expect(await repo.hasValidToken(), isFalse);
    });

    test('should_returnFalse_when_tokenIsExpired', () async {
      // Token expiré il y a 1 heure
      final expiredExp = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final token = _buildFakeJwt(exp: expiredExp);
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => token);

      expect(await repo.hasValidToken(), isFalse);
    });

    test('should_returnFalse_when_tokenExpiresWithin30Seconds', () async {
      // Token expire dans 15 secondes (sous la marge de 30s)
      final soonExp = DateTime.now().add(const Duration(seconds: 15)).millisecondsSinceEpoch ~/ 1000;
      final token = _buildFakeJwt(exp: soonExp);
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => token);

      expect(await repo.hasValidToken(), isFalse);
    });

    test('should_returnTrue_when_tokenIsValid', () async {
      // Token expire dans 10 minutes
      final validExp = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;
      final token = _buildFakeJwt(exp: validExp);
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => token);

      expect(await repo.hasValidToken(), isTrue);
    });

    test('should_returnFalse_when_tokenIsMalformed', () async {
      when(mockStorage.read(key: 'access_token')).thenAnswer((_) async => 'not-a-jwt');

      expect(await repo.hasValidToken(), isFalse);
    });
  });
}
