// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:ui';

import 'package:k_budget/src/theme/k_tokens.dart';

/// Couleurs de l'app. Les valeurs portées par k-design sont des alias de
/// [KTokens] (`lib/src/theme/k_tokens.dart`, copie de k-design par son
/// `scripts/sync.mjs`, KKS-589) : ne jamais y écrire de littéral. Seules les
/// couleurs sans équivalent k-design, regroupées en fin de classe, restent
/// locales.
class AppColors {
  AppColors._();

  // ===== Primitives k-design (identiques dans les deux thèmes) =====

  // Ambre
  /// Alias de [KTokens.amber50Dark].
  static const Color amber50 = KTokens.amber50Dark;
  /// Alias de [KTokens.amber100Dark].
  static const Color amber100 = KTokens.amber100Dark;
  /// Alias de [KTokens.amber200Dark].
  static const Color amber200 = KTokens.amber200Dark;
  /// Alias de [KTokens.amber300Dark].
  static const Color amber300 = KTokens.amber300Dark;
  /// Alias de [KTokens.amber400Dark].
  static const Color amber400 = KTokens.amber400Dark;
  /// Alias de [KTokens.amber500Dark].
  static const Color amber500 = KTokens.amber500Dark;
  /// Alias de [KTokens.amber600Dark].
  static const Color amber600 = KTokens.amber600Dark;
  /// Alias de [KTokens.amber700Dark].
  static const Color amber700 = KTokens.amber700Dark;
  /// Alias de [KTokens.amber800Dark].
  static const Color amber800 = KTokens.amber800Dark;
  /// Alias de [KTokens.amber900Dark].
  static const Color amber900 = KTokens.amber900Dark;

  // Gris
  /// Alias de [KTokens.gray50Dark].
  static const Color gray50 = KTokens.gray50Dark;
  /// Alias de [KTokens.gray100Dark].
  static const Color gray100 = KTokens.gray100Dark;
  /// Alias de [KTokens.gray200Dark].
  static const Color gray200 = KTokens.gray200Dark;
  /// Alias de [KTokens.gray300Dark].
  static const Color gray300 = KTokens.gray300Dark;
  /// Alias de [KTokens.gray400Dark].
  static const Color gray400 = KTokens.gray400Dark;
  /// Alias de [KTokens.gray500Dark].
  static const Color gray500 = KTokens.gray500Dark;
  /// Alias de [KTokens.gray600Dark].
  static const Color gray600 = KTokens.gray600Dark;
  /// Alias de [KTokens.gray700Dark].
  static const Color gray700 = KTokens.gray700Dark;
  /// Alias de [KTokens.gray800Dark].
  static const Color gray800 = KTokens.gray800Dark;
  /// Alias de [KTokens.gray900Dark].
  static const Color gray900 = KTokens.gray900Dark;

  // Feedback, teinte brute
  /// Alias de [KTokens.colorSuccessRawDark].
  static const Color success = KTokens.colorSuccessRawDark;
  /// Alias de [KTokens.colorErrorRawDark].
  static const Color error = KTokens.colorErrorRawDark;
  /// Alias de [KTokens.colorWarningRawDark].
  static const Color warning = KTokens.colorWarningRawDark;
  /// Alias de [KTokens.colorInfoRawDark].
  static const Color info = KTokens.colorInfoRawDark;

  // ===== Thème clair =====

  // Fonds de feedback
  /// Alias de [KTokens.bgSuccessLight].
  static const Color successLight = KTokens.bgSuccessLight;
  /// Alias de [KTokens.bgWarningLight].
  static const Color warningLight = KTokens.bgWarningLight;
  /// Alias de [KTokens.bgErrorLight].
  static const Color errorLight = KTokens.bgErrorLight;
  /// Alias de [KTokens.bgInfoLight].
  static const Color infoLight = KTokens.bgInfoLight;

  // Texte de feedback (D13 : crans 700/800, AA sur les fonds clairs)
  /// Alias de [KTokens.textSuccessLight].
  static const Color textSuccess = KTokens.textSuccessLight;
  /// Alias de [KTokens.textErrorLight].
  static const Color textError = KTokens.textErrorLight;
  /// Alias de [KTokens.textWarningLight].
  static const Color textWarning = KTokens.textWarningLight;
  /// Alias de [KTokens.textInfoLight].
  static const Color textInfo = KTokens.textInfoLight;
  /// Alias de [KTokens.textWarningLight].
  static const Color textWarningLight = KTokens.textWarningLight;
  /// Alias de [KTokens.textInfoLight].
  static const Color textInfoLight = KTokens.textInfoLight;

