import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:shimmer/shimmer.dart';

/// Widget affichant un budget avec sa progression.
///
/// Affiche l'icône/couleur de la catégorie, son nom, une barre de progression
/// colorée (3 états : normal/warning/exceeded), les montants dépensé/budgété,
/// et un marqueur d'overflow si le budget est dépassé.
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
    this.showProgressBar = true,
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
        showProgressBar = true,
        _isSkeleton = true;

  final String categoryNom;
  final String categoryIcone;
  final String categoryCouleur;
  final double montantBudget;
  final double montantDepense;
  final double percentage;
  final String currency;
  final VoidCallback? onTap;
  final bool showProgressBar;
  final bool _isSkeleton;

  @override
  Widget build(BuildContext context) {
    if (_isSkeleton) return _BudgetItemSkeleton();

    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final categoryColor = parseHexColor(categoryCouleur);
    final isOverBudget = percentage > 100;

    // 3 états couleur barre
    final Color barColor;
    if (percentage > 100) {
      barColor = colors.expenseColor;
    } else if (percentage >= 80) {
      barColor = colors.textWarning;
    } else {
      barColor = categoryColor?.withValues(alpha: 0.7) ?? colors.incomeColor.withValues(alpha: 0.7);
    }

    final clampedProgress = (percentage / 100).clamp(0.0, 1.0);

    final currencyEnum = Currency.values.byNameOrDefault(
      currency.toLowerCase(),
      Currency.eur,
    );

    final formattedSpent = AmountFormatter.format(montantDepense, currency: currencyEnum);
    final formattedBudget = AmountFormatter.format(montantBudget, currency: currencyEnum);

    // Couleur montants : rouge si exceeded
    final Color amountsColor = isOverBudget ? colors.expenseColor : colorScheme.onSurfaceVariant;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône catégorie 32px
              Container(
                width: AppSpacing.space8,
                height: AppSpacing.space8,
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
              const SizedBox(width: AppSpacing.space3),
              // Nom (flex:1)
              Expanded(
                child: Text(
                  categoryNom,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              // Montants à droite
              Text(
                '$formattedSpent / $formattedBudget',
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.regular,
                  color: amountsColor,
                ),
              ),
            ],
          ),
          if (showProgressBar) ...[
            const SizedBox(height: AppSpacing.space2),
            _buildProgressBar(context, clampedProgress, barColor, isOverBudget),
          ],
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

  Widget _buildProgressBar(
    BuildContext context,
    double clampedProgress,
    Color barColor,
    bool isOverBudget,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.round),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: AppSpacing.space1,
            backgroundColor: colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        if (isOverBudget)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: colors.expenseColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppRadius.round),
                  bottomRight: Radius.circular(AppRadius.round),
                ),
              ),
            ),
          ),
      ],
    );
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
          children: [
            // Cercle icône 32px
            Container(
              width: AppSpacing.space8,
              height: AppSpacing.space8,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ligne nom + montants placeholder
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
                        width: 80,
                        height: AppTypography.sizeXs,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  // Barre
                  Container(
                    height: AppSpacing.space1,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppRadius.round),
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
