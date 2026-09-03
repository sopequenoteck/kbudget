// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/domain/enums/enums.dart' as enums;
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

const _kThemeModeKey = 'theme_mode_v2';

final themeNotifierProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    // First, try the new key (supports 'system')
    final stored = await _storage.read(key: _kThemeModeKey);
    if (stored != null) {
      state = _parseThemeMode(stored);
      return;
    }

    // Fallback: read legacy key from AppConfigRepository
    final repo = ref.read(appConfigRepositoryProvider);
    final legacyTheme = await repo.getTheme();
    state = legacyTheme == enums.AppTheme.dark ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeMode _parseThemeMode(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  String _themeModeKey(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _kThemeModeKey, value: _themeModeKey(mode));

    // Keep legacy repo in sync (light/dark only)
    final repo = ref.read(appConfigRepositoryProvider);
    final legacyValue = mode == ThemeMode.light
        ? enums.AppTheme.light
        : enums.AppTheme.dark;
    await repo.setTheme(legacyValue);
  }
}
