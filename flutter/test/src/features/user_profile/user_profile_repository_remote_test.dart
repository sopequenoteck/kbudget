import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/user_profile/data/user_profile_repository_remote.dart';
import 'package:k_budget/src/features/user_profile/domain/models/delete_account_request.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_profile_repository_remote_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late Directory tempDir;
  late UserProfileRepositoryRemote repository;

  setUp(() async {
    mockDio = MockDio();
    tempDir = Directory.systemTemp.createTempSync('kbudget_test_');
    repository = UserProfileRepositoryRemote(
      mockDio,
      getExportDirectory: () async => tempDir,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('UserProfileRepositoryRemote.exportJson', () {
    test('should_returnFile_when_serverRespondsWithBytes', () async {
      const bytes = [123, 125]; // "{}" JSON minimal
      const filename = 'kbudget-export-uuid-20260427.json';

      when(
        mockDio.get<List<int>>(
          '/users/me/export',
          queryParameters: {'format': 'json'},
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          data: bytes,
          statusCode: 200,
          headers: Headers.fromMap({
            'content-disposition': [
              'attachment; filename="$filename"',
            ],
          }),
          requestOptions: RequestOptions(path: '/users/me/export'),
        ),
      );

      final file = await repository.exportJson();

      expect(file, isA<File>());
      expect(file.path, endsWith(filename));
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), bytes);
    });

    test('should_useFallbackFilename_when_contentDispositionAbsent', () async {
      const bytes = [1, 2, 3];

      when(
        mockDio.get<List<int>>(
          '/users/me/export',
          queryParameters: {'format': 'json'},
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          data: bytes,
          statusCode: 200,
          headers: Headers.fromMap({}),
          requestOptions: RequestOptions(path: '/users/me/export'),
        ),
      );

      final file = await repository.exportJson();

      expect(file, isA<File>());
      expect(file.path, contains('.json'));
    });
  });

  group('UserProfileRepositoryRemote.exportCsv', () {
    test('should_returnFile_when_serverRespondsWithBytes', () async {
      const bytes = [68, 97, 116, 101]; // "Date"
      const filename = 'kbudget-transactions-uuid-20260427.csv';

      when(
        mockDio.get<List<int>>(
          '/users/me/export',
          queryParameters: {'format': 'csv'},
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          data: bytes,
          statusCode: 200,
          headers: Headers.fromMap({
            'content-disposition': [
              'attachment; filename="$filename"',
            ],
          }),
          requestOptions: RequestOptions(path: '/users/me/export'),
        ),
      );

      final file = await repository.exportCsv();

      expect(file, isA<File>());
      expect(file.path, endsWith(filename));
      expect(await file.exists(), isTrue);
    });

    test('should_useFallbackFilename_when_contentDispositionAbsent', () async {
      const bytes = [1, 2, 3];

      when(
        mockDio.get<List<int>>(
          '/users/me/export',
          queryParameters: {'format': 'csv'},
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          data: bytes,
          statusCode: 200,
          headers: Headers.fromMap({}),
          requestOptions: RequestOptions(path: '/users/me/export'),
        ),
      );

      final file = await repository.exportCsv();

      expect(file, isA<File>());
      expect(file.path, contains('.csv'));
    });
  });

  group('UserProfileRepositoryRemote.deleteAccount', () {
    test('should_completeWithoutError_when_serverReturns204', () async {
      const req = DeleteAccountRequest(
        currentPassword: 'correct_password',
        confirmed: true,
      );

      when(
        mockDio.delete<void>(
          '/users/me',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/users/me'),
        ),
      );

      await expectLater(repository.deleteAccount(req), completes);

      verify(
        mockDio.delete<void>(
          '/users/me',
          data: req.toJson(),
        ),
      ).called(1);
    });

    test('should_throwDioException_when_serverReturns401', () async {
      const req = DeleteAccountRequest(
        currentPassword: 'wrong_password',
        confirmed: true,
      );

      when(
        mockDio.delete<void>(
          '/users/me',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: Response(
            statusCode: 401,
            data: {'error': 'PASSWORD_INCORRECT'},
            requestOptions: RequestOptions(path: '/users/me'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await expectLater(
        repository.deleteAccount(req),
        throwsA(isA<DioException>()),
      );
    });

    test('should_throwDioException_when_serverReturns403LastAdmin', () async {
      const req = DeleteAccountRequest(
        currentPassword: 'correct_password',
        confirmed: true,
      );

      when(
        mockDio.delete<void>(
          '/users/me',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/users/me'),
          response: Response(
            statusCode: 403,
            data: {'error': 'LAST_ADMIN_DELETION_FORBIDDEN'},
            requestOptions: RequestOptions(path: '/users/me'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await expectLater(
        repository.deleteAccount(req),
        throwsA(isA<DioException>()),
      );
    });
  });
}
