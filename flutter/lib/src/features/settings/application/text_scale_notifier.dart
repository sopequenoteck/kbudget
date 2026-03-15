import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

final textScaleNotifierProvider =
    NotifierProvider<TextScaleNotifier, TextScale>(TextScaleNotifier.new);

class TextScaleNotifier extends Notifier<TextScale> {
  @override
  TextScale build() {
    _loadTextScale();
    return TextScale.medium;
  }

  Future<void> _loadTextScale() async {
    final repo = ref.read(appConfigRepositoryProvider);
    final textScale = await repo.getTextScale();
    state = textScale;

    final modeAsync = ref.read(dataModeProvider);
    final mode = modeAsync.valueOrNull;
    if (mode == DataMode.server) {
      try {
        final dataSource =
            await ref.read(preferenceRemoteDataSourceProvider.future);
        final prefs = await dataSource.getPreferences();
        if (prefs.textScale != null) {
          final serverScale =
              TextScale.values.byName(prefs.textScale!.toLowerCase());
          state = serverScale;
          await repo.setTextScale(serverScale);
        }
      } on Exception catch (_) {
        // Silently fail — local value already loaded
      }
    }
  }

  Future<void> setTextScale(TextScale textScale) async {
    state = textScale;
    final repo = ref.read(appConfigRepositoryProvider);
    await repo.setTextScale(textScale);

    final modeAsync = ref.read(dataModeProvider);
    final mode = modeAsync.valueOrNull;
    if (mode == DataMode.server) {
      unawaited(_syncToServer(textScale));
    }
  }

  Future<void> _syncToServer(TextScale textScale) async {
    try {
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      await dataSource.updatePreferences(
        UserPreferenceRequest(
          enabledFeatures: prefs.enabledFeatures,
          textScale: textScale.name.toUpperCase(),
        ),
      );
    } on Exception catch (_) {
      // Fire-and-forget — no error state needed
    }
  }
}
