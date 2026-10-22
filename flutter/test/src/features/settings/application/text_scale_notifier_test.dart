// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_response.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/text_scale_notifier.dart';

/// Device storage of the text scale, in memory.
class FakeTextScaleConfig extends Fake implements AppConfigRepository {
  FakeTextScaleConfig([this.textScale = TextScale.medium]);

  TextScale textScale;
  final writes = <TextScale>[];

  @override
  Future<TextScale> getTextScale() async => textScale;

  @override
  Future<void> setTextScale(TextScale textScale) async {
    writes.add(textScale);
    this.textScale = textScale;
  }
}

/// Server preferences, recording every call.
class FakePreferenceDataSource extends PreferenceRemoteDataSource {
  FakePreferenceDataSource({this.textScale}) : super(Dio());

  /// Upper case, as the server sends it.
  String? textScale;
  bool failReads = false;
  int reads = 0;
  final updates = <UserPreferenceRequest>[];

  UserPreferenceResponse get _response => UserPreferenceResponse(
        enabledFeatures: const [Feature.budgets],
        navOrder: Feature.values,
        textScale: textScale,
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
    updates.add(request);
    textScale = request.textScale ?? textScale;
    return _response;
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
Completer<UserPreferenceResponse> answerWith(
  String? textScale, {
  bool ready = true,
}) {
  final answer = Completer<UserPreferenceResponse>();
  if (ready) {
    answer.complete(_account(textScale));
  }
  return answer;
}

UserPreferenceResponse _account(String? textScale) => UserPreferenceResponse(
      enabledFeatures: const [Feature.budgets],
      navOrder: Feature.values,
      textScale: textScale,
    );

/// Authentication state driven by the test.
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this.initial);

  final AuthState initial;

  @override
  AuthState build() => initial;

  void emit(AuthState next) => state = next;
}

/// Overrides every dependency of [TextScaleNotifier].
List<Override> textScaleOverrides({
  required AppConfigRepository config,
  required FakePreferenceDataSource remote,
  AuthState auth = const AuthState.authenticated(),
}) =>
    [
      appConfigRepositoryProvider.overrideWithValue(config),
      preferenceRemoteDataSourceProvider.overrideWith((ref) async => remote),
      authNotifierProvider.overrideWith(() => FakeAuthNotifier(auth)),
    ];

void main() {
  group('TextScaleNotifier', () {
    late FakeTextScaleConfig config;
    late FakePreferenceDataSource remote;
    late ProviderContainer container;

    Future<void> start({
      AuthState auth = const AuthState.authenticated(),
    }) async {
      container = ProviderContainer(
        overrides: textScaleOverrides(
          config: config,
          remote: remote,
          auth: auth,
        ),
      );
      addTearDown(container.dispose);
      container.read(textScaleNotifierProvider);
      await pumpEventQueue();
    }

    TextScaleNotifier notifier() =>
        container.read(textScaleNotifierProvider.notifier);

    TextScale textScale() => container.read(textScaleNotifierProvider);

    void emit(AuthState next) =>
        (container.read(authNotifierProvider.notifier) as FakeAuthNotifier)
            .emit(next);

    setUp(() {
      config = FakeTextScaleConfig();
      remote = FakePreferenceDataSource();
    });

    test('should_startWithMedium_when_built', () async {
      container = ProviderContainer(
        overrides: textScaleOverrides(config: config, remote: remote),
      );
      addTearDown(container.dispose);

      expect(textScale(), TextScale.medium);
      // Let the stored scale load before the container is disposed
      await pumpEventQueue();
    });

    test('should_applyStoredScale_when_notAuthenticated', () async {
      config.textScale = TextScale.large;

      await start(auth: const AuthState.unauthenticated());

      expect(textScale(), TextScale.large);
      expect(remote.reads, 0);
    });

    test('should_applyServerScale_when_authenticatedAtStart', () async {
      remote.textScale = 'LARGE';

      await start();

      expect(textScale(), TextScale.large);
      expect(config.writes, [TextScale.large]);
    });

    test('should_loadServerScale_when_userLogsIn', () async {
      remote.textScale = 'SMALL';
      await start(auth: const AuthState.unauthenticated());
      expect(textScale(), TextScale.medium);

      emit(const AuthState.authenticated());
      await pumpEventQueue();

      expect(textScale(), TextScale.small);
      expect(remote.reads, 1);
      expect(config.writes, [TextScale.small]);
    });

    test('should_keepStoredScale_when_serverIsUnreachable', () async {
      config.textScale = TextScale.large;
      remote
        ..textScale = 'SMALL'
        ..failReads = true;

      await start();

      expect(textScale(), TextScale.large);
      expect(config.writes, isEmpty);
    });

    test('should_keepStoredScale_when_serverScaleIsNull', () async {
      config.textScale = TextScale.large;

      await start();

      expect(textScale(), TextScale.large);
      expect(remote.reads, 1);
      expect(config.writes, isEmpty);
    });

    test('should_notReload_when_authStateChangesWithoutLogin', () async {
      remote.textScale = 'LARGE';
      await start();
      expect(remote.reads, 1);

      // Already authenticated: the same state is not a new login
      emit(const AuthState.authenticated());
      await pumpEventQueue();
      expect(remote.reads, 1);

      emit(const AuthState.authenticating());
      await pumpEventQueue();
      emit(const AuthState.unauthenticated());
      await pumpEventQueue();
      expect(remote.reads, 1);
    });

    test('should_reloadServerScale_when_userLogsInAgain', () async {
      remote.textScale = 'LARGE';
      await start();
      expect(remote.reads, 1);

      // Another account may sign in: its own scale replaces the previous one
      emit(const AuthState.unauthenticated());
      await pumpEventQueue();
      remote.textScale = 'SMALL';
      emit(const AuthState.authenticated());
      await pumpEventQueue();

      expect(textScale(), TextScale.small);
      expect(remote.reads, 2);
    });

    test('should_ignoreStaleResponse_when_sessionChangesDuringLoad', () async {
      final answerA = answerWith(null, ready: false);
      final queued = QueuedPreferenceDataSource([answerA, answerWith('SMALL')]);
      remote = queued;
      await start(auth: const AuthState.unauthenticated());

      emit(const AuthState.authenticated());
      await pumpEventQueue();
      emit(const AuthState.unauthenticated());
      emit(const AuthState.authenticated());
      await pumpEventQueue();
      answerA.complete(_account('LARGE'));
      await pumpEventQueue();

      expect(queued.calls, 2);
      expect(textScale(), TextScale.small);
      expect(config.writes, [TextScale.small]);
    });

    test('should_notWriteServer_when_sessionChangesDuringSync', () async {
      final held = answerWith(null, ready: false);
      final queued = QueuedPreferenceDataSource([answerWith(null), held]);
      remote = queued;
      await start();

      await notifier().setTextScale(TextScale.small);
      await pumpEventQueue();
      expect(queued.calls, 2);
      emit(const AuthState.unauthenticated());
      held.complete(_account(null));
      await pumpEventQueue();

      expect(queued.updates, isEmpty);
    });

    test('should_putScale_when_scaleSelected', () async {
      await start();

      await notifier().setTextScale(TextScale.small);
      await pumpEventQueue();

      expect(textScale(), TextScale.small);
      expect(config.writes, [TextScale.small]);
      expect(remote.updates.single.textScale, 'SMALL');
      expect(remote.updates.single.enabledFeatures, [Feature.budgets]);
    });
  });
}
