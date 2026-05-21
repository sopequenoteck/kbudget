import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:k_budget/src/common_widgets/month_selector.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/currency_pill_selector.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

// DTO interne pour le widget DoughnutMini
class DoughnutSegment {
  const DoughnutSegment({required this.value, required this.color});
  final double value;
  final String color;
}

// ─── Widget DoughnutMini ───────────────────────────────────────────────────────

class _DoughnutMini extends StatelessWidget {
  const _DoughnutMini({required this.segments});
  final List<DoughnutSegment> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final fallback = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      width: 80,
      height: 80,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 26,
          sectionsSpace: 1,
          sections: segments.map((s) {
            final color = parseHexColor(s.color)?.withValues(alpha: 0.7) ?? fallback;
            return PieChartSectionData(
              value: s.value,
              color: color,
              showTitle: false,
              radius: 14,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Widget Hero ───────────────────────────────────────────────────────────────

class BudgetHeroWidget extends StatelessWidget {
  const BudgetHeroWidget({
    super.key,
    required this.budgetedSpent,
    required this.activeCurrency,
    required this.heroConverted,
    required this.heroConvertedCurrency,
    required this.overBudgetCount,
    required this.budgetCount,
    required this.unbudgetedTotal,
    required this.doughnutSegments,
    required this.currencies,
    required this.onCurrencyChanged,
    required this.onUnbudgetedTap,
    required this.selectedMonth,
    required this.selectedYear,
    required this.isCurrentMonth,
    required this.onPrevNextMonth,
    required this.onChartsTap,
  });

  final double budgetedSpent;
  final Currency activeCurrency;
  final double? heroConverted;
  final Currency? heroConvertedCurrency;
  final int overBudgetCount;
  final int budgetCount;
  final double unbudgetedTotal;
  final List<DoughnutSegment> doughnutSegments;
  final List<Currency> currencies;
  final ValueChanged<Currency> onCurrencyChanged;
  final VoidCallback? onUnbudgetedTap;
  final int selectedMonth;
  final int selectedYear;
  final bool isCurrentMonth;
  final void Function(int month, int year) onPrevNextMonth;
  final VoidCallback onChartsTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;

    final formattedSpent = AmountFormatter.format(budgetedSpent, currency: activeCurrency);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space2,
        AppSpacing.space4,
        AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top-row : MonthSelector + CurrencyPills + chart icon
          Row(
            children: [
              Expanded(
                child: MonthSelector(
                  initialMonth: selectedMonth,
                  initialYear: selectedYear,
                  onChanged: onPrevNextMonth,
                ),
              ),
              CurrencyPillSelector(
                currencies: currencies,
                activeCurrency: activeCurrency,
                onCurrencyChanged: onCurrencyChanged,
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsRegular.chartBar, size: 20),
                onPressed: onChartsTap,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          // Hero row : montant + donut
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedSpent,
                      style: TextStyle(
                        fontSize: AppTypography.size3xl,
                        fontWeight: AppTypography.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (heroConverted != null && heroConvertedCurrency != null) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        '≈ ${AmountFormatter.format(heroConverted!, currency: heroConvertedCurrency!)}',
                        style: TextStyle(
                          fontSize: AppTypography.sizeSm,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _DoughnutMini(segments: doughnutSegments),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          // Méta-ligne : dépassements + count
          Row(
            children: [
              if (overBudgetCount > 0) ...[
                PhosphorIcon(
                  PhosphorIconsRegular.warning,
                  size: 14,
                  color: themeExt.textWarning,
                ),
                const SizedBox(width: 4),
                Text(
                  '$overBudgetCount en dépassement · ',
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    color: themeExt.textWarning,
                  ),
                ),
              ],
              Text(
                '$budgetCount budgets',
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Ligne non budgété (si > 0)
          if (unbudgetedTotal > 0) ...[
            const SizedBox(height: AppSpacing.space1),
            GestureDetector(
              onTap: onUnbudgetedTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.tray,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${AmountFormatter.format(unbudgetedTotal, currency: activeCurrency)} non budgété',
                    style: TextStyle(
                      fontSize: AppTypography.sizeXs,
                      color: colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Hero Skeleton ────────────────────────────────────────────────────────────

class BudgetHeroSkeleton extends StatelessWidget {
  const BudgetHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space2,
          AppSpacing.space4,
          AppSpacing.space2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 20,
              width: 180,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 36,
                        width: 140,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Container(
                        height: 14,
                        width: 90,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
