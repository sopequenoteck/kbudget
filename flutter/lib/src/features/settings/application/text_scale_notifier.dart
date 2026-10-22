// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

final textScaleNotifierProvider =
    NotifierProvider<TextScaleNotifier, TextScale>(TextScaleNotifier.new);

/// Taille du texte, lue et ecrite sur les preferences du compte connecte.
class TextScaleNotifier extends Notifier<TextScale> with SessionGuard {
  @override
  TextScale build() {
    bindSession(ref);
    // The server preference needs a session: read it at each login, not
    // only at start, when no token may exist yet or the account may change
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated && previous is! AuthAuthenticated) {
        unawaited(_loadServerTextScale());
      }
    });
    _loadTextScale();
    return TextScale.medium;
  }

  Future<void> _loadTextScale() async {
    final repo = ref.read(appConfigRepositoryProvider);
    final textScale = await repo.getTextScale();
    state = textScale;

    if (ref.read(authNotifierProvider) is AuthAuthenticated) {
      await _loadServerTextScale();
    }
  }

  Future<void> _loadServerTextScale() async {
    final token = session;
    final repo = ref.read(appConfigRepositoryProvider);
    try {
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      if (isStale(token)) {
        return;
      }
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

  Future<void> setTextScale(TextScale textScale) async {
    final token = session;
    state = textScale;
    final repo = ref.read(appConfigRepositoryProvider);
    await repo.setTextScale(textScale);

    unawaited(_syncToServer(textScale, token));
  }

  Future<void> _syncToServer(TextScale textScale, int token) async {
    try {
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      if (isStale(token)) {
        return;
      }
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
