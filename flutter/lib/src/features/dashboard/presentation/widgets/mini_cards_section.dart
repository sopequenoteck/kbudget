import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class MiniCardsSection extends ConsumerWidget {
  final Currency activeCurrency;
  final List<ExchangeRate> exchangeRates;

  const MiniCardsSection({
    super.key,
    required this.activeCurrency,
    required this.exchangeRates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);
    final colors = Theme.of(context).extension<AppThemeExtension>()!;

    if (state.isLoading) return const _MiniCardsSkeleton();

    return Row(
      spacing: AppSpacing.space3,
      children: [
        Expanded(
          child: _MiniCard(
            icon: PhosphorIconsFill.arrowsClockwise,
            title: 'Abonnements',
            value: AmountFormatter.format(
              state.subscriptionMonthlyTotal,
              currency: activeCurrency,
            ),
            subtitle: '${state.activeSubscriptionCount} actifs',
            accentColor: colors.subscriptionColor,
            onTap: () => context.go(RouteNames.subscriptions),
          ),
        ),
        Expanded(
          child: _MiniCard(
            icon: PhosphorIconsFill.handshake,
            title: 'Dettes',
            value: AmountFormatter.format(
              state.debtNetBalance.abs(),
              currency: activeCurrency,
            ),
            subtitle: state.debtNetBalance > 0
                ? 'On vous doit'
                : state.debtNetBalance < 0
                    ? 'Vous devez'
                    : '${state.activeDebtCount} en cours',
            accentColor: state.debtNetBalance >= 0
                ? colors.debtOwedColor
                : colors.debtOweColor,
            onTap: () => context.go(RouteNames.debts),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Row(
              children: [
                PhosphorIcon(
                  icon,
                  size: AppTypography.sizeXl,
                  color: accentColor,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    title,
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
            Text(
              value,
              style: TextStyle(
                fontSize: AppTypography.sizeXl,
                fontWeight: AppTypography.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.regular,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCardsSkeleton extends StatelessWidget {
  const _MiniCardsSkeleton();

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
              height: 100,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 100,
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
