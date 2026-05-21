import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/relative_date_formatter.dart';

class RecurringListItem extends StatelessWidget {
  const RecurringListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RecurringTransaction item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    final amountColor = item.type == TransactionType.depense
        ? themeExt.expenseColor
        : themeExt.incomeColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          children: [
            _CategoryIcon(
              icon: item.categoryIcon,
              color: item.categoryColor,
              themeExt: themeExt,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.libelle,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeSm,
                      fontWeight: AppTypography.medium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_frequencyLabel(l10n)} · ${RelativeDateFormatter.formatCompact(item.nextOccurrence)}',
                    style: TextStyle(
                      fontSize: AppTypography.sizeXs,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              AmountFormatter.format(
                item.montant,
                currency: item.accountCurrency ?? Currency.eur,
              ),
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.semiBold,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _frequencyLabel(AppLocalizations l10n) {
    return switch (item.frequency) {
      Frequency.hebdomadaire => l10n.frequencyHebdomadaire,
      Frequency.mensuel => l10n.frequencyMensuel,
      Frequency.annuel => l10n.frequencyAnnuel,
    };
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.icon,
    required this.color,
    required this.themeExt,
  });

  final String? icon;
  final String? color;
  final AppThemeExtension themeExt;

  @override
  Widget build(BuildContext context) {
    final bg = parseHexColor(color)?.withValues(alpha: 0.15) ?? themeExt.iconCircleBg;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        icon ?? '🔄',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

}
