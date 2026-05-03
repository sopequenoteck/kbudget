import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';

final class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    // ===== Existantes (conservées — pas de breaking change) =====
    required this.incomeColor,
    required this.expenseColor,
    required this.debtOweColor,
    required this.debtOwedColor,
    required this.subscriptionColor,
    required this.secondaryColor,
    // ===== Nouvelles — feedback =====
    required this.textWarning,
    required this.textInfo,
    // ===== Nouvelles — interactifs =====
    required this.primarySubtle,
    required this.primaryMuted,
    required this.primaryBorder,
    required this.hoverSubtle,
    required this.highlightSubtle,
    required this.overlayLight,
    required this.focusRing,
    required this.iconCircleBg,
  });

  // Existantes (compatibilité 14+ widgets consommateurs)
  final Color incomeColor;
  final Color expenseColor;
  final Color debtOweColor;
  final Color debtOwedColor;
  final Color subscriptionColor;
  final Color secondaryColor;

  // Nouvelles — feedback
  final Color textWarning;
  final Color textInfo;

  // Nouvelles — interactifs
  final Color primarySubtle;
  final Color primaryMuted;
  final Color primaryBorder;
  final Color hoverSubtle;
  final Color highlightSubtle;
  final Color overlayLight;
  final Color focusRing;
  final Color iconCircleBg;

  static const AppThemeExtension light = AppThemeExtension(
    incomeColor: AppColors.incomeLight,
    expenseColor: AppColors.expenseLight,
    debtOweColor: AppColors.debtOweLight,
    debtOwedColor: AppColors.debtOwedLight,
    subscriptionColor: AppColors.subscriptionLight,
    secondaryColor: AppColors.indigo600,
    textWarning: AppColors.textWarningLight,
    textInfo: AppColors.textInfoLight,
    primarySubtle: AppColors.primarySubtleLight,
    primaryMuted: AppColors.primaryMutedLight,
    primaryBorder: AppColors.primaryBorderLight,
    hoverSubtle: AppColors.hoverSubtleLight,
    highlightSubtle: AppColors.highlightSubtleLight,
    overlayLight: AppColors.overlayLightLight,
    focusRing: AppColors.focusRingLight,
    iconCircleBg: AppColors.iconCircleBgLight,
  );

  static const AppThemeExtension dark = AppThemeExtension(
    incomeColor: AppColors.incomeDark,
    expenseColor: AppColors.expenseDark,
    debtOweColor: AppColors.debtOweDark,
    debtOwedColor: AppColors.debtOwedDark,
    subscriptionColor: AppColors.subscriptionDark,
    secondaryColor: AppColors.indigo400,
    textWarning: AppColors.textWarningDark,
    textInfo: AppColors.textInfoDark,
    primarySubtle: AppColors.primarySubtleDark,
    primaryMuted: AppColors.primaryMutedDark,
    primaryBorder: AppColors.primaryBorderDark,
    hoverSubtle: AppColors.hoverSubtleDark,
    highlightSubtle: AppColors.highlightSubtleDark,
    overlayLight: AppColors.overlayLightDark,
    focusRing: AppColors.focusRingDark,
    iconCircleBg: AppColors.iconCircleBgDark,
  );

  @override
  AppThemeExtension copyWith({
    Color? incomeColor,
    Color? expenseColor,
    Color? debtOweColor,
    Color? debtOwedColor,
    Color? subscriptionColor,
    Color? secondaryColor,
    Color? textWarning,
    Color? textInfo,
    Color? primarySubtle,
    Color? primaryMuted,
    Color? primaryBorder,
    Color? hoverSubtle,
    Color? highlightSubtle,
    Color? overlayLight,
    Color? focusRing,
    Color? iconCircleBg,
  }) {
    return AppThemeExtension(
      incomeColor: incomeColor ?? this.incomeColor,
      expenseColor: expenseColor ?? this.expenseColor,
      debtOweColor: debtOweColor ?? this.debtOweColor,
      debtOwedColor: debtOwedColor ?? this.debtOwedColor,
      subscriptionColor: subscriptionColor ?? this.subscriptionColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      textWarning: textWarning ?? this.textWarning,
      textInfo: textInfo ?? this.textInfo,
      primarySubtle: primarySubtle ?? this.primarySubtle,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      hoverSubtle: hoverSubtle ?? this.hoverSubtle,
      highlightSubtle: highlightSubtle ?? this.highlightSubtle,
      overlayLight: overlayLight ?? this.overlayLight,
      focusRing: focusRing ?? this.focusRing,
      iconCircleBg: iconCircleBg ?? this.iconCircleBg,
    );
  }

  @override
  AppThemeExtension lerp(covariant AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
      expenseColor: Color.lerp(expenseColor, other.expenseColor, t)!,
      debtOweColor: Color.lerp(debtOweColor, other.debtOweColor, t)!,
      debtOwedColor: Color.lerp(debtOwedColor, other.debtOwedColor, t)!,
      subscriptionColor:
          Color.lerp(subscriptionColor, other.subscriptionColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      textWarning: Color.lerp(textWarning, other.textWarning, t)!,
      textInfo: Color.lerp(textInfo, other.textInfo, t)!,
      primarySubtle: Color.lerp(primarySubtle, other.primarySubtle, t)!,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t)!,
      primaryBorder: Color.lerp(primaryBorder, other.primaryBorder, t)!,
      hoverSubtle: Color.lerp(hoverSubtle, other.hoverSubtle, t)!,
      highlightSubtle: Color.lerp(highlightSubtle, other.highlightSubtle, t)!,
      overlayLight: Color.lerp(overlayLight, other.overlayLight, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      iconCircleBg: Color.lerp(iconCircleBg, other.iconCircleBg, t)!,
    );
  }
}
