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
  static const Color amber50 = KTokens.amber50Dark;
  static const Color amber100 = KTokens.amber100Dark;
  static const Color amber200 = KTokens.amber200Dark;
  static const Color amber300 = KTokens.amber300Dark;
  static const Color amber400 = KTokens.amber400Dark;
  static const Color amber500 = KTokens.amber500Dark;
  static const Color amber600 = KTokens.amber600Dark;
  static const Color amber700 = KTokens.amber700Dark;
  static const Color amber800 = KTokens.amber800Dark;
  static const Color amber900 = KTokens.amber900Dark;

  // Gris
  static const Color gray50 = KTokens.gray50Dark;
  static const Color gray100 = KTokens.gray100Dark;
  static const Color gray200 = KTokens.gray200Dark;
  static const Color gray300 = KTokens.gray300Dark;
  static const Color gray400 = KTokens.gray400Dark;
  static const Color gray500 = KTokens.gray500Dark;
  static const Color gray600 = KTokens.gray600Dark;
  static const Color gray700 = KTokens.gray700Dark;
  static const Color gray800 = KTokens.gray800Dark;
  static const Color gray900 = KTokens.gray900Dark;

  // Feedback, teinte brute
  static const Color success = KTokens.colorSuccessRawDark;
  static const Color error = KTokens.colorErrorRawDark;
  static const Color warning = KTokens.colorWarningRawDark;
  static const Color info = KTokens.colorInfoRawDark;

  // ===== Thème clair =====

  // Fonds de feedback
  static const Color successLight = KTokens.bgSuccessLight;
  static const Color warningLight = KTokens.bgWarningLight;
  static const Color errorLight = KTokens.bgErrorLight;
  static const Color infoLight = KTokens.bgInfoLight;

  // Texte de feedback (D13 : crans 700/800, AA sur les fonds clairs)
  static const Color textSuccess = KTokens.textSuccessLight;
  static const Color textError = KTokens.textErrorLight;
  static const Color textWarning = KTokens.textWarningLight;
  static const Color textInfo = KTokens.textInfoLight;
  static const Color textWarningLight = KTokens.textWarningLight;
  static const Color textInfoLight = KTokens.textInfoLight;

  // Métier
  static const Color incomeLight = KTokens.colorIncomeLight;
  static const Color expenseLight = KTokens.colorExpenseLight;
  static const Color debtOweLight = KTokens.colorDebtOweLight;
  static const Color debtOwedLight = KTokens.colorDebtOwedLight;
  static const Color subscriptionLight = KTokens.colorSubscriptionLight;

  // Interactifs (D2 : dérivés de l'ambre #c66e05)
  static const Color primarySubtleLight = KTokens.primarySubtleLight;
  static const Color primaryMutedLight = KTokens.primaryMutedLight;
  static const Color primaryBorderLight = KTokens.primaryBorderLight;
  static const Color hoverBgLight = KTokens.hoverBgLight;
  static const Color hoverSubtleLight = KTokens.hoverSubtleLight;
  static const Color highlightSubtleLight = KTokens.highlightSubtleLight;
  static const Color overlayLightOnLight = KTokens.overlayLightLight;
  static const Color focusRingLight = KTokens.focusRingLight;
  static const Color iconCircleBgLight = KTokens.iconCircleBgLight;

  // ===== Thème sombre =====

  // Action
  static const Color primaryAmberDark = KTokens.colorPrimaryDark;
  static const Color primaryAmberHoverDark = KTokens.colorPrimaryHoverDark;

  // Texte de feedback
  static const Color textWarningDark = KTokens.textWarningDark;
  static const Color textInfoDark = KTokens.textInfoDark;

  // Métier
  static const Color incomeDark = KTokens.colorIncomeDark;
  static const Color expenseDark = KTokens.colorExpenseDark;
  static const Color subscriptionDark = KTokens.colorSubscriptionDark;
  static const Color debtOweDark = KTokens.colorDebtOweDark;
  static const Color debtOwedDark = KTokens.colorDebtOwedDark;

  // Interactifs
  static const Color primarySubtleDark = KTokens.primarySubtleDark;
  static const Color primaryMutedDark = KTokens.primaryMutedDark;
  static const Color primaryBorderDark = KTokens.primaryBorderDark;
  static const Color hoverBgDark = KTokens.hoverBgDark;
  static const Color hoverSubtleDark = KTokens.hoverSubtleDark;
  static const Color highlightSubtleDark = KTokens.highlightSubtleDark;
  static const Color overlayLightOnDark = KTokens.overlayLightDark;
  static const Color focusRingDark = KTokens.focusRingDark;
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
