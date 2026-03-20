import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:shimmer/shimmer.dart';

class IncomeExpenseCards extends StatelessWidget {
  const IncomeExpenseCards({
    super.key,
    required this.currentSummary,
    required this.previousSummary,
    required this.currencies,
    required this.exchangeRates,
    required this.activeCurrency,
  });

  final MonthlySummary? currentSummary;
  final MonthlySummary? previousSummary;
  final List<Currency> currencies;
  final List<ExchangeRate> exchangeRates;
  final Currency activeCurrency;

  String _previousMonthLabel(MonthlySummary summary) {
    // Calcule le mois précédent à partir de month/year du summary courant
    final date = DateTime(summary.year, summary.month, 1);
    final previous = DateTime(date.year, date.month - 1, 1);
    return DateFormat('MMM', 'fr_FR').format(previous);
  }

  @override
  Widget build(BuildContext context) {
    if (currentSummary == null) return const _IncomeExpenseCardsSkeleton();

    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final prevLabel = _previousMonthLabel(currentSummary!);

    final secondaryCurrency =
        currencies.length >= 2 ? currencies[1] : null;

    return Row(
      spacing: AppSpacing.space3,
      children: [
        Expanded(
          child: _IncomeExpenseCard(
            label: 'REVENUS',
            dotColor: colors.incomeColor,
            amount: currentSummary!.totalRecettes,
            previousAmount: previousSummary?.totalRecettes,
            previousMonthLabel: prevLabel,
            activeCurrency: activeCurrency,
            secondaryCurrency: secondaryCurrency,
            exchangeRates: exchangeRates,
            isExpense: false,
          ),
        ),
        Expanded(
          child: _IncomeExpenseCard(
            label: 'DÉPENSES',
            dotColor: colors.expenseColor,
            amount: currentSummary!.totalDepenses,
            previousAmount: previousSummary?.totalDepenses,
            previousMonthLabel: prevLabel,
            activeCurrency: activeCurrency,
            secondaryCurrency: secondaryCurrency,
            exchangeRates: exchangeRates,
            isExpense: true,
          ),
        ),
      ],
    );
  }
}

class _IncomeExpenseCard extends StatelessWidget {
  const _IncomeExpenseCard({
    required this.label,
    required this.dotColor,
    required this.amount,
    required this.previousAmount,
    required this.previousMonthLabel,
    required this.activeCurrency,
    required this.secondaryCurrency,
    required this.exchangeRates,
    required this.isExpense,
  });

  final String label;
  final Color dotColor;
  final double amount;
  final double? previousAmount;
  final String previousMonthLabel;
  final Currency activeCurrency;
  final Currency? secondaryCurrency;
  final List<ExchangeRate> exchangeRates;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.extension<AppThemeExtension>()!;

    // Badge delta — toujours affiche (fallback 0 si pas de mois precedent, comme Angular)
    final delta = amount - (previousAmount ?? 0);
    final arrow = delta >= 0 ? '↑' : '↓';
    final sign = delta >= 0 ? '+' : '';
    final deltaFormatted = AmountFormatter.format(
      delta,
      currency: activeCurrency,
    );
    final deltaText = '$arrow $sign$deltaFormatted vs $previousMonthLabel';

    final Color deltaColor;
    if (isExpense) {
      deltaColor = delta <= 0 ? colors.incomeColor : colors.expenseColor;
    } else {
      deltaColor = delta >= 0 ? colors.incomeColor : colors.expenseColor;
    }

    // Conversion devise secondaire
    final convertedAmount = secondaryCurrency != null
        ? CurrencyConverter.convert(
            amount: amount,
            fromCurrency: activeCurrency,
            toCurrency: secondaryCurrency!,
            rates: exchangeRates,
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot + label
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          // Montant principal avec signe et couleur
          Text(
            '${isExpense ? '-' : '+'}${AmountFormatter.format(amount, currency: activeCurrency)}',
            style: TextStyle(
              fontSize: AppTypography.sizeXl,
              fontWeight: AppTypography.bold,
              color: isExpense ? colors.expenseColor : colors.incomeColor,
            ),
          ),
          // Badge delta (pill)
          ...[
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
              child: Text(
                deltaText,
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.medium,
                  color: deltaColor,
                ),
              ),
            ),
          ],
          // Conversion devise secondaire
          if (convertedAmount != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              '≈ ${AmountFormatter.format(convertedAmount, currency: secondaryCurrency!)}',
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.regular,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IncomeExpenseCardsSkeleton extends StatelessWidget {
  const _IncomeExpenseCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Row(
        spacing: AppSpacing.space3,
        children: [
          Expanded(
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