  // Métier
  /// Alias de [KTokens.colorIncomeLight].
  static const Color incomeLight = KTokens.colorIncomeLight;
  /// Alias de [KTokens.colorExpenseLight].
  static const Color expenseLight = KTokens.colorExpenseLight;
  /// Alias de [KTokens.colorDebtOweLight].
  static const Color debtOweLight = KTokens.colorDebtOweLight;
  /// Alias de [KTokens.colorDebtOwedLight].
  static const Color debtOwedLight = KTokens.colorDebtOwedLight;
  /// Alias de [KTokens.colorSubscriptionLight].
  static const Color subscriptionLight = KTokens.colorSubscriptionLight;

  // Interactifs (D2 : dérivés de l'ambre #c66e05)
  /// Alias de [KTokens.primarySubtleLight].
  static const Color primarySubtleLight = KTokens.primarySubtleLight;
  /// Alias de [KTokens.primaryMutedLight].
  static const Color primaryMutedLight = KTokens.primaryMutedLight;
  /// Alias de [KTokens.primaryBorderLight].
  static const Color primaryBorderLight = KTokens.primaryBorderLight;
  /// Alias de [KTokens.hoverBgLight].
  static const Color hoverBgLight = KTokens.hoverBgLight;
  /// Alias de [KTokens.hoverSubtleLight].
  static const Color hoverSubtleLight = KTokens.hoverSubtleLight;
  /// Alias de [KTokens.highlightSubtleLight].
  static const Color highlightSubtleLight = KTokens.highlightSubtleLight;
  /// Alias de [KTokens.overlayLightLight].
  static const Color overlayLightOnLight = KTokens.overlayLightLight;
  /// Alias de [KTokens.focusRingLight].
  static const Color focusRingLight = KTokens.focusRingLight;
  /// Alias de [KTokens.iconCircleBgLight].
  static const Color iconCircleBgLight = KTokens.iconCircleBgLight;

  // ===== Thème sombre =====

  // Action
  /// Alias de [KTokens.colorPrimaryDark].
  static const Color primaryAmberDark = KTokens.colorPrimaryDark;
  /// Alias de [KTokens.colorPrimaryHoverDark].
  static const Color primaryAmberHoverDark = KTokens.colorPrimaryHoverDark;

  // Texte de feedback
  /// Alias de [KTokens.textWarningDark].
  static const Color textWarningDark = KTokens.textWarningDark;
  /// Alias de [KTokens.textInfoDark].
  static const Color textInfoDark = KTokens.textInfoDark;

  // Métier
  /// Alias de [KTokens.colorIncomeDark].
  static const Color incomeDark = KTokens.colorIncomeDark;
  /// Alias de [KTokens.colorExpenseDark].
  static const Color expenseDark = KTokens.colorExpenseDark;
  /// Alias de [KTokens.colorSubscriptionDark].
  static const Color subscriptionDark = KTokens.colorSubscriptionDark;
  /// Alias de [KTokens.colorDebtOweDark].
  static const Color debtOweDark = KTokens.colorDebtOweDark;
  /// Alias de [KTokens.colorDebtOwedDark].
  static const Color debtOwedDark = KTokens.colorDebtOwedDark;

  // Interactifs
  /// Alias de [KTokens.primarySubtleDark].
  static const Color primarySubtleDark = KTokens.primarySubtleDark;
  /// Alias de [KTokens.primaryMutedDark].
  static const Color primaryMutedDark = KTokens.primaryMutedDark;
  /// Alias de [KTokens.primaryBorderDark].
  static const Color primaryBorderDark = KTokens.primaryBorderDark;
  /// Alias de [KTokens.hoverBgDark].
  static const Color hoverBgDark = KTokens.hoverBgDark;
  /// Alias de [KTokens.hoverSubtleDark].
  static const Color hoverSubtleDark = KTokens.hoverSubtleDark;
  /// Alias de [KTokens.highlightSubtleDark].
  static const Color highlightSubtleDark = KTokens.highlightSubtleDark;
  /// Alias de [KTokens.overlayLightDark].
  static const Color overlayLightOnDark = KTokens.overlayLightDark;
  /// Alias de [KTokens.focusRingDark].
  static const Color focusRingDark = KTokens.focusRingDark;
  /// Alias de [KTokens.iconCircleBgDark].
  static const Color iconCircleBgDark = KTokens.iconCircleBgDark;

  // ===== Couleurs locales, sans équivalent k-design =====

  // Secondaire indigo (Tailwind), pour `ColorScheme.secondary` et
  // `AppThemeExtension.secondaryColor`
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color indigo300 = Color(0xFFA5B4FC);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF312E81);

  // Violet (Tailwind). k-design ne porte que le violet sémantique des
  // abonnements (`subscriptionDark` / `subscriptionLight`, D7).
  static const Color violet400 = Color(0xFFA78BFA);
  static const Color violet500 = Color(0xFF8B5CF6);

  // Catégorie hors budget
  static const Color unbudgetedGray = Color(0xFF9CA3AF);
}
