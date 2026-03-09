import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/models/unbudgeted_item.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/enum_utils.dart';

/// Bottom sheet affichant la liste des catégories non budgétées avec leurs dépenses.
///
/// Utiliser [UnbudgetedDetailSheet.show] pour afficher le sheet.
class UnbudgetedDetailSheet extends StatelessWidget {
  const UnbudgetedDetailSheet({
    super.key,
    required this.items,
    required this.total,
    required this.currency,
  });

  final List<UnbudgetedItem> items;
  final double total;
  final String currency;

  static void show(
    BuildContext context, {
    required List<UnbudgetedItem> items,
    required double total,
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
      builder: (_) => UnbudgetedDetailSheet(
        items: items,
        total: total,
        currency: currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final currencyEnum = Currency.values.byNameOrDefault(
      currency.toLowerCase(),
      Currency.eur,
    );

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
            // Titre
            Row(
              spacing: AppSpacing.space3,
              children: [
                Container(
                  width: AppSpacing.space12,
                  height: AppSpacing.space12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9ca3af),
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                  child: const Center(
                    child: Text(
                      '📦',
                      style: TextStyle(fontSize: AppTypography.sizeXl),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.budgetOtherCategory,
                    style: TextStyle(
                      fontSize: AppTypography.sizeXl,
                      fontWeight: AppTypography.semiBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            // Total
            Text(
              '${l10n.total} : ${AmountFormatter.format(total, currency: currencyEnum)}',
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            // Liste des items
            ...items.map((item) {
              final color = parseHexColor(item.categoryCouleur);
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space2,
                ),
                child: Row(
                  spacing: AppSpacing.space3,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color ?? colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      item.categoryIcone,
                      style:
                          const TextStyle(fontSize: AppTypography.sizeMd),
                    ),
                    Expanded(
                      child: Text(
                        item.categoryNom,
                        style: TextStyle(
                          fontSize: AppTypography.sizeSm,
                          fontWeight: AppTypography.medium,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AmountFormatter.format(
                        item.montantDepense,
                        currency: currencyEnum,
                      ),
                      style: TextStyle(
                        fontSize: AppTypography.sizeSm,
                        fontWeight: AppTypography.semiBold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
