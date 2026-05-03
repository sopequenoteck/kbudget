import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/theme/app_theme.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

void main() {
  group('AppTheme', () {
    test('should_use_amber_600_as_primary_in_light_theme', () {
      final theme = AppTheme.light;

      expect(theme.colorScheme.primary, AppColors.amber600);
      expect(theme.brightness, Brightness.light);
    });

    test('should_use_gray_50_as_scaffold_bg_in_light_theme', () {
      final theme = AppTheme.light;

      expect(theme.scaffoldBackgroundColor, AppColors.gray50);
    });

    test('should_use_primary_amber_dark_as_primary_in_dark_theme', () {
      final theme = AppTheme.dark;

      expect(theme.colorScheme.primary, AppColors.primaryAmberDark);
      expect(theme.brightness, Brightness.dark);
    });

    test('should_use_gray_900_as_scaffold_bg_in_dark_theme', () {
      final theme = AppTheme.dark;

      expect(theme.scaffoldBackgroundColor, AppColors.gray900);
    });

    test('should_contain_app_theme_extension_in_light', () {
      final theme = AppTheme.light;
      final ext = theme.extension<AppThemeExtension>();

      expect(ext, isNotNull);
      expect(ext!.incomeColor, AppColors.incomeLight);
      expect(ext.expenseColor, AppColors.expenseLight);
    });

    test('should_contain_app_theme_extension_in_dark', () {
      final theme = AppTheme.dark;
      final ext = theme.extension<AppThemeExtension>();

      expect(ext, isNotNull);
      expect(ext!.incomeColor, AppColors.incomeDark);
      expect(ext.expenseColor, AppColors.expenseDark);
    });

    test('should_use_inter_font_family', () {
      final theme = AppTheme.light;

      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    });
  });
}
