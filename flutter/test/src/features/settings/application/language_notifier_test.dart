// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_response.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/features/settings/application/language_notifier.dart';

/// Device storage of the language, in memory.
class FakeLanguageConfig extends Fake implements AppConfigRepository {
  FakeLanguageConfig([this.language]);

  String? language;
  final writes = <String?>[];

  @override
  Future<String?> getLanguage() async => language;

  @override
  Future<void> setLanguage(String? language) async {
    writes.add(language);
    this.language = language;
  }
}

/// Server preferences, recording every call.
class FakePreferenceDataSource extends PreferenceRemoteDataSource {
  FakePreferenceDataSource({this.language}) : super(Dio());

  String? language;
  bool failReads = false;
  bool failWrites = false;
  int reads = 0;
  int clears = 0;
  final updates = <UserPreferenceRequest>[];

  UserPreferenceResponse get _response => UserPreferenceResponse(
        enabledFeatures: const [Feature.budgets],
        navOrder: Feature.values,
        language: language,
      );

  @override
  Future<UserPreferenceResponse> getPreferences() async {
    reads++;
    if (failReads) {
      throw DioException(requestOptions: RequestOptions());
    }
    return _response;
  }

  @override
  Future<UserPreferenceResponse> updatePreferences(
    UserPreferenceRequest request,
  ) async {
    if (failWrites) {
      throw DioException(requestOptions: RequestOptions());
    }
    updates.add(request);
    language = request.language ?? language;
    return _response;
  }

  @override
  Future<void> clearLanguage() async {
    if (failWrites) {
      throw DioException(requestOptions: RequestOptions());
    }
    clears++;
    language = null;
  }
}

/// Server preferences whose n-th read answers when `answers[n]` completes.
class QueuedPreferenceDataSource extends FakePreferenceDataSource {
  QueuedPreferenceDataSource(this.answers);

  final List<Completer<UserPreferenceResponse>> answers;
  int calls = 0;

  @override
  Future<UserPreferenceResponse> getPreferences() => answers[calls++].future;
}

/// Preferences of an account, as the server answers them.
UserPreferenceResponse accountPreferences(String? language) =>
    UserPreferenceResponse(
      enabledFeatures: const [Feature.budgets],
      navOrder: Feature.values,
      language: language,
    );

/// An answer that is already there.
Completer<UserPreferenceResponse> readyAnswer(
  UserPreferenceResponse response,
) =>
    Completer<UserPreferenceResponse>()..complete(response);

/// A Dio recording its requests, whose n-th answer arrives when
/// `answers[n]` completes.
Dio heldPreferencesDio(
  List<RequestOptions> requests,
  List<Completer<Map<String, dynamic>>> answers,
) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final index = requests.length;
          requests.add(options);
          final data = await answers[index].future;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
}

/// Preferences of an account as JSON, the way the server sends them.
Map<String, dynamic> preferencesJson({String? language}) => {
      'enabledFeatures': ['BUDGETS'],
      'navOrder': ['BUDGETS'],
      'language': language,
    };

/// Authentication state driven by the test.
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this.initial);

  final AuthState initial;

  @override
  AuthState build() => initial;

  void emit(AuthState next) => state = next;
}

/// Overrides every dependency of [LanguageNotifier].
List<Override> languageOverrides({
  required AppConfigRepository config,
  required FakePreferenceDataSource remote,
  AuthState auth = const AuthState.authenticated(),
  List<Locale> system = const [Locale('en', 'US')],
}) =>
    [
      systemLocalesProvider.overrideWithValue(system),
      appConfigRepositoryProvider.overrideWithValue(config),
      preferenceRemoteDataSourceProvider.overrideWith((ref) async => remote),
      authNotifierProvider.overrideWith(() => FakeAuthNotifier(auth)),
    ];

