// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_response.dart';
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
  DataMode mode = DataMode.server,
  AuthState auth = const AuthState.authenticated(),
  List<Locale> system = const [Locale('en', 'US')],
}) =>
    [
      systemLocalesProvider.overrideWithValue(system),
      appConfigRepositoryProvider.overrideWithValue(config),
      dataModeProvider.overrideWith((ref) async => mode),
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
      DataMode mode = DataMode.server,
      AuthState auth = const AuthState.authenticated(),
      List<Locale> system = const [Locale('en', 'US')],
    }) async {
      container = ProviderContainer(
        overrides: languageOverrides(
          config: config,
          remote: remote,
          mode: mode,
          auth: auth,
          system: system,
        ),
      );
      addTearDown(container.dispose);
      container.read(languageNotifierProvider);
      await pumpEventQueue();
    }

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

    test('should_useStoredPreference_when_localMode', () async {
      config.language = 'fr';

      await start(mode: DataMode.local);

      expect(language(), 'fr');
      expect(preference(), 'fr');
      expect(remote.reads, 0);
    });

    test('should_useSystemLanguage_when_localModeWithoutPreference',
        () async {
      await start(mode: DataMode.local, system: const [Locale('fr')]);

      expect(language(), 'fr');
      expect(preference(), isNull);
      expect(config.writes, isEmpty);
    });

    test('should_storeChoiceWithoutNetwork_when_localMode', () async {
      await start(mode: DataMode.local);

      await notifier().selectLanguage('fr');
      await notifier().selectLanguage(null);

      expect(config.writes, ['fr', null]);
      expect(language(), 'en');
      expect(remote.reads, 0);
      expect(remote.updates, isEmpty);
      expect(remote.clears, 0);
    });
  });
}
