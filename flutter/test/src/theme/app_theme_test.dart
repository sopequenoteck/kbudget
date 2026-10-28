import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/theme/app_theme.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/theme/k_tokens.dart';

/// Rapport de contraste WCAG 2.1 entre deux couleurs opaques.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('AppTheme - ColorScheme sur la sémantique k-design (KKS-600)', () {
    test('should_map_light_scheme_to_k_tokens_when_reading_light_theme', () {
      final cs = AppTheme.light.colorScheme;

      expect(cs.brightness, Brightness.light);
      expect(cs.primary, KTokens.colorPrimaryLight);
      expect(cs.onPrimary, KTokens.colorPrimaryContrastLight);
      expect(cs.primaryContainer, KTokens.primaryMutedLight);
      expect(cs.onPrimaryContainer, KTokens.textPrimaryLight);
      expect(cs.surface, KTokens.surfaceDefaultLight);
      expect(cs.surfaceContainerHighest, KTokens.surfaceRaisedLight);
      expect(cs.onSurface, KTokens.textPrimaryLight);
      expect(cs.onSurfaceVariant, KTokens.textSecondaryLight);
      expect(cs.outline, KTokens.borderStrongLight);
      expect(cs.outlineVariant, KTokens.borderDefaultLight);
      expect(cs.error, KTokens.textErrorLight);
      expect(cs.onError, KTokens.textInverseLight);
      expect(cs.errorContainer, KTokens.bgErrorLight);
      expect(cs.onErrorContainer, KTokens.textErrorLight);
      expect(cs.secondary, AppColors.indigo600);
    });

    test('should_map_dark_scheme_to_k_tokens_when_reading_dark_theme', () {
      final cs = AppTheme.dark.colorScheme;

      expect(cs.brightness, Brightness.dark);
      expect(cs.primary, KTokens.colorPrimaryDark);
      expect(cs.onPrimary, KTokens.colorPrimaryContrastDark);
      expect(cs.primaryContainer, KTokens.primaryMutedDark);
      expect(cs.onPrimaryContainer, KTokens.textPrimaryDark);
      expect(cs.surface, KTokens.surfaceDefaultDark);
      expect(cs.surfaceContainer, KTokens.surfaceDefaultDark);
      expect(cs.surfaceContainerHighest, KTokens.surfaceRaisedDark);
      expect(cs.onSurface, KTokens.textPrimaryDark);
      expect(cs.onSurfaceVariant, KTokens.textSecondaryDark);
      expect(cs.outline, KTokens.borderStrongDark);
      expect(cs.outlineVariant, KTokens.borderDefaultDark);
      expect(cs.error, KTokens.textErrorDark);
      expect(cs.onError, KTokens.textInverseDark);
      expect(cs.errorContainer, KTokens.bgErrorDark);
      expect(cs.onErrorContainer, KTokens.textErrorDark);
      expect(cs.secondary, AppColors.indigo400);
    });

    test('should_use_web_chrome_tokens_when_reading_light_components', () {
      final theme = AppTheme.light;

      expect(theme.scaffoldBackgroundColor, KTokens.bgPrimaryLight);
      expect(theme.appBarTheme.backgroundColor, KTokens.surfaceRaisedLight);
      expect(
        theme.bottomNavigationBarTheme.backgroundColor,
        KTokens.surfaceRaisedLight,
      );
      expect(
        theme.bottomNavigationBarTheme.selectedItemColor,
        KTokens.colorPrimaryLight,
      );
      expect(
        theme.bottomNavigationBarTheme.unselectedItemColor,
        KTokens.textSecondaryLight,
      );
      expect(
        theme.floatingActionButtonTheme.foregroundColor,
        KTokens.colorPrimaryContrastLight,
      );
      expect(
        theme.inputDecorationTheme.enabledBorder?.borderSide.color,
        KTokens.borderDefaultLight,
      );
    });

    test('should_use_web_chrome_tokens_when_reading_dark_components', () {
      final theme = AppTheme.dark;

      expect(theme.scaffoldBackgroundColor, KTokens.bgPrimaryDark);
      expect(theme.appBarTheme.backgroundColor, KTokens.surfaceRaisedDark);
      expect(
        theme.bottomNavigationBarTheme.backgroundColor,
        KTokens.surfaceRaisedDark,
      );
      expect(
        theme.bottomNavigationBarTheme.unselectedItemColor,
        KTokens.textSecondaryDark,
      );
      expect(
        theme.floatingActionButtonTheme.foregroundColor,
        KTokens.colorPrimaryContrastDark,
      );
      expect(
        theme.inputDecorationTheme.enabledBorder?.borderSide.color,
        KTokens.borderDefaultDark,
      );
    });

    test('should_contain_app_theme_extension_when_reading_both_themes', () {
      expect(
        AppTheme.light.extension<AppThemeExtension>(),
        same(AppThemeExtension.light),
      );
      expect(
        AppTheme.dark.extension<AppThemeExtension>(),
        same(AppThemeExtension.dark),
      );
    });

    test('should_use_inter_font_family', () {
      expect(AppTheme.light.textTheme.bodyMedium?.fontFamily, 'Inter');
    });
  });

  group('AppTheme - contraste AA des paires texte / fond', () {
    for (final (name, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      final cs = theme.colorScheme;
      final pairs = <String, (Color, Color)>{
        'onPrimary / primary': (cs.onPrimary, cs.primary),
        'onSurface / surface': (cs.onSurface, cs.surface),
        'onSurfaceVariant / surface': (cs.onSurfaceVariant, cs.surface),
        'onSurfaceVariant / surfaceContainerHighest': (
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest,
        ),
        'onSurface / scaffold': (cs.onSurface, theme.scaffoldBackgroundColor),
        'onError / error': (cs.onError, cs.error),
        'error / surface': (cs.error, cs.surface),
      };

      for (final MapEntry(key: pair, value: (fg, bg)) in pairs.entries) {
        test('should_reach_aa_when_reading_${pair}_in_$name', () {
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });
}
