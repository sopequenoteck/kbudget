import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart' as enums;
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

final themeNotifierProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light;
  }

  Future<void> _loadTheme() async {
    final repo = ref.read(appConfigRepositoryProvider);
    final theme = await repo.getTheme();
    state = theme == enums.AppTheme.dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final repo = ref.read(appConfigRepositoryProvider);
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      await repo.setTheme(enums.AppTheme.dark);
    } else {
      state = ThemeMode.light;
      await repo.setTheme(enums.AppTheme.light);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final repo = ref.read(appConfigRepositoryProvider);
    await repo.setTheme(
      mode == ThemeMode.dark ? enums.AppTheme.dark : enums.AppTheme.light,
    );
  }
}
