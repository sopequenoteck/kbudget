// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

const _preferencesBody = <String, dynamic>{
  'enabledFeatures': ['SUBSCRIPTIONS', 'DEBTS'],
  'navOrder': ['SUBSCRIPTIONS', 'DEBTS'],
};

/// A Dio whose answer arrives asynchronously, so that concurrent reads
/// really overlap.
Dio _preferencesDio(List<RequestOptions> requests, {bool fail = false}) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests.add(options);
          await Future<void>.delayed(Duration.zero);
          if (fail) {
            handler.reject(DioException(requestOptions: options));
            return;
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: _preferencesBody,
            ),
          );
        },
      ),
    );
}

void main() {
  group('PreferenceRemoteDataSource', () {
    test('should_sendGet_when_preferencesRead', () async {
      final requests = <RequestOptions>[];
      final dataSource = PreferenceRemoteDataSource(_preferencesDio(requests));

      final result = await dataSource.getPreferences();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/users/me/preferences');
      expect(result.enabledFeatures, [Feature.subscriptions, Feature.debts]);
    });

    test('should_sendSingleGet_when_preferencesReadConcurrently', () async {
      final requests = <RequestOptions>[];
      final dataSource = PreferenceRemoteDataSource(_preferencesDio(requests));

      final results = await Future.wait([
        dataSource.getPreferences(),
        dataSource.getPreferences(),
        dataSource.getPreferences(),
      ]);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/users/me/preferences');
      expect(results, hasLength(3));
      expect(results[1], same(results[0]));
      expect(results[2], same(results[0]));
    });

    test('should_sendNewGet_when_previousReadCompleted', () async {
      final requests = <RequestOptions>[];
      final dataSource = PreferenceRemoteDataSource(_preferencesDio(requests));

      await dataSource.getPreferences();
      await dataSource.getPreferences();

      expect(requests, hasLength(2));
    });

    test('should_forwardErrorToAllCallers_when_concurrentReadFails', () async {
      final requests = <RequestOptions>[];
      final dataSource = PreferenceRemoteDataSource(
        _preferencesDio(requests, fail: true),
      );

      final first = expectLater(
        dataSource.getPreferences(),
        throwsA(isA<DioException>()),
      );
      final second = expectLater(
        dataSource.getPreferences(),
        throwsA(isA<DioException>()),
      );
      await Future.wait([first, second]);

      expect(requests, hasLength(1));
    });

    test('should_sendNewGet_when_previousReadFailed', () async {
      final requests = <RequestOptions>[];
      final dataSource = PreferenceRemoteDataSource(
        _preferencesDio(requests, fail: true),
      );

      await expectLater(
        dataSource.getPreferences(),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        dataSource.getPreferences(),
        throwsA(isA<DioException>()),
      );

      expect(requests, hasLength(2));
    });

    test('should_sendDelete_when_languageCleared', () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                Response<void>(requestOptions: options, statusCode: 204),
              );
            },
          ),
        );

      await PreferenceRemoteDataSource(dio).clearLanguage();

      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/users/me/preferences/language');
    });

    test('should_throw_when_deleteFails', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(requestOptions: options),
            ),
          ),
        );

      expect(
        PreferenceRemoteDataSource(dio).clearLanguage(),
        throwsA(isA<DioException>()),
      );
    });
  });
}
