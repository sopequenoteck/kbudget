import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:shimmer/shimmer.dart';

/// Widget affichant un budget avec sa progression.
///
/// Affiche l'icône/couleur de la catégorie, son nom, une barre de progression
/// colorée (rouge si dépassement > 100%), les montants dépensé/budgété et le
/// pourcentage.
///
/// Utilise le constructeur nommé [BudgetItem.skeleton] pour l'état de chargement.
class BudgetItem extends StatelessWidget {
  const BudgetItem({
    super.key,
    required this.categoryNom,
    required this.categoryIcone,
    required this.categoryCouleur,
    required this.montantBudget,
    required this.montantDepense,
    required this.percentage,
    required this.currency,
    this.onTap,
  }) : _isSkeleton = false;

  /// Constructeur nommé pour l'état de chargement shimmer.
  const BudgetItem.skeleton({super.key})
      : categoryNom = '',
        categoryIcone = '',
        categoryCouleur = '',
        montantBudget = 0,
        montantDepense = 0,
        percentage = 0,
        currency = '',
        onTap = null,
        _isSkeleton = true;

  final String categoryNom;
  final String categoryIcone;
  final String categoryCouleur;
  final double montantBudget;
  final double montantDepense;
  final double percentage;
  final String currency;
  final VoidCallback? onTap;
  final bool _isSkeleton;

  @override
  Widget build(BuildContext context) {
    if (_isSkeleton) return _BudgetItemSkeleton();

    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = parseHexColor(categoryCouleur);
    final isOverBudget = percentage > 100;

    final progressColor = isOverBudget ? AppColors.error : (categoryColor ?? colorScheme.primary);
    final clampedProgress = (percentage / 100).clamp(0.0, 1.0);

    final currencyEnum = Currency.values.byNameOrDefault(
      currency.toLowerCase(),
      Currency.eur,
    );

    final formattedSpent = AmountFormatter.format(montantDepense, currency: currencyEnum);
    final formattedBudget = AmountFormatter.format(montantBudget, currency: currencyEnum);
    final percentageText = '${percentage.toStringAsFixed(0)} %';

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: AppSpacing.space3,
        children: [
          // Icône catégorie
          Container(
            width: AppSpacing.space10,
            height: AppSpacing.space10,
            decoration: BoxDecoration(
              color: categoryColor ?? colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.round),
            ),
            child: Center(
              child: Text(
                categoryIcone,
                style: const TextStyle(fontSize: AppTypography.sizeLg),
              ),
            ),
          ),
          // Contenu central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.space1,
              children: [
                // Nom + pourcentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        categoryNom,
                        style: TextStyle(
                          fontSize: AppTypography.sizeMd,
                          fontWeight: AppTypography.medium,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      percentageText,
                      style: TextStyle(
                        fontSize: AppTypography.sizeSm,
                        fontWeight: AppTypography.semiBold,
                        color: isOverBudget ? AppColors.error : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.round),
                  child: LinearProgressIndicator(
                    value: clampedProgress,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                // Montants
                Text(
                  '$formattedSpent / $formattedBudget',
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    fontWeight: AppTypography.regular,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

class _BudgetItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppSpacing.space3,
          children: [
            // Cercle icône
            Container(
              width: AppSpacing.space10,
              height: AppSpacing.space10,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
            ),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.space2,
                children: [
                  // Nom + pourcentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 120,
                        height: AppTypography.sizeSm,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: AppTypography.sizeSm,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ],
                  ),
                  // Barre progression
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppRadius.round),
                    ),
                  ),
                  // Montants
                  Container(
                    width: 100,
                    height: AppTypography.sizeXs,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
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
