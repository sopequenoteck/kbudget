// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';

void main() {
  group('PreferenceRemoteDataSource', () {
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
