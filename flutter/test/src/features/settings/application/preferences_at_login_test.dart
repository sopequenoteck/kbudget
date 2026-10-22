// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/features/settings/application/language_notifier.dart';
import 'package:k_budget/src/features/settings/application/text_scale_notifier.dart';

import '../../../../helpers/display_locale.dart';
import 'language_notifier_test.dart'
    show FakeAuthNotifier, heldPreferencesDio, preferencesJson;

/// Device storage shared by the three preference notifiers, in memory.
class _DeviceConfig extends Fake implements AppConfigRepository {
  @override
  Future<String?> getLanguage() async => null;

  @override
  Future<void> setLanguage(String? language) async {}

  @override
  Future<TextScale> getTextScale() async => TextScale.medium;

  @override
  Future<void> setTextScale(TextScale textScale) async {}

  @override
  Future<List<Feature>> getEnabledFeatures() async => [Feature.budgets];

  @override
  Future<void> setEnabledFeatures(List<Feature> features) async {}

  @override
  Future<List<Feature>> getNavOrder() async => [Feature.budgets];

  @override
  Future<void> setNavOrder(List<Feature> order) async {}
}

/// The language, text size and feature notifiers all reload the server
/// preferences at login, through the real preference data source: they must
/// share one request (KKS-539), which is per session (KKS-562).
void main() {
  late List<RequestOptions> requests;
  late List<Completer<Map<String, dynamic>>> answers;
  late ProviderContainer container;
  late FakeAuthNotifier auth;

  setUp(() async {
    requests = [];
    answers = List.generate(4, (_) => Completer<Map<String, dynamic>>());
    container = ProviderContainer(
      overrides: [
        displayLocaleOverride(),
        systemLocalesProvider.overrideWithValue(const [Locale('en')]),
        appConfigRepositoryProvider.overrideWithValue(_DeviceConfig()),
        authenticatedDioProvider.overrideWith(
          (ref) async => heldPreferencesDio(requests, answers),
        ),
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(const AuthState.unauthenticated()),
        ),
      ],
    );
    container
      ..listen(languageNotifierProvider, (_, _) {})
      ..listen(textScaleNotifierProvider, (_, _) {})
      ..listen(featureConfigNotifierProvider, (_, _) {});
    auth = container.read(authNotifierProvider.notifier) as FakeAuthNotifier;
    await pumpEventQueue();
  });

  tearDown(() => container.dispose());

  test('should_sendSingleGet_when_firstLogin', () async {
    auth.emit(const AuthState.authenticated());
    await pumpEventQueue();

    expect(requests, hasLength(1));
  });

  test('should_sendSingleGet_when_anotherAccountLogsIn', () async {
    auth.emit(const AuthState.authenticated());
    await pumpEventQueue();
    answers.first.complete(preferencesJson(language: 'fr'));
    await pumpEventQueue();
    auth
      ..emit(const AuthState.unauthenticated())
      ..emit(const AuthState.authenticating())
      ..emit(const AuthState.authenticated());
    await pumpEventQueue();

    expect(requests, hasLength(2));
  });
}
