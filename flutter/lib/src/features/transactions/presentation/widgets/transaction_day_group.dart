import 'package:flutter/material.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/currency_converter.dart';

class TransactionDayGroup extends StatelessWidget {
  const TransactionDayGroup({
    super.key,
    required this.transactions,
    required this.categories,
    this.onTransactionTap,
    this.accounts = const [],
    this.exchangeRates = const [],
    this.primaryCurrency,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categories;
  final void Function(Transaction)? onTransactionTap;
  final List<Account> accounts;
  final List<ExchangeRate> exchangeRates;
  final Currency? primaryCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.extension<AppThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

          // Sous-texte montant converti si devise étrangère
          String? convertedSubtitle;
          if (primaryCurrency != null &&
              tx.accountId != null &&
              exchangeRates.isNotEmpty) {
            final account = accounts.cast<Account?>().firstWhere(
                  (a) => a?.id == tx.accountId,
                  orElse: () => null,
                );
            final txCurrency = account?.currency ?? Currency.eur;
            if (txCurrency != primaryCurrency) {
              final converted = CurrencyConverter.convert(
                amount: tx.montant,
                fromCurrency: txCurrency,
                toCurrency: primaryCurrency!,
                rates: exchangeRates,
              );
              if (converted != null) {
                convertedSubtitle =
                    '~ ${AmountFormatter.format(converted, currency: primaryCurrency!)}';
              }
            }
          }

          return ListItem(
            icon: icon,
            iconBackgroundColor: iconBg,
            title: tx.libelle,
            subtitle: subtitle,
            value: AmountFormatter.format(tx.montant, type: typeName),
            valueColor: valueColor,
            rightSubtitle: convertedSubtitle,
            onPressed: onTransactionTap != null
                ? () => onTransactionTap!(tx)
                : null,
          );
        }),
      ],
    );
  }
}
