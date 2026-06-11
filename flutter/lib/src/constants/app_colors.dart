import 'dart:ui';

class AppColors {
  AppColors._();

  // Primary - Amber (Tailwind — inchangé, conforme _primitives.scss)
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);

  // Gray — palette propriétaire v5 (remplace Tailwind)
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-50: #fafafa`.
  static const Color gray50 = Color(0xFFFAFAFA);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-100: #f5f5f5`.
  static const Color gray100 = Color(0xFFF5F5F5);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-200: #e5e5e5`.
  static const Color gray200 = Color(0xFFE5E5E5);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-300: #d4d4d4`.
  static const Color gray300 = Color(0xFFD4D4D4);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-400: #a3a3a3`.
  static const Color gray400 = Color(0xFFA3A3A3);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-500: #737373`.
  static const Color gray500 = Color(0xFF737373);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-600: #525252`.
  static const Color gray600 = Color(0xFF525252);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-700: #1e1e1e`.
  static const Color gray700 = Color(0xFF1E1E1E);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-800: #141414`.
  static const Color gray800 = Color(0xFF141414);
  /// Source: app/src/styles/tokens/_primitives.scss `--color-gray-900: #0a0a0a`.
  static const Color gray900 = Color(0xFF0A0A0A);

  // Secondary - Indigo (Tailwind — inchangé, conforme _primitives.scss)
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

  // Feedback (Tailwind — inchangé, conforme _primitives.scss)
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFEAB308);
  static const Color info = Color(0xFF3B82F6);

  // Feedback - Light backgrounds (Tailwind — inchangé)
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Feedback - Text on light (Tailwind — inchangé)
  static const Color textSuccess = Color(0xFF16A34A);
  static const Color textError = Color(0xFFDC2626);
  static const Color textWarning = Color(0xFFCA8A04);
  static const Color textInfo = Color(0xFF2563EB);

  // Subscription (Tailwind — inchangé, conforme _primitives.scss)
  static const Color violet400 = Color(0xFFA78BFA);
  static const Color violet500 = Color(0xFF8B5CF6);

  // Budget - Unbudgeted category
  static const Color unbudgetedGray = Color(0xFF9CA3AF);

  // Semantic - Light theme (business — inchangé)
  static const Color incomeLight = Color(0xFF16A34A);
  static const Color expenseLight = Color(0xFFDC2626);
  static const Color debtOweLight = Color(0xFFDC2626);
  static const Color debtOwedLight = Color(0xFF16A34A);
  static const Color subscriptionLight = Color(0xFF8B5CF6);

  // Semantic - Dark theme (business — valeurs propriétaires v5)
  /// Income color for dark theme. Custom value — was #4ADE80 (green-400 Tailwind).
  /// Source: app/src/styles/themes/_dark.scss `--color-income: #6dc990`.
  static const Color incomeDark = Color(0xFF6DC990);
  /// Expense color for dark theme. Custom value — was #F87171 (red-400 Tailwind).
  /// Source: app/src/styles/themes/_dark.scss `--color-expense: #d97777`.
  static const Color expenseDark = Color(0xFFD97777);
  /// Subscription color for dark theme. Custom value — was #A78BFA (violet-400 Tailwind).
  /// Source: app/src/styles/themes/_dark.scss `--color-subscription: #9580d9`.
  static const Color subscriptionDark = Color(0xFF9580D9);
  /// Alias of expenseDark — debt owed by user.
  static const Color debtOweDark = Color(0xFFD97777);
  /// Alias of incomeDark — debt owed to user.
  static const Color debtOwedDark = Color(0xFF6DC990);

  // ===== Semantic dark values — primary =====
  /// Primary amber semantic value for dark theme. Not derived from amber-* palette.
  /// Source: app/src/styles/themes/_dark.scss `--color-primary: #e0a820`.
  static const Color primaryAmberDark = Color(0xFFE0A820);
  /// Primary amber hover state for dark theme.
  /// Source: app/src/styles/themes/_dark.scss `--color-primary-hover: #c9952a`.
  static const Color primaryAmberHoverDark = Color(0xFFC9952A);

  // ===== Semantic dark values — feedback =====
  /// Warning text color optimized for dark theme readability.
  /// Source: app/src/styles/themes/_dark.scss `--color-text-warning: #d4ad3c`.
  static const Color textWarningDark = Color(0xFFD4AD3C);
  /// Info text color optimized for dark theme readability.
  /// Source: app/src/styles/themes/_dark.scss `--color-text-info: #7aacdb`.
  static const Color textInfoDark = Color(0xFF7AACDB);

  // ===== Semantic dark values — interactifs =====
  /// Subtle amber primary background — rgba(224,168,32,0.10).
  /// Source: app/src/styles/themes/_dark.scss `--color-primary-subtle`.
  static const Color primarySubtleDark = Color(0x1AE0A820);
  /// Muted amber primary background — rgba(224,168,32,0.15).
  /// Source: app/src/styles/themes/_dark.scss `--color-primary-muted`.
  static const Color primaryMutedDark = Color(0x26E0A820);
  /// Amber primary border — rgba(224,168,32,0.25).
  /// Source: app/src/styles/themes/_dark.scss `--color-primary-border`.
  static const Color primaryBorderDark = Color(0x40E0A820);
  /// Hover background for interactive elements in dark theme. Alias of gray700.
  /// Source: app/src/styles/themes/_dark.scss `--color-hover-bg`.
  static const Color hoverBgDark = gray700;
  /// Subtle hover overlay — rgba(255,255,255,0.04).
  /// Source: app/src/styles/themes/_dark.scss `--color-hover-subtle`.
  static const Color hoverSubtleDark = Color(0x0AFFFFFF);
  /// Highlight subtle overlay — rgba(255,255,255,0.10).
  /// Source: app/src/styles/themes/_dark.scss `--color-highlight-subtle`.
  static const Color highlightSubtleDark = Color(0x1AFFFFFF);
  /// Light overlay layer — rgba(255,255,255,0.15).
  /// Source: app/src/styles/themes/_dark.scss `--color-overlay-light`.
  static const Color overlayLightOnDark = Color(0x26FFFFFF);
  /// Focus ring amber — rgba(amber-400 #FBBF24, 0.5).
  /// Source: app/src/styles/themes/_dark.scss `--color-focus-ring`.
  static const Color focusRingDark = Color(0x80FBBF24);
  /// Icon circle background — rgba(255,255,255,0.06).
  /// Source: app/src/styles/themes/_dark.scss `--color-icon-circle-bg`.
  static const Color iconCircleBgDark = Color(0x0FFFFFFF);

  // ===== Semantic light values — feedback =====
  /// Warning text color for light theme. Alias of existing textWarning.
  /// Source: app/src/styles/themes/_light.scss `--color-text-warning: #ca8a04`.
  static const Color textWarningLight = Color(0xFFCA8A04);
  /// Info text color for light theme. Alias of existing textInfo.
  /// Source: app/src/styles/themes/_light.scss `--color-text-info: #2563eb`.
  static const Color textInfoLight = Color(0xFF2563EB);

  // ===== Semantic light values — interactifs =====
  /// Subtle amber primary background — rgba(amber-600 #D97706, 0.10).
  /// Source: app/src/styles/themes/_light.scss `--color-primary-subtle`.
  static const Color primarySubtleLight = Color(0x1AD97706);
  /// Muted amber primary background — rgba(amber-600 #D97706, 0.15).
  /// Source: app/src/styles/themes/_light.scss `--color-primary-muted`.
  static const Color primaryMutedLight = Color(0x26D97706);
  /// Amber primary border — rgba(amber-600 #D97706, 0.25).
  /// Source: app/src/styles/themes/_light.scss `--color-primary-border`.
  static const Color primaryBorderLight = Color(0x40D97706);
  /// Hover background for interactive elements in light theme. Alias of gray100.
  /// Source: app/src/styles/themes/_light.scss `--color-hover-bg`.
  static const Color hoverBgLight = gray100;
  /// Subtle hover overlay — rgba(0,0,0,0.04).
  /// Source: app/src/styles/themes/_light.scss `--color-hover-subtle`.
  static const Color hoverSubtleLight = Color(0x0A000000);
  /// Highlight subtle overlay — rgba(0,0,0,0.06).
  /// Source: app/src/styles/themes/_light.scss `--color-highlight-subtle`.
  static const Color highlightSubtleLight = Color(0x0F000000);
  /// Light overlay layer — rgba(0,0,0,0.10).
  /// Source: app/src/styles/themes/_light.scss `--color-overlay-light`.
  static const Color overlayLightOnLight = Color(0x1A000000);
  /// Focus ring amber — rgba(amber-500 #F59E0B, 0.5).
  /// Source: app/src/styles/themes/_light.scss `--color-focus-ring`.
  static const Color focusRingLight = Color(0x80F59E0B);
  /// Icon circle background — rgba(0,0,0,0.04).
  /// Source: app/src/styles/themes/_light.scss `--color-icon-circle-bg`.
  static const Color iconCircleBgLight = Color(0x0A000000);
}
