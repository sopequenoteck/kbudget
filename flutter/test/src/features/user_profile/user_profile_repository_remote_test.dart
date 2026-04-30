import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/user_profile/data/user_profile_repository_remote.dart';
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
}
