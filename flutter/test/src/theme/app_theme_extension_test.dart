import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

void main() {
  group('AppThemeExtension - dark instance', () {
    test('should_have_correct_business_token_values', () {
      expect(AppThemeExtension.dark.incomeColor, equals(AppColors.incomeDark));
      expect(
        AppThemeExtension.dark.incomeColor,
        equals(const Color(0xFF6DC990)),
      );
      expect(
        AppThemeExtension.dark.expenseColor,
        equals(AppColors.expenseDark),
      );
      expect(
        AppThemeExtension.dark.expenseColor,
        equals(const Color(0xFFD97777)),
      );
      expect(
        AppThemeExtension.dark.subscriptionColor,
        equals(AppColors.subscriptionDark),
      );
      expect(
        AppThemeExtension.dark.subscriptionColor,
        equals(const Color(0xFF9580D9)),
      );
      expect(
        AppThemeExtension.dark.debtOweColor,
        equals(AppColors.debtOweDark),
      );
      expect(
        AppThemeExtension.dark.debtOwedColor,
        equals(AppColors.debtOwedDark),
      );
    });

    test('should_have_correct_feedback_token_values', () {
      expect(
        AppThemeExtension.dark.textWarning,
        equals(AppColors.textWarningDark),
      );
      expect(
        AppThemeExtension.dark.textWarning,
        equals(const Color(0xFFD4AD3C)),
      );
      expect(
        AppThemeExtension.dark.textInfo,
        equals(AppColors.textInfoDark),
      );
      expect(
        AppThemeExtension.dark.textInfo,
        equals(const Color(0xFF7AACDB)),
      );
    });

    test('should_have_correct_interactive_token_values', () {
      expect(
        AppThemeExtension.dark.primarySubtle,
        equals(AppColors.primarySubtleDark),
      );
      expect(
        AppThemeExtension.dark.primaryMuted,
        equals(AppColors.primaryMutedDark),
      );
      expect(
        AppThemeExtension.dark.primaryBorder,
        equals(AppColors.primaryBorderDark),
      );
      expect(
        AppThemeExtension.dark.hoverSubtle,
        equals(AppColors.hoverSubtleDark),
      );
      expect(
        AppThemeExtension.dark.highlightSubtle,
        equals(AppColors.highlightSubtleDark),
      );
      expect(
        AppThemeExtension.dark.overlayLight,
        equals(AppColors.overlayLightDark),
      );
      expect(
        AppThemeExtension.dark.focusRing,
        equals(AppColors.focusRingDark),
      );
      expect(
        AppThemeExtension.dark.iconCircleBg,
        equals(AppColors.iconCircleBgDark),
      );
    });
  });

  group('AppThemeExtension - light instance', () {
    test('should_have_correct_business_token_values', () {
      expect(
        AppThemeExtension.light.incomeColor,
        equals(AppColors.incomeLight),
      );
      expect(
        AppThemeExtension.light.incomeColor,
        equals(const Color(0xFF16A34A)),
      );
      expect(
        AppThemeExtension.light.expenseColor,
        equals(AppColors.expenseLight),
      );
      expect(
        AppThemeExtension.light.subscriptionColor,
        equals(AppColors.subscriptionLight),
      );
    });

    test('should_have_correct_feedback_token_values', () {
      expect(
        AppThemeExtension.light.textWarning,
        equals(AppColors.textWarningLight),
      );
      expect(
        AppThemeExtension.light.textWarning,
        equals(const Color(0xFFCA8A04)),
      );
      expect(
        AppThemeExtension.light.textInfo,
        equals(AppColors.textInfoLight),
      );
      expect(
        AppThemeExtension.light.textInfo,
        equals(const Color(0xFF2563EB)),
      );
    });

    test('should_have_correct_interactive_token_values', () {
      expect(
        AppThemeExtension.light.primarySubtle,
        equals(AppColors.primarySubtleLight),
      );
      expect(
        AppThemeExtension.light.hoverSubtle,
        equals(AppColors.hoverSubtleLight),
      );
      expect(
        AppThemeExtension.light.iconCircleBg,
        equals(AppColors.iconCircleBgLight),
      );
    });
  });

  group('AppThemeExtension - lerp()', () {
    test('should_return_this_when_t_is_zero', () {
      final lerped = AppThemeExtension.dark.lerp(AppThemeExtension.light, 0.0);
      expect(lerped.incomeColor, equals(AppThemeExtension.dark.incomeColor));
      expect(lerped.textWarning, equals(AppThemeExtension.dark.textWarning));
      expect(lerped.primarySubtle, equals(AppThemeExtension.dark.primarySubtle));
    });

    test('should_return_other_when_t_is_one', () {
      final lerped = AppThemeExtension.dark.lerp(AppThemeExtension.light, 1.0);
      expect(lerped.incomeColor, equals(AppThemeExtension.light.incomeColor));
      expect(lerped.textWarning, equals(AppThemeExtension.light.textWarning));
      expect(
        lerped.primarySubtle,
        equals(AppThemeExtension.light.primarySubtle),
      );
    });

    test('should_return_this_when_other_is_null', () {
      final lerped = AppThemeExtension.dark.lerp(null, 0.5);
      expect(lerped, same(AppThemeExtension.dark));
    });
  });

  group('AppThemeExtension - copyWith()', () {
    test('should_modify_only_specified_property', () {
      const newColor = Color(0xFF123456);
      final copy = AppThemeExtension.dark.copyWith(textWarning: newColor);
      expect(copy.textWarning, equals(newColor));
      expect(copy.incomeColor, equals(AppThemeExtension.dark.incomeColor));
      expect(
        copy.primarySubtle,
        equals(AppThemeExtension.dark.primarySubtle),
      );
    });
  });
}