void main() {
  group('supportedLanguageOf', () {
    test('should_returnNull_when_codeIsNullOrEmpty', () {
      expect(supportedLanguageOf(null), isNull);
      expect(supportedLanguageOf(''), isNull);
    });

    test('should_keepLanguage_when_codeIsRegionalOrUppercase', () {
      expect(supportedLanguageOf('fr-CA'), 'fr');
      expect(supportedLanguageOf('EN'), 'en');
      expect(supportedLanguageOf('en-GB'), 'en');
    });

    test('should_returnNull_when_languageIsNotSupported', () {
      expect(supportedLanguageOf('pt-BR'), isNull);
      expect(supportedLanguageOf('de'), isNull);
    });
  });

  group('detectSystemLanguage', () {
    test('should_returnFirstSupportedLanguage_when_listHasRegionalCodes', () {
      expect(
        detectSystemLanguage(const [Locale('pt', 'BR'), Locale('fr', 'CA')]),
        'fr',
      );
    });

    test('should_returnEnglish_when_noLanguageIsSupported', () {
      expect(detectSystemLanguage(const [Locale('de'), Locale('pt')]), 'en');
    });

    test('should_returnEnglish_when_listIsEmpty', () {
      expect(detectSystemLanguage(const []), 'en');
    });
  });

  group('LanguageNotifier', () {
    late FakeLanguageConfig config;
    late FakePreferenceDataSource remote;
    late ProviderContainer container;

    Future<void> start({
          AuthState auth = const AuthState.authenticated(),
      List<Locale> system = const [Locale('en', 'US')],
    }) async {
      container = ProviderContainer(
        overrides: languageOverrides(
          config: config,
          remote: remote,
          auth: auth,
          system: system,
        ),
      );
      addTearDown(container.dispose);
      container.read(languageNotifierProvider);
      await pumpEventQueue();
    }

    Future<void> startWith(FakePreferenceDataSource source) async {
      remote = source;
      await start();
    }

    void emit(AuthState next) =>
        (container.read(authNotifierProvider.notifier) as FakeAuthNotifier)
            .emit(next);

    LanguageNotifier notifier() =>
        container.read(languageNotifierProvider.notifier);

    String language() => container.read(languageNotifierProvider).language;

    String? preference() =>
        container.read(languageNotifierProvider).preference;

    setUp(() {
      config = FakeLanguageConfig();
      remote = FakePreferenceDataSource();
    });

    test('should_startWithSystemLanguage_when_built', () async {
      container = ProviderContainer(
        overrides: languageOverrides(
          config: config,
          remote: remote,
          system: const [Locale('fr', 'CA')],
        ),
      );
      addTearDown(container.dispose);

      expect(language(), 'fr');
      expect(container.read(displayLocaleProvider), const Locale('fr'));
      // Let the stored language load before the container is disposed
      await pumpEventQueue();
    });

    test('should_applyServerPreference_when_preferenceIsSet', () async {
      remote.language = 'fr';

      await start();

      expect(language(), 'fr');
      expect(preference(), 'fr');
      expect(config.language, 'fr');
      expect(container.read(intlLocaleProvider), 'fr_FR');
    });

    test('should_applySystemLanguage_when_serverPreferenceIsNull', () async {
      config.language = 'fr';

      await start(system: const [Locale('en', 'GB')]);

      expect(language(), 'en');
      expect(preference(), isNull);
      expect(config.language, 'en');
    });

    test('should_applySystemLanguage_when_preferenceIsNotSupported',
        () async {
      remote.language = 'pt-BR';

      await start(system: const [Locale('fr')]);

      expect(language(), 'fr');
      expect(preference(), isNull);
    });

    test('should_applyStoredLanguage_when_preferenceIsNotLoaded', () async {
      config.language = 'fr';

      await start(auth: const AuthState.initial());

      expect(language(), 'fr');
      expect(remote.reads, 0);
    });

    test('should_keepStoredLanguage_when_serverIsUnreachable', () async {
      config.language = 'fr';
      remote
        ..language = 'en'
        ..failReads = true;

      await start();

      expect(language(), 'fr');
    });

    test('should_loadPreference_when_userLogsIn', () async {
      remote.language = 'fr';
      await start(auth: const AuthState.unauthenticated());
      expect(language(), 'en');

      (container.read(authNotifierProvider.notifier) as FakeAuthNotifier)
          .emit(const AuthState.authenticated());
      await pumpEventQueue();

      expect(language(), 'fr');
      expect(remote.reads, 1);
    });

    test('should_ignoreStaleResponse_when_sessionChangesDuringLoad', () async {
      final answerA = Completer<UserPreferenceResponse>();
      final queued = QueuedPreferenceDataSource([
        answerA,
        readyAnswer(accountPreferences('en')),
      ]);
      container = ProviderContainer(
        overrides: languageOverrides(
          config: config,
          remote: queued,
          auth: const AuthState.unauthenticated(),
        ),
      );
      addTearDown(container.dispose);
      container.read(languageNotifierProvider);
      await pumpEventQueue();

      emit(const AuthState.authenticated());
      await pumpEventQueue();
      emit(const AuthState.unauthenticated());
      emit(const AuthState.authenticated());
      await pumpEventQueue();
      answerA.complete(accountPreferences('fr'));
      await pumpEventQueue();

      expect(queued.calls, 2);
      expect(language(), 'en');
      expect(preference(), 'en');
      expect(config.writes, ['en']);
    });

    test('should_notWriteServer_when_sessionChangesDuringSelect', () async {
      final held = Completer<UserPreferenceResponse>();
      final queued = QueuedPreferenceDataSource([
        readyAnswer(accountPreferences(null)),
        held,
      ]);
      await startWith(queued);

      final selection = notifier().selectLanguage('fr');
      await pumpEventQueue();
      emit(const AuthState.unauthenticated());
      held.complete(accountPreferences(null));
      await selection;

      expect(queued.updates, isEmpty);
      expect(config.writes, ['en']);
    });

    test('should_notClearLanguage_when_sessionChangesDuringSelect', () async {
      remote.language = 'fr';
      await start();

      final selection = notifier().selectLanguage(null);
      emit(const AuthState.unauthenticated());
      await selection;

      expect(remote.clears, 0);
      expect(config.writes, ['fr']);
    });

    test('should_keepNewAccountLanguage_when_staleWriteFails', () async {
      final held = Completer<UserPreferenceResponse>();
      final queued = QueuedPreferenceDataSource([
        readyAnswer(accountPreferences(null)),
        held,
        readyAnswer(accountPreferences('fr')),
      ]);
      await startWith(queued);

      final selection = notifier().selectLanguage('fr');
      await pumpEventQueue();
      emit(const AuthState.unauthenticated());
      emit(const AuthState.authenticated());
      await pumpEventQueue();
      expect(language(), 'fr');
      held.completeError(DioException(requestOptions: RequestOptions()));
      await selection;

      expect(language(), 'fr');
      expect(preference(), 'fr');
    });

    test('should_applyNewAccountLanguage_when_previousReadStillInFlight',
        () async {
      final requests = <RequestOptions>[];
      final answerA = Completer<Map<String, dynamic>>();
      final dio = heldPreferencesDio(requests, [
        answerA,
        Completer<Map<String, dynamic>>()
          ..complete(preferencesJson(language: 'en')),
      ]);
      container = ProviderContainer(
        overrides: [
          systemLocalesProvider.overrideWithValue(const [Locale('de')]),
          appConfigRepositoryProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthState.unauthenticated()),
          ),
          authenticatedDioProvider.overrideWith((ref) async => dio),
        ],
      );
      addTearDown(container.dispose);
      container.read(languageNotifierProvider);
      await pumpEventQueue();

      emit(const AuthState.authenticated());
      await pumpEventQueue();
      emit(const AuthState.unauthenticated());
      emit(const AuthState.authenticated());
      await pumpEventQueue();
      answerA.complete(preferencesJson(language: 'fr'));
      await pumpEventQueue();

      expect(requests, hasLength(2));
      expect(language(), 'en');
      expect(preference(), 'en');
    });

    test('should_putLanguage_when_languageSelected', () async {
      await start();

      await notifier().selectLanguage('fr');

      expect(language(), 'fr');
      expect(preference(), 'fr');
      expect(remote.updates.single.language, 'fr');
      expect(remote.updates.single.enabledFeatures, [Feature.budgets]);
      expect(config.language, 'fr');
    });

    test('should_deleteLanguage_when_autoSelected', () async {
      remote.language = 'fr';
      await start();

      await notifier().selectLanguage(null);

      expect(remote.clears, 1);
      expect(remote.updates, isEmpty);
      expect(language(), 'en');
      expect(preference(), isNull);
    });

    test('should_doNothing_when_sameLanguageSelected', () async {
      remote.language = 'fr';
      await start();

      await notifier().selectLanguage('fr');

      expect(remote.updates, isEmpty);
      expect(remote.clears, 0);
    });

    test('should_restorePreviousLanguage_when_serverWriteFails', () async {
      await start();
      remote.failWrites = true;

      await notifier().selectLanguage('fr');

      expect(language(), 'en');
      expect(preference(), isNull);
    });

    test('should_restorePreviousLanguage_when_deleteFails', () async {
      remote.language = 'fr';
      await start();
      remote.failWrites = true;

      await notifier().selectLanguage(null);

      expect(language(), 'fr');
      expect(preference(), 'fr');
    });
  });
}
