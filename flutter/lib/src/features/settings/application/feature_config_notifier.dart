// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';

part 'feature_config_notifier.freezed.dart';

@freezed
class FeatureConfigState with _$FeatureConfigState {
  const factory FeatureConfigState({
    @Default([Feature.subscriptions, Feature.debts]) List<Feature> enabledFeatures,
    @Default(Feature.values) List<Feature> navOrder,
    @Default(NotificationType.values) List<NotificationType> enabledNotificationTypes,
    @Default('Europe/Paris') String timezone,
    @Default(false) bool isLoading,
    String? error,
  }) = _FeatureConfigState;
}

final featureConfigNotifierProvider =
    NotifierProvider<FeatureConfigNotifier, FeatureConfigState>(
  FeatureConfigNotifier.new,
);

/// Fonctionnalites et preferences du compte connecte, lues sur le serveur.
class FeatureConfigNotifier extends Notifier<FeatureConfigState>
    with SessionGuard {
  @override
  FeatureConfigState build() {
    bindSession(ref);
    // The server preference needs a session: read it at each login, not
    // only at start, when no token may exist yet or the account may change
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated && previous is! AuthAuthenticated) {
        unawaited(_loadFromServer());
      }
    });
    _loadFeatures();
    return const FeatureConfigState();
  }

  Future<void> _loadFeatures() async {
    final repo = ref.read(appConfigRepositoryProvider);
    final features = await repo.getEnabledFeatures();
    final navOrder = await repo.getNavOrder();
    state = state.copyWith(enabledFeatures: features, navOrder: navOrder);

    // Load from API and overwrite local, once a session exists
    if (ref.read(authNotifierProvider) is AuthAuthenticated) {
      await _loadFromServer();
    }
  }

  Future<void> _loadFromServer() async {
    final token = session;
    try {
      state = state.copyWith(isLoading: true);
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        enabledFeatures: prefs.enabledFeatures,
        navOrder: prefs.navOrder,
        enabledNotificationTypes: prefs.enabledNotificationTypes.isEmpty
            ? NotificationType.values.toList()
            : prefs.enabledNotificationTypes,
        timezone: prefs.timezone,
        isLoading: false,
        error: null,
      );
      // Sync local config
      final repo = ref.read(appConfigRepositoryProvider);
      await repo.setEnabledFeatures(prefs.enabledFeatures);
      if (isStale(token)) {
        return;
      }
      await repo.setNavOrder(prefs.navOrder);
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).settingsFeedbackLoadError,
      );
    }
  }

  bool isEnabled(Feature feature) {
    return state.enabledFeatures.contains(feature);
  }

  Future<void> toggleFeature(Feature feature) async {
    final token = session;
    final current = List<Feature>.from(state.enabledFeatures);
    if (current.contains(feature)) {
      current.remove(feature);
    } else {
      current.add(feature);
    }
    state = state.copyWith(enabledFeatures: current, error: null);

    // Persist locally
    final repo = ref.read(appConfigRepositoryProvider);
    await repo.setEnabledFeatures(current);

    // Sync in background (fire-and-forget, optimistic)
    unawaited(_syncToServer(
      current,
      token,
      navOrder: state.navOrder,
      enabledNotificationTypes: state.enabledNotificationTypes,
      timezone: state.timezone,
    ));
  }

  Future<void> reorderNavigation(List<Feature> newOrder) async {
    final token = session;
    state = state.copyWith(navOrder: newOrder, error: null);

    // Persist locally
    final repo = ref.read(appConfigRepositoryProvider);
    await repo.setNavOrder(newOrder);

    // Sync in background
    unawaited(_syncToServer(
      state.enabledFeatures,
      token,
      navOrder: newOrder,
      enabledNotificationTypes: state.enabledNotificationTypes,
      timezone: state.timezone,
    ));
  }

  Future<void> updateNotificationTypes(List<NotificationType> types) async {
    state = state.copyWith(enabledNotificationTypes: types, error: null);

    unawaited(_syncToServer(
      state.enabledFeatures,
      session,
      navOrder: state.navOrder,
      enabledNotificationTypes: types,
      timezone: state.timezone,
    ));
  }

  Future<void> updateTimezone(String timezone) async {
    state = state.copyWith(timezone: timezone, error: null);

    unawaited(_syncToServer(
      state.enabledFeatures,
      session,
      navOrder: state.navOrder,
      enabledNotificationTypes: state.enabledNotificationTypes,
      timezone: timezone,
    ));
  }

  Future<void> _syncToServer(
    List<Feature> features,
    int token, {
    List<Feature>? navOrder,
    List<NotificationType>? enabledNotificationTypes,
    String? timezone,
  }) async {
    try {
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      if (isStale(token)) {
        return;
      }
      await dataSource.updatePreferences(
        UserPreferenceRequest(
          enabledFeatures: features,
          navOrder: navOrder,
          enabledNotificationTypes: enabledNotificationTypes,
          timezone: timezone,
        ),
      );
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        error: ref.read(appLocalizationsProvider).settingsFeedbackSaveError,
      );
    }
  }
}
