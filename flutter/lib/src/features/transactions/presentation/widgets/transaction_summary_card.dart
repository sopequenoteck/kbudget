import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:shimmer/shimmer.dart';

class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({
    super.key,
    this.summary,
    this.isLoading = false,
  });

  final MonthlySummary? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _SummaryCardSkeleton();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.extension<AppThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final currency = summary?.currency ?? Currency.eur;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: Row(
        children: [
          _MetricChip(
            label: l10n.transactionsSummaryRecettes,
            amount: AmountFormatter.format(
              summary?.totalRecettes ?? 0,
              currency: currency,
            ),
            color: colors.incomeColor,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: AppSpacing.space2),
          _MetricChip(
            label: l10n.transactionsSummaryDepenses,
            amount: AmountFormatter.format(
              summary?.totalDepenses ?? 0,
              currency: currency,
            ),
            color: colors.expenseColor,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: AppSpacing.space2),
          _MetricChip(
            label: l10n.transactionsSummaryBilan,
            amount: AmountFormatter.format(
              summary?.bilan ?? 0,
              currency: currency,
            ),
            color: _bilanColor(summary?.bilan ?? 0, colors, colorScheme),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Color _bilanColor(
    double bilan,
    AppThemeExtension colors,
    ColorScheme colorScheme,
  ) {
    if (bilan > 0) return colors.incomeColor;
    if (bilan < 0) return colors.expenseColor;
    return colorScheme.onSurface;
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.colorScheme,
  });

  final String label;
  final String amount;
  final Color color;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space2,
          horizontal: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              amount,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Row(
          children: List.generate(
            3,
            (_) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
