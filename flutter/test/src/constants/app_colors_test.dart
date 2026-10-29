import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/theme/k_tokens.dart';

/// Chaque couleur portée par k-design est un alias de KTokens (KKS-589).
void main() {
  group('AppColors - alias de KTokens', () {
    const aliases = <String, (Color, Color)>{
      'amber50': (AppColors.amber50, KTokens.amber50Dark),
      'amber100': (AppColors.amber100, KTokens.amber100Dark),
      'amber200': (AppColors.amber200, KTokens.amber200Dark),
      'amber300': (AppColors.amber300, KTokens.amber300Dark),
      'amber400': (AppColors.amber400, KTokens.amber400Dark),
      'amber500': (AppColors.amber500, KTokens.amber500Dark),
      'amber600': (AppColors.amber600, KTokens.amber600Dark),
      'amber700': (AppColors.amber700, KTokens.amber700Dark),
      'amber800': (AppColors.amber800, KTokens.amber800Dark),
      'amber900': (AppColors.amber900, KTokens.amber900Dark),
      'gray50': (AppColors.gray50, KTokens.gray50Dark),
      'gray100': (AppColors.gray100, KTokens.gray100Dark),
      'gray200': (AppColors.gray200, KTokens.gray200Dark),
      'gray300': (AppColors.gray300, KTokens.gray300Dark),
      'gray400': (AppColors.gray400, KTokens.gray400Dark),
      'gray500': (AppColors.gray500, KTokens.gray500Dark),
      'gray600': (AppColors.gray600, KTokens.gray600Dark),
      'gray700': (AppColors.gray700, KTokens.gray700Dark),
      'gray800': (AppColors.gray800, KTokens.gray800Dark),
      'gray900': (AppColors.gray900, KTokens.gray900Dark),
      'success': (AppColors.success, KTokens.colorSuccessRawDark),
      'error': (AppColors.error, KTokens.colorErrorRawDark),
      'warning': (AppColors.warning, KTokens.colorWarningRawDark),
      'info': (AppColors.info, KTokens.colorInfoRawDark),
      'bgPrimaryLight': (AppColors.bgPrimaryLight, KTokens.bgPrimaryLight),
      'surfaceDefaultLight': (
        AppColors.surfaceDefaultLight,
        KTokens.surfaceDefaultLight,
      ),
      'surfaceRaisedLight': (
        AppColors.surfaceRaisedLight,
        KTokens.surfaceRaisedLight,
      ),
      'textPrimaryLight': (
        AppColors.textPrimaryLight,
        KTokens.textPrimaryLight,
      ),
      'textSecondaryLight': (
        AppColors.textSecondaryLight,
        KTokens.textSecondaryLight,
      ),
      'textTertiaryLight': (
        AppColors.textTertiaryLight,
        KTokens.textTertiaryLight,
      ),
      'textInverseLight': (
        AppColors.textInverseLight,
        KTokens.textInverseLight,
      ),
      'borderDefaultLight': (
        AppColors.borderDefaultLight,
        KTokens.borderDefaultLight,
      ),
      'borderStrongLight': (
        AppColors.borderStrongLight,
        KTokens.borderStrongLight,
      ),
      'primaryAmberContrastLight': (
        AppColors.primaryAmberContrastLight,
        KTokens.colorPrimaryContrastLight,
      ),
      'textErrorLight': (AppColors.textErrorLight, KTokens.textErrorLight),
      'primaryAmberLight': (
        AppColors.primaryAmberLight,
        KTokens.colorPrimaryLight,
      ),
      'bgPrimaryDark': (AppColors.bgPrimaryDark, KTokens.bgPrimaryDark),
      'surfaceDefaultDark': (
        AppColors.surfaceDefaultDark,
        KTokens.surfaceDefaultDark,
      ),
      'surfaceRaisedDark': (
        AppColors.surfaceRaisedDark,
        KTokens.surfaceRaisedDark,
      ),
      'textPrimaryDark': (AppColors.textPrimaryDark, KTokens.textPrimaryDark),
      'textSecondaryDark': (
        AppColors.textSecondaryDark,
        KTokens.textSecondaryDark,
      ),
      'textTertiaryDark': (
        AppColors.textTertiaryDark,
        KTokens.textTertiaryDark,
      ),
      'textInverseDark': (AppColors.textInverseDark, KTokens.textInverseDark),
      'borderDefaultDark': (
        AppColors.borderDefaultDark,
        KTokens.borderDefaultDark,
      ),
      'borderStrongDark': (
        AppColors.borderStrongDark,
        KTokens.borderStrongDark,
      ),
      'primaryAmberContrastDark': (
        AppColors.primaryAmberContrastDark,
        KTokens.colorPrimaryContrastDark,
      ),
      'textErrorDark': (AppColors.textErrorDark, KTokens.textErrorDark),
      'bgErrorDark': (AppColors.bgErrorDark, KTokens.bgErrorDark),
      'successLight': (AppColors.successLight, KTokens.bgSuccessLight),
      'warningLight': (AppColors.warningLight, KTokens.bgWarningLight),
      'errorLight': (AppColors.errorLight, KTokens.bgErrorLight),
      'infoLight': (AppColors.infoLight, KTokens.bgInfoLight),
      'textSuccess': (AppColors.textSuccess, KTokens.textSuccessLight),
      'textError': (AppColors.textError, KTokens.textErrorLight),
      'textWarning': (AppColors.textWarning, KTokens.textWarningLight),
      'textInfo': (AppColors.textInfo, KTokens.textInfoLight),
      'textWarningLight': (
        AppColors.textWarningLight,
        KTokens.textWarningLight,
      ),
      'textInfoLight': (AppColors.textInfoLight, KTokens.textInfoLight),
      'incomeLight': (AppColors.incomeLight, KTokens.colorIncomeLight),
      'expenseLight': (AppColors.expenseLight, KTokens.colorExpenseLight),
      'debtOweLight': (AppColors.debtOweLight, KTokens.colorDebtOweLight),
      'debtOwedLight': (AppColors.debtOwedLight, KTokens.colorDebtOwedLight),
      'subscriptionLight': (
        AppColors.subscriptionLight,
        KTokens.colorSubscriptionLight,
      ),
      'primarySubtleLight': (
        AppColors.primarySubtleLight,
        KTokens.primarySubtleLight,
      ),
      'primaryMutedLight': (
        AppColors.primaryMutedLight,
        KTokens.primaryMutedLight,
      ),
      'primaryBorderLight': (
        AppColors.primaryBorderLight,
        KTokens.primaryBorderLight,
      ),
      'hoverBgLight': (AppColors.hoverBgLight, KTokens.hoverBgLight),
      'hoverSubtleLight': (
        AppColors.hoverSubtleLight,
        KTokens.hoverSubtleLight,
      ),
      'highlightSubtleLight': (
        AppColors.highlightSubtleLight,
        KTokens.highlightSubtleLight,
      ),
      'overlayLightOnLight': (
        AppColors.overlayLightOnLight,
        KTokens.overlayLightLight,
      ),
      'focusRingLight': (AppColors.focusRingLight, KTokens.focusRingLight),
      'iconCircleBgLight': (
        AppColors.iconCircleBgLight,
        KTokens.iconCircleBgLight,
      ),
      'primaryAmberDark': (
        AppColors.primaryAmberDark,
        KTokens.colorPrimaryDark,
      ),
      'primaryAmberHoverDark': (
        AppColors.primaryAmberHoverDark,
        KTokens.colorPrimaryHoverDark,
      ),
      'textWarningDark': (AppColors.textWarningDark, KTokens.textWarningDark),
      'textInfoDark': (AppColors.textInfoDark, KTokens.textInfoDark),
      'incomeDark': (AppColors.incomeDark, KTokens.colorIncomeDark),
      'expenseDark': (AppColors.expenseDark, KTokens.colorExpenseDark),
      'subscriptionDark': (
        AppColors.subscriptionDark,
        KTokens.colorSubscriptionDark,
      ),
      'debtOweDark': (AppColors.debtOweDark, KTokens.colorDebtOweDark),
      'debtOwedDark': (AppColors.debtOwedDark, KTokens.colorDebtOwedDark),
      'primarySubtleDark': (
        AppColors.primarySubtleDark,
        KTokens.primarySubtleDark,
      ),
      'primaryMutedDark': (
        AppColors.primaryMutedDark,
        KTokens.primaryMutedDark,
      ),
      'primaryBorderDark': (
        AppColors.primaryBorderDark,
        KTokens.primaryBorderDark,
      ),
      'hoverBgDark': (AppColors.hoverBgDark, KTokens.hoverBgDark),
      'hoverSubtleDark': (AppColors.hoverSubtleDark, KTokens.hoverSubtleDark),
      'highlightSubtleDark': (
        AppColors.highlightSubtleDark,
        KTokens.highlightSubtleDark,
      ),
      'overlayLightOnDark': (
        AppColors.overlayLightOnDark,
        KTokens.overlayLightDark,
      ),
      'focusRingDark': (AppColors.focusRingDark, KTokens.focusRingDark),
      'iconCircleBgDark': (
        AppColors.iconCircleBgDark,
        KTokens.iconCircleBgDark,
      ),
    };

    for (final MapEntry(key: name, value: (actual, token)) in aliases.entries) {
      test('should_equal_k_token_when_reading_$name', () {
        expect(actual, equals(token));
      });
    }

    test('should_use_d13_light_values_when_reading_business_colors', () {
      expect(AppColors.incomeLight, equals(const Color(0xFF166534)));
      expect(AppColors.expenseLight, equals(const Color(0xFFB91C1C)));
      expect(AppColors.textWarningLight, equals(const Color(0xFF854D0E)));
      expect(AppColors.textInfoLight, equals(const Color(0xFF1D4ED8)));
    });
  });

  group('AppColors - source', () {
    test('should_keep_hex_literals_in_local_section_when_reading_file', () {
      final source =
          File('lib/src/constants/app_colors.dart').readAsStringSync();
      const marker = 'Couleurs locales, sans équivalent k-design';
      final markerIndex = source.indexOf(marker);

      expect(markerIndex, isNonNegative);
      expect(source.substring(0, markerIndex), isNot(contains('Color(0x')));
    });
  });

  group('KTokens - en-tête', () {
    test('should_state_k_design_version_when_reading_generated_file', () {
      final header = File('lib/src/theme/k_tokens.dart')
          .readAsLinesSync()
          .take(6)
          .join('\n');

      // Plus d'en-tete MPL depuis k-design v0.4.0 (D16 caduque) : le fichier est
      // exclu du controle de licence de ci-flutter.yml (KKS-595).
      expect(header, matches(RegExp(r'K Design v\d+\.\d+\.\d+')));
    });
  });
}
