// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/account_bank_icon.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountListTile extends ConsumerWidget {
  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback? onEdit;
  final bool isConfirmingDelete;
  final String? deleteError;
  final VoidCallback? onRequestDelete;
  final VoidCallback? onConfirmDelete;
  final VoidCallback? onCancelDelete;

  const AccountListTile({
    super.key,
    required this.account,
    this.onTap,
    this.onSetDefault,
    this.onEdit,
    this.isConfirmingDelete = false,
    this.deleteError,
    this.onRequestDelete,
    this.onConfirmDelete,
    this.onCancelDelete,
  });

  String _typeLabel(AppLocalizations l10n) {
    return switch (account.type) {
      AccountType.courant => l10n.accountTypeCourant,
      AccountType.epargne => l10n.accountTypeEpargne,
      AccountType.especes => l10n.accountTypeEspeces,
    };
  }

  String _subtitle(AppLocalizations l10n) {
    final type = _typeLabel(l10n);
    final bank = account.bankName;
    if (bank != null && bank.isNotEmpty) {
      return '$bank · $type';
    }
    return type;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    final formattedBalance = AmountFormatter.format(
      account.solde,
      currency: account.currency,
    );

    final balanceColor = account.solde < 0
        ? colors.expenseColor
        : colorScheme.onSurfaceVariant;

    return Opacity(
      opacity: account.actif ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ligne 1 : icône + contenu + solde
            Row(
              spacing: AppSpacing.space3,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AccountBankIcon(account: account, size: AppSpacing.space8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        spacing: AppSpacing.space2,
                        children: [
                          Flexible(
                            child: Text(
                              account.nom,
                              style: TextStyle(
                                fontSize: AppTypography.sizeSm,
                                fontWeight: AppTypography.medium,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (account.isDefault)
                            _Badge(
                              label: l10n.accountBadgeDefault,
                              colorScheme: colorScheme,
                            ),
                          if (!account.actif)
                            _Badge(
                              label: l10n.accountBadgeInactive,
                              colorScheme: colorScheme,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        _subtitle(l10n),
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
                Text(
                  formattedBalance,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.semiBold,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            // Ligne 2 : actions inline
            Row(
              children: [
                _ActionButton(
                  icon: PhosphorIconsRegular.trash,
                  color: colors.expenseColor,
                  onTap: onRequestDelete,
                ),
                const Spacer(),
                if (!account.isDefault && account.actif)
                  _ActionButton(
                    icon: PhosphorIconsRegular.star,
                    onTap: onSetDefault,
                  ),
                _ActionButton(
                  icon: PhosphorIconsRegular.pencilSimple,
                  onTap: onEdit,
                ),
              ],
            ),
            // Ligne 3 : bloc confirmation delete (si actif)
            if (isConfirmingDelete)
              _ConfirmDeleteBlock(
                deleteError: deleteError,
                onConfirm: onConfirmDelete,
                onCancel: onCancelDelete,
                expenseColor: colors.expenseColor,
                colorScheme: colorScheme,
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _Badge({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.size2Xs,
          fontWeight: AppTypography.medium,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppSpacing.space8,
      height: AppSpacing.space8,
      child: IconButton(
        icon: PhosphorIcon(icon, size: 16),
        color: color ?? colorScheme.onSurfaceVariant,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class _ConfirmDeleteBlock extends StatelessWidget {
  final String? deleteError;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color expenseColor;
  final ColorScheme colorScheme;

  const _ConfirmDeleteBlock({
    this.deleteError,
    this.onConfirm,
    this.onCancel,
    required this.expenseColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.space2),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Supprimer ce compte ?',
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.medium,
              color: colorScheme.onSurface,
            ),
          ),
          if (deleteError != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              deleteError!,
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                color: expenseColor,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Row(
            spacing: AppSpacing.space2,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Annuler'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: expenseColor,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: const Text('Supprimer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
