// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

/// Widget hero affichant le solde mensuel (bilan = recettes − dépenses)
/// avec les méta-lignes revenus et dépenses.
///
/// Affiche un skeleton shimmer lorsque [isLoading] est `true`.
///
/// Exemple d'usage :
/// ```dart
/// TransactionHeroWidget(
///   summary: state.summary,
///   primaryCurrency: primaryCurrency,
///   isLoading: state.isLoading,
/// )
/// ```
class TransactionHeroWidget extends StatelessWidget {
  const TransactionHeroWidget({
    super.key,
    this.summary,
    this.primaryCurrency,
    required this.isLoading,
  });

  /// Résumé mensuel contenant les totaux recettes et dépenses.
  final MonthlySummary? summary;

  /// Devise principale pour l'affichage des montants.
  /// Utilise [Currency.eur] par défaut si null.
  final Currency? primaryCurrency;

  /// Indique si les données sont en cours de chargement.
  /// Quand `true`, affiche un skeleton à la place du contenu.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _TransactionHeroSkeleton(
        key: Key('transaction_hero_skeleton'),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final currency = primaryCurrency ?? Currency.eur;
    final bilan =
        (summary?.totalRecettes ?? 0) - (summary?.totalDepenses ?? 0);
    final bilanColor =
        bilan >= 0 ? colors.incomeColor : colors.expenseColor;

    return Padding(
      key: const Key('transaction_hero'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'SOLDE',
            style: TextStyle(
              fontSize: AppTypography.sizeXs,
              fontWeight: AppTypography.medium,
              letterSpacing: 0.8,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          const SizedBox(height: AppSpacing.space2),

          // Bilan
          Text(
            AmountFormatter.format(bilan, currency: currency),
            style: TextStyle(
              fontSize: AppTypography.size3xl,
              fontWeight: AppTypography.bold,
              color: bilanColor,
            ),
          ),

          const SizedBox(height: AppSpacing.space2),

          // Meta-line revenus
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.trendUp,
                size: 14,
                color: colors.incomeColor,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AmountFormatter.format(
                  summary?.totalRecettes ?? 0,
                  currency: currency,
                ),
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colors.incomeColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space1),

          // Meta-line dépenses
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.trendDown,
                size: 14,
                color: colors.expenseColor,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AmountFormatter.format(
                  summary?.totalDepenses ?? 0,
                  currency: currency,
                ),
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colors.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionHeroSkeleton extends StatelessWidget {
  const _TransactionHeroSkeleton({super.key});

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
