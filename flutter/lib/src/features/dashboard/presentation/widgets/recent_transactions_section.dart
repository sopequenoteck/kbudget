// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/enums/modal_type.dart';
import 'package:k_budget/src/domain/enums/transaction_type.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
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
              'Dernières opérations',
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
                'Aucune opération récente',
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

            // Trouver le compte associé
            final account = state.accounts
                .where((a) => a.id == transaction.accountId)
                .cast<Account?>()
                .firstOrNull;

            // Subtitle : catégorie · nom du compte
            final parts = <String>[
              if (category?.nom != null) category!.nom,
              if (account?.nom != null) account!.nom,
            ];
            final subtitle = parts.isEmpty ? null : parts.join(' · ');

            // Déterminer si la devise du compte diffère de la devise active
            final accountCurrency = account?.currency;
            final hasForeignCurrency = accountCurrency != null &&
                accountCurrency != state.activeCurrency;

            // Montant converti
            String? convertedAmount;
            if (hasForeignCurrency) {
              final converted = CurrencyConverter.convert(
                amount: transaction.montant,
                fromCurrency: accountCurrency,
                toCurrency: state.activeCurrency,
                rates: state.exchangeRates,
              );
              if (converted != null) {
                convertedAmount = '≈ ${AmountFormatter.format(
                  converted,
                  currency: state.activeCurrency,
                )}';
              }
            }

            final onPressed = transaction.type == TransactionType.ajustement
                ? null
                : () => ref.read(modalNotifierProvider.notifier).open(
                      ModalType.transaction,
                      entity: transaction,
                    );

            if (hasForeignCurrency) {
              return _TransactionListItemWithBadge(
                transaction: transaction,
                icon: category?.icone ?? '💰',
                iconBackgroundColor: parseHexColor(category?.couleur),
                subtitle: subtitle,
                rightSubtitle: RelativeDateFormatter.format(transaction.date),
                valueColor: AmountFormatter.amountColor(
                    transaction.type.name, colors),
                accountCurrency: accountCurrency,
                convertedAmount: convertedAmount,
                onPressed: onPressed,
              );
            }

            return ListItem(
              icon: category?.icone ?? '💰',
              iconBackgroundColor: parseHexColor(category?.couleur),
              title: transaction.libelle,
              value: AmountFormatter.format(
                transaction.montant,
                type: transaction.type.name,
                currency: accountCurrency ?? state.activeCurrency,
              ),
              subtitle: subtitle,
              rightSubtitle: RelativeDateFormatter.format(transaction.date),
              valueColor:
                  AmountFormatter.amountColor(transaction.type.name, colors),
              onPressed: onPressed,
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

/// Widget ListItem enrichi avec badge devise et montant converti.
/// Utilisé uniquement quand la devise du compte diffère de la devise active.
class _TransactionListItemWithBadge extends StatelessWidget {
  const _TransactionListItemWithBadge({
    required this.transaction,
    required this.icon,
    required this.iconBackgroundColor,
    required this.subtitle,
    required this.rightSubtitle,
    required this.valueColor,
    required this.accountCurrency,
    required this.convertedAmount,
    required this.onPressed,
  });

  final Transaction transaction;
  final String icon;
  final Color? iconBackgroundColor;
  final String? subtitle;
  final String? rightSubtitle;
  final Color? valueColor;
  final Currency accountCurrency;
  final String? convertedAmount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space3,
        horizontal: AppSpacing.space4,
      ),
      child: Row(
        spacing: AppSpacing.space3,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Zone icône
          Container(
            width: AppSpacing.space10,
            height: AppSpacing.space10,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppColors.amber100,
              borderRadius: BorderRadius.circular(AppRadius.round),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: AppTypography.sizeLg),
              ),
            ),
          ),
          // Zone contenu central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.space1,
              children: [
                Text(
                  transaction.libelle,
                  style: TextStyle(
                    fontSize: AppTypography.sizeMd,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: AppTypography.sizeSm,
                      fontWeight: AppTypography.regular,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Zone valeur droite
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.space1,
            children: [
              // Montant avec badge devise
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.space1,
                children: [
                  // Badge devise
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      accountCurrency.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: AppTypography.sizeXs,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                  Text(
                    AmountFormatter.format(
                      transaction.montant,
                      type: transaction.type.name,
                      currency: accountCurrency,
                    ),
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      fontWeight: AppTypography.semiBold,
                      color: valueColor ?? colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              // Ligne 2 : date relative + montant converti
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.space2,
                children: [
                  if (rightSubtitle != null)
                    Text(
                      rightSubtitle!,
                      style: TextStyle(
                        fontSize: AppTypography.sizeSm,
                        fontWeight: AppTypography.regular,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (convertedAmount != null)
                    Text(
                      convertedAmount!,
                      style: TextStyle(
                        fontSize: AppTypography.sizeSm,
                        fontWeight: AppTypography.regular,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final semanticLabel = '${transaction.libelle}, ${AmountFormatter.format(
      transaction.montant,
      type: transaction.type.name,
      currency: accountCurrency,
    )}';

    if (onPressed != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: InkWell(
          onTap: onPressed,
          child: content,
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: content,
    );
  }
}
