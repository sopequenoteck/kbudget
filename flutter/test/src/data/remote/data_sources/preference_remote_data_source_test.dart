// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';

import '../../../features/settings/application/language_notifier_test.dart'
    show FakeAuthNotifier, heldPreferencesDio, preferencesJson;

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

    group('preferenceRemoteDataSourceProvider', () {
      late List<RequestOptions> requests;
      late List<Completer<Map<String, dynamic>>> answers;
      late ProviderContainer container;

      void emit(AuthState next) =>
          (container.read(authNotifierProvider.notifier) as FakeAuthNotifier)
              .emit(next);

      ProviderContainer start(AuthState auth) {
        requests = <RequestOptions>[];
        final dio = heldPreferencesDio(requests, answers);
        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(() => FakeAuthNotifier(auth)),
            authenticatedDioProvider.overrideWith((ref) async => dio),
          ],
        );
        addTearDown(container.dispose);
        return container;
      }

      test('should_notShareInFlightRead_when_sessionChanges', () async {
        answers = [
          Completer<Map<String, dynamic>>(),
          Completer<Map<String, dynamic>>()
            ..complete(preferencesJson(language: 'en')),
        ];
        start(const AuthState.authenticated());

        final sourceA =
            await container.read(preferenceRemoteDataSourceProvider.future);
        final readA = sourceA.getPreferences();
        await pumpEventQueue();
        emit(const AuthState.unauthenticated());
        emit(const AuthState.authenticated());
        final sourceB =
            await container.read(preferenceRemoteDataSourceProvider.future);
        final readB = sourceB.getPreferences();
        await pumpEventQueue();
        answers.first.complete(preferencesJson(language: 'fr'));

        expect(sourceB, isNot(same(sourceA)));
        expect(requests, hasLength(2));
        expect((await readB).language, 'en');
        expect((await readA).language, 'fr');
      });

      test('should_keepSameSource_when_sessionIsUnchanged', () async {
        answers = [];
        start(const AuthState.authenticated());

        final first =
            await container.read(preferenceRemoteDataSourceProvider.future);
        final second =
            await container.read(preferenceRemoteDataSourceProvider.future);

        expect(second, same(first));
      });

      test('should_resolve_when_firstReadHappensInsideLoginListener',
          () async {
        answers = [];
        start(const AuthState.unauthenticated());
        final sources = <PreferenceRemoteDataSource>[];
        container.listen<AuthState>(authNotifierProvider, (previous, next) {
          unawaited(
            container
                .read(preferenceRemoteDataSourceProvider.future)
                .then(sources.add),
          );
        });

        emit(const AuthState.authenticated());
        await pumpEventQueue();

        expect(sources, hasLength(1));
      });
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
