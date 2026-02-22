import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/relative_date_formatter.dart';

class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);
    final categoryState = ref.watch(categoryNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.extension<AppThemeExtension>()!;

    if (state.isLoading) return _buildSkeleton();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec "Voir tout"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dernieres operations',
              style: TextStyle(
                fontSize: AppTypography.sizeLg,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.transactions),
              child: const Text('Voir tout'),
            ),
          ],
        ),

        if (state.recentTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            child: Center(
              child: Text(
                'Aucune operation recente',
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          ...state.recentTransactions.map((transaction) {
            // Trouver la categorie
            final category = categoryState.items
                .where((c) => c.id == transaction.categoryId)
                .firstOrNull;

            return ListItem(
              icon: category?.icone ?? '💰',
              iconBackgroundColor: parseHexColor(category?.couleur),
              title: transaction.libelle,
              value: AmountFormatter.format(
                transaction.montant,
                type: transaction.type.name,
              ),
              subtitle: category?.nom,
              rightSubtitle: RelativeDateFormatter.format(transaction.date),
              valueColor:
                  AmountFormatter.amountColor(transaction.type.name, colors),
            );
          }),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.space2),
        ...List.generate(3, (_) => const ListItem.skeleton()),
      ],
    );
  }
}
