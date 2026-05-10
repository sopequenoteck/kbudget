import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/debts/application/debt_list_state.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class DebtHeroWidget extends StatelessWidget {
  const DebtHeroWidget({
    super.key,
    required this.summary,
    required this.enCours,
    required this.isLoading,
    this.primaryCurrency,
  });

  final Map<Currency, DebtCurrencySummary> summary;
  final int enCours;
  final bool isLoading;
  final Currency? primaryCurrency;

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty && !isLoading) return const SizedBox.shrink();

    if (isLoading) {
      return const _DebtHeroSkeleton(key: Key('debt_hero_skeleton'));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.extension<AppThemeExtension>()!;

    final DebtCurrencySummary entry;
    final Currency currency;
    if (primaryCurrency != null && summary.containsKey(primaryCurrency)) {
      entry = summary[primaryCurrency]!;
      currency = primaryCurrency!;
    } else {
      final firstEntry = summary.entries.first;
      entry = firstEntry.value;
      currency = firstEntry.key;
    }

    final net = entry.totalPrets - entry.totalEmprunts;

    final Color netColor;
    if (net > 0) {
      netColor = colors.incomeColor;
    } else if (net < 0) {
      netColor = colors.expenseColor;
    } else {
      netColor = colorScheme.onSurface;
    }

    return Padding(
      key: const Key('debt_hero'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'DETTES',
            style: TextStyle(
              fontSize: AppTypography.sizeXs,
              fontWeight: AppTypography.medium,
              letterSpacing: 0.8,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          // Montant solde net
          Text(
            AmountFormatter.format(net.abs(), currency: currency),
            style: TextStyle(
              fontSize: AppTypography.size3xl,
              fontWeight: AppTypography.bold,
              color: netColor,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          // Meta-ligne 1 : prêts + emprunts
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.handCoins,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${AmountFormatter.format(entry.totalPrets, currency: currency)} prêts',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              PhosphorIcon(
                PhosphorIconsRegular.handshake,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${AmountFormatter.format(entry.totalEmprunts, currency: currency)} emprunts',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          // Meta-ligne 2 : en cours
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.clock,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '$enCours en cours',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtHeroSkeleton extends StatelessWidget {
  const _DebtHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        height: 96,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}
