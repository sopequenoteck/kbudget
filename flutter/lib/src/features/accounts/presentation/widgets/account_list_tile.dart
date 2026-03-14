import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/account_bank_icon.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountListTile extends ConsumerWidget {
  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  const AccountListTile({
    super.key,
    required this.account,
    this.onTap,
    this.onSetDefault,
    this.onDelete,
  });

  String _typeLabel(AppLocalizations l10n) {
    return switch (account.type) {
      AccountType.courant => l10n.accountTypeCourant,
      AccountType.epargne => l10n.accountTypeEpargne,
      AccountType.especes => l10n.accountTypeEspeces,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final formattedBalance = AmountFormatter.format(
      account.solde,
      currency: account.currency,
    );

    return Opacity(
      opacity: account.actif ? 1.0 : 0.5,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space3,
            horizontal: AppSpacing.space4,
          ),
          child: Row(
            spacing: AppSpacing.space3,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon circle
              AccountBankIcon(account: account, size: AppSpacing.space10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      account.nom,
                      style: TextStyle(
                        fontSize: AppTypography.sizeMd,
                        fontWeight: AppTypography.medium,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Row(
                      spacing: AppSpacing.space2,
                      children: [
                        Text(
                          _typeLabel(l10n),
                          style: TextStyle(
                            fontSize: AppTypography.sizeSm,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (account.isDefault)
                          _Badge(
                            label: l10n.accountBadgeDefault,
                            color: colorScheme.primary,
                          ),
                        if (!account.actif)
                          _Badge(
                            label: l10n.accountBadgeInactive,
                            color: colorScheme.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Balance + menu
              Text(
                formattedBalance,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  fontWeight: AppTypography.semiBold,
                  color: colorScheme.onSurface,
                ),
              ),
              PopupMenuButton<String>(
                icon: PhosphorIcon(
                  PhosphorIconsRegular.dotsThreeVertical,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  if (account.actif && !account.isDefault)
                    PopupMenuItem(
                      value: 'setDefault',
                      child: Text(l10n.accountActionSetDefault),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.accountActionDelete),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'setDefault') {
                    onSetDefault?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          fontWeight: AppTypography.medium,
          color: color,
        ),
      ),
    );
  }
}
