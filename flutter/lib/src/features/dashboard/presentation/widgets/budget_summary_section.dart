// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/category_name.dart';
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
    final l10n = AppLocalizations.of(context)!;

    // Top 4 items tries par pourcentage decroissant (depasses en premier)
    final topItems = [...overview.items]
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final displayItems = topItems.take(4).toList();

    final currencyEnum = Currency.values.firstWhere(
      (c) => c.name == overview.currency || c.name == overview.currency.toLowerCase(),
      orElse: () => Currency.eur,
    );
    final locale = ref.watch(intlLocaleProvider);
    final monthLabel = DateFormat.yMMMM(locale).format(DateTime.now());
    final spentFormatted = AmountFormatter.format(
      overview.totalSpent,
      currency: currencyEnum,
      locale: locale,
    );
    final budgetFormatted = AmountFormatter.format(
      overview.totalBudget,
      currency: currencyEnum,
      locale: locale,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.budgetsPageTitle} · $monthLabel',
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.budgets),
              child: Text(l10n.commonActionViewAll),
            ),
          ],
        ),

        // Sous-titre : MENSUEL · EN {devise} + total (entre header et carte)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n
                  .budgetsSummaryMonthlyInCurrency(overview.currency)
                  .toUpperCase(),
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: AppTypography.sizeXs * 0.05,
              ),
            ),
            Text(
              '$spentFormatted / $budgetFormatted',
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
                categoryNom: categoryDisplayName(
                  item.categoryNom,
                  item.categorySystemKey,
                  l10n,
                ),
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
