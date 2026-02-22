import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/common_widgets/month_selector.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:shimmer/shimmer.dart';

class MonthlySummarySection extends ConsumerWidget {
  const MonthlySummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.extension<AppThemeExtension>()!;

    if (state.isLoading) return const _SummarySkeleton();

    // Prendre le premier summary (devise par defaut)
    final summary = state.monthlySummaries.isNotEmpty
        ? state.monthlySummaries.first
        : null;

    final totalRecettes = summary?.totalRecettes ?? 0;
    final totalDepenses = summary?.totalDepenses ?? 0;
    final solde = summary?.solde ?? 0;
    final currency = summary?.currency;

    // Barres proportionnelles
    final maxRef =
        totalRecettes > totalDepenses ? totalRecettes : totalDepenses;
    final ratioRecettes = maxRef > 0 ? totalRecettes / maxRef : 0.0;
    final ratioDepenses = maxRef > 0 ? totalDepenses / maxRef : 0.0;

    // Couleur solde
    final Color soldeColor;
    if (solde > 0) {
      soldeColor = colors.incomeColor;
    } else if (solde < 0) {
      soldeColor = colors.expenseColor;
    } else {
      soldeColor = colorScheme.onSurface;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Resume du mois',
          style: TextStyle(
            fontSize: AppTypography.sizeLg,
            fontWeight: AppTypography.semiBold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Selecteur de mois
        Center(
          child: MonthSelector(
            initialMonth: state.selectedMonth,
            initialYear: state.selectedYear,
            onChanged: (month, year) {
              ref
                  .read(dashboardNotifierProvider.notifier)
                  .changeMonth(month, year);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Barre recettes
        _SummaryBar(
          label: 'Recettes',
          amount: AmountFormatter.format(
            totalRecettes,
            type: 'recette',
            currency: currency ?? _defaultCurrency,
          ),
          ratio: ratioRecettes,
          color: colors.incomeColor,
        ),
        const SizedBox(height: AppSpacing.space2),

        // Barre depenses
        _SummaryBar(
          label: 'Depenses',
          amount: AmountFormatter.format(
            totalDepenses,
            type: 'depense',
            currency: currency ?? _defaultCurrency,
          ),
          ratio: ratioDepenses,
          color: colors.expenseColor,
        ),
        const SizedBox(height: AppSpacing.space3),

        // Solde du mois
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Solde',
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              AmountFormatter.format(
                solde,
                currency: currency ?? _defaultCurrency,
              ),
              style: TextStyle(
                fontSize: AppTypography.sizeLg,
                fontWeight: AppTypography.bold,
                color: soldeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const _defaultCurrency = Currency.eur;

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String amount;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: AppTypography.sizeLg,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Center(
            child: Container(
              width: 240,
              height: AppSpacing.space12,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          ...List.generate(
            2,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: Container(
                width: double.infinity,
                height: 32,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
