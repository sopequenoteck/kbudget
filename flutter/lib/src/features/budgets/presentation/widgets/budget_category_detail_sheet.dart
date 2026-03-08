import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';

/// Bottom sheet affichant le détail d'une catégorie de budget.
///
/// Affiche l'icône et le nom de la catégorie, les montants dépensé/budgété
/// et le pourcentage de consommation avec un indicateur coloré.
///
/// Utiliser [BudgetCategoryDetailSheet.show] pour afficher le sheet.
class BudgetCategoryDetailSheet extends StatelessWidget {
  const BudgetCategoryDetailSheet({
    super.key,
    required this.categoryNom,
    required this.categoryIcone,
    required this.categoryCouleur,
    required this.montantDepense,
    required this.montantBudget,
    required this.percentage,
    required this.currency,
  });

  final String categoryNom;
  final String categoryIcone;
  final String categoryCouleur;
  final double montantDepense;
  final double montantBudget;
  final double percentage;
  final String currency;

  /// Affiche le bottom sheet de détail d'une catégorie de budget.
  static void show(
    BuildContext context, {
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantDepense,
    required double montantBudget,
    required double percentage,
    required String currency,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (_) => BudgetCategoryDetailSheet(
        categoryNom: categoryNom,
        categoryIcone: categoryIcone,
        categoryCouleur: categoryCouleur,
        montantDepense: montantDepense,
        montantBudget: montantBudget,
        percentage: percentage,
        currency: currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = parseHexColor(categoryCouleur);
    final isOverBudget = percentage > 100;

    final currencyEnum = Currency.values.firstWhere(
      (c) => c.name == currency || c.name == currency.toLowerCase(),
      orElse: () => Currency.eur,
    );

    final formattedSpent =
        AmountFormatter.format(montantDepense, currency: currencyEnum);
    final formattedBudget =
        AmountFormatter.format(montantBudget, currency: currencyEnum);
    final percentageText = '${percentage.toStringAsFixed(0)} %';

    final clampedProgress = (percentage / 100).clamp(0.0, 1.0);
    final progressColor =
        isOverBudget ? AppColors.error : (categoryColor ?? colorScheme.primary);
    final percentageColor =
        isOverBudget ? AppColors.textError : AppColors.textSuccess;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.round),
                ),
              ),
            ),
            // En-tête : icône + nom
            Row(
              spacing: AppSpacing.space3,
              children: [
                Container(
                  width: AppSpacing.space12,
                  height: AppSpacing.space12,
                  decoration: BoxDecoration(
                    color: categoryColor ??
                        colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                  child: Center(
                    child: Text(
                      categoryIcone,
                      style: const TextStyle(fontSize: AppTypography.sizeXl),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    categoryNom,
                    style: TextStyle(
                      fontSize: AppTypography.sizeXl,
                      fontWeight: AppTypography.semiBold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space5),
            // Montants
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.space3,
                children: [
                  // Dépensé vs budget
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.space1,
                        children: [
                          Text(
                            'Dépensé',
                            style: TextStyle(
                              fontSize: AppTypography.sizeXs,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            formattedSpent,
                            style: TextStyle(
                              fontSize: AppTypography.sizeLg,
                              fontWeight: AppTypography.semiBold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: AppSpacing.space1,
                        children: [
                          Text(
                            'Budget',
                            style: TextStyle(
                              fontSize: AppTypography.sizeXs,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            formattedBudget,
                            style: TextStyle(
                              fontSize: AppTypography.sizeLg,
                              fontWeight: AppTypography.semiBold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Barre de progression
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.round),
                    child: LinearProgressIndicator(
                      value: clampedProgress,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  // Pourcentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space2,
                          vertical: AppSpacing.space1,
                        ),
                        decoration: BoxDecoration(
                          color: isOverBudget
                              ? AppColors.errorLight
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          percentageText,
                          style: TextStyle(
                            fontSize: AppTypography.sizeSm,
                            fontWeight: AppTypography.semiBold,
                            color: percentageColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
