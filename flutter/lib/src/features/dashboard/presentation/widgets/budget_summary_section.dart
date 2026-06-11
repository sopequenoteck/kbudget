import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_item.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:shimmer/shimmer.dart';

class BudgetSummarySection extends ConsumerWidget {
  const BudgetSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureConfig = ref.watch(featureConfigNotifierProvider);

    if (!featureConfig.enabledFeatures.contains(Feature.budgets)) {
      return const SizedBox.shrink();
    }

    final budgetState = ref.watch(budgetNotifierProvider);

    if (budgetState.isLoading && budgetState.overview == null) {
      return const _BudgetSummarySkeleton();
    }

    final overview = budgetState.overview;
    if (overview == null || overview.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Top 4 items tries par pourcentage decroissant (depasses en premier)
    final topItems = [...overview.items]
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final displayItems = topItems.take(4).toList();

    final currencyEnum = Currency.values.firstWhere(
      (c) => c.name == overview.currency || c.name == overview.currency.toLowerCase(),
      orElse: () => Currency.eur,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budgets · ${DateFormat('MMMM yyyy', 'fr_FR').format(DateTime.now())}',
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.budgets),
              child: const Text('Voir tout'),
            ),
          ],
        ),

        // Sous-titre : MENSUEL · EN {devise} + total (entre header et carte)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MENSUEL · EN ${overview.currency.toUpperCase()}',
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: AppTypography.sizeXs * 0.05,
              ),
            ),
            Text(
              '${AmountFormatter.format(overview.totalSpent, currency: currencyEnum)} / ${AmountFormatter.format(overview.totalBudget, currency: currencyEnum)}',
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Carte items
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            children: displayItems.map(
              (item) => BudgetItem(
                categoryNom: item.categoryNom,
                categoryIcone: item.categoryIcone,
                categoryCouleur: item.categoryCouleur,
                montantBudget: item.montantBudgetNormalise,
                montantDepense: item.montantDepense,
                percentage: item.percentage,
                currency: item.currency,
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }
}

class _BudgetSummarySkeleton extends StatelessWidget {
  const _BudgetSummarySkeleton();

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
          // Header skeleton
          Container(
            width: 80,
            height: AppTypography.sizeLg,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          // Items skeleton
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              children: List.generate(
                3,
                (_) => const BudgetItem.skeleton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
