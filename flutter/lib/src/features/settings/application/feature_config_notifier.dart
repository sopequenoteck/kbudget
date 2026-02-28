import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

part 'feature_config_notifier.freezed.dart';

@freezed
class FeatureConfigState with _$FeatureConfigState {
  const factory FeatureConfigState({
    @Default([Feature.subscriptions, Feature.debts]) List<Feature> enabledFeatures,
    @Default(false) bool isLoading,
    String? error,
  }) = _FeatureConfigState;
}

final featureConfigNotifierProvider =
    NotifierProvider<FeatureConfigNotifier, FeatureConfigState>(
  FeatureConfigNotifier.new,
);

class FeatureConfigNotifier extends Notifier<FeatureConfigState> {
  @override
  FeatureConfigState build() {
    _loadFeatures();
    return const FeatureConfigState();
  }

  Future<void> _loadFeatures() async {
    final repo = ref.read(appConfigRepositoryProvider);
    final features = await repo.getEnabledFeatures();
    state = state.copyWith(enabledFeatures: features);

    // In server mode, load from API and overwrite local
    final modeAsync = ref.read(dataModeProvider);
    final mode = modeAsync.valueOrNull;
    if (mode == DataMode.server) {
      await _loadFromServer();
    }
  }

  Future<void> _loadFromServer() async {
    try {
      state = state.copyWith(isLoading: true);
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      state = state.copyWith(
        enabledFeatures: prefs.enabledFeatures,
        isLoading: false,
        error: null,
      );
      // Sync local config
      final repo = ref.read(appConfigRepositoryProvider);
      await repo.setEnabledFeatures(prefs.enabledFeatures);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de synchronisation: $e',
      );
    }
  }

  bool isEnabled(Feature feature) {
    return state.enabledFeatures.contains(feature);
  }

  Future<void> toggleFeature(Feature feature) async {
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

    // If server mode, sync in background (fire-and-forget, optimistic)
    final modeAsync = ref.read(dataModeProvider);
    final mode = modeAsync.valueOrNull;
    if (mode == DataMode.server) {
      unawaited(_syncToServer(current));
    }
  }

  Future<void> _syncToServer(List<Feature> features) async {
    try {
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      await dataSource.updatePreferences(
        UserPreferenceRequest(enabledFeatures: features),
      );
    } on Exception catch (e) {
      state = state.copyWith(error: 'Synchronisation échouée: $e');
    }
  }
}
