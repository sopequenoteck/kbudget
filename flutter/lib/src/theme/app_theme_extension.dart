import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.incomeColor,
    required this.expenseColor,
    required this.debtOweColor,
    required this.debtOwedColor,
    required this.subscriptionColor,
  });

  final Color incomeColor;
  final Color expenseColor;
  final Color debtOweColor;
  final Color debtOwedColor;
  final Color subscriptionColor;

  static const light = AppThemeExtension(
    incomeColor: AppColors.incomeLight,
    expenseColor: AppColors.expenseLight,
    debtOweColor: AppColors.debtOweLight,
    debtOwedColor: AppColors.debtOwedLight,
    subscriptionColor: AppColors.subscriptionLight,
  );

  static const dark = AppThemeExtension(
    incomeColor: AppColors.incomeDark,
    expenseColor: AppColors.expenseDark,
    debtOweColor: AppColors.debtOweDark,
    debtOwedColor: AppColors.debtOwedDark,
    subscriptionColor: AppColors.subscriptionDark,
  );

  @override
  AppThemeExtension copyWith({
    Color? incomeColor,
    Color? expenseColor,
    Color? debtOweColor,
    Color? debtOwedColor,
    Color? subscriptionColor,
  }) {
    return AppThemeExtension(
      incomeColor: incomeColor ?? this.incomeColor,
      expenseColor: expenseColor ?? this.expenseColor,
      debtOweColor: debtOweColor ?? this.debtOweColor,
      debtOwedColor: debtOwedColor ?? this.debtOwedColor,
      subscriptionColor: subscriptionColor ?? this.subscriptionColor,
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
    );
  }
}
