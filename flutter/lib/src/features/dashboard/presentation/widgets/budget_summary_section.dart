import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class BudgetSummarySection extends ConsumerStatefulWidget {
  const BudgetSummarySection({super.key});

  @override
  ConsumerState<BudgetSummarySection> createState() =>
      _BudgetSummarySectionState();
}

class _BudgetSummarySectionState extends ConsumerState<BudgetSummarySection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(budgetNotifierProvider);
      if (state.overview == null && !state.isLoading) {
        ref.read(budgetNotifierProvider.notifier).loadOverview();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Top 5 items triés par pourcentage décroissant
    final topItems = [...overview.items]
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final displayItems = topItems.take(5).toList();

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
              'Budgets',
              style: TextStyle(
                fontSize: AppTypography.sizeLg,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.budgetDetails),
              child: const Text('Voir tout'),
            ),
          ],
        ),

        // Contenu dans une carte
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              // Liste des budgets
              ...displayItems.map(
                (item) => BudgetItem(
                  categoryNom: item.categoryNom,
                  categoryIcone: item.categoryIcone,
                  categoryCouleur: item.categoryCouleur,
                  montantBudget: item.montantBudgetNormalise,
                  montantDepense: item.montantDepense,
                  percentage: item.percentage,
                  currency: item.currency,
                ),
              ),

              // Séparateur
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant,
              ),

              // Footer : total dépensé / total budget
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total du mois',
                      style: TextStyle(
                        fontSize: AppTypography.sizeSm,
                        fontWeight: AppTypography.medium,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${AmountFormatter.format(overview.totalSpent, currency: currencyEnum)} / ${AmountFormatter.format(overview.totalBudget, currency: currencyEnum)}',
                      style: TextStyle(
                        fontSize: AppTypography.sizeSm,
                        fontWeight: AppTypography.semiBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colorScheme.outlineVariant),
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
