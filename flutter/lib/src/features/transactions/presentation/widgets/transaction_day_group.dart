import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/day_header_formatter.dart';

class TransactionDayGroup extends StatelessWidget {
  const TransactionDayGroup({
    super.key,
    required this.date,
    required this.transactions,
    required this.categories,
    this.onTransactionTap,
  });

  final DateTime date;
  final List<Transaction> transactions;
  final Map<String, Category> categories;
  final void Function(Transaction)? onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.extension<AppThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space2,
          ),
          child: Text(
            DayHeaderFormatter.format(date),
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...transactions.map((tx) {
          final category = tx.categoryId != null
              ? categories[tx.categoryId]
              : null;
          final icon = category?.icone ?? '\u{1F4DD}';
          final iconBg = parseHexColor(category?.couleur);
          final l10n = AppLocalizations.of(context)!;
          final subtitle = category?.nom ?? l10n.transactionsNoCategory;
          final typeName = tx.type.name;
          final valueColor =
              AmountFormatter.amountColor(typeName, colors) ??
                  colorScheme.onSurface;

          return ListItem(
            icon: icon,
            iconBackgroundColor: iconBg,
            title: tx.libelle,
            subtitle: subtitle,
            value: AmountFormatter.format(tx.montant, type: typeName),
            valueColor: valueColor,
            onPressed: onTransactionTap != null
                ? () => onTransactionTap!(tx)
                : null,
          );
        }),
      ],
    );
  }
}
