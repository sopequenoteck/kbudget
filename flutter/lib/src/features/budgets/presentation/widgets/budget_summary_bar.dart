import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:shimmer/shimmer.dart';

/// Barre de résumé global des budgets du mois.
///
/// Affiche le total dépensé / total budget, le pourcentage global
/// et une barre de progression pleine largeur.
class BudgetSummaryBar extends StatelessWidget {
  const BudgetSummaryBar({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.percentage,
    required this.currency,
  }) : _isSkeleton = false;

  /// Constructeur nommé pour l'état de chargement shimmer.
  const BudgetSummaryBar.skeleton({super.key})
      : totalBudget = 0,
        totalSpent = 0,
        percentage = 0,
        currency = '',
        _isSkeleton = true;

  final double totalBudget;
  final double totalSpent;
  final double percentage;
  final String currency;
  final bool _isSkeleton;

  @override
  Widget build(BuildContext context) {
    if (_isSkeleton) return const _BudgetSummaryBarSkeleton();

    final colorScheme = Theme.of(context).colorScheme;
    final isOverBudget = percentage > 100;

    final progressColor = isOverBudget ? AppColors.error : colorScheme.primary;
    final clampedProgress = (percentage / 100).clamp(0.0, 1.0);

    final currencyEnum = Currency.values.firstWhere(
      (c) => c.name == currency || c.name == currency.toLowerCase(),
      orElse: () => Currency.eur,
    );

    final formattedSpent = AmountFormatter.format(totalSpent, currency: currencyEnum);
    final formattedBudget = AmountFormatter.format(totalBudget, currency: currencyEnum);
    final percentageText = '${percentage.toStringAsFixed(0)} %';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.space2,
          children: [
            // Ligne montants + pourcentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$formattedSpent / $formattedBudget',
                  style: TextStyle(
                    fontSize: AppTypography.sizeMd,
                    fontWeight: AppTypography.semiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  percentageText,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.bold,
                    color: isOverBudget ? AppColors.error : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            // Barre de progression globale
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.round),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetSummaryBarSkeleton extends StatelessWidget {
  const _BudgetSummaryBarSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
