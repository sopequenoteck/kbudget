import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

class AccountTypeSelector extends StatelessWidget {
  final AccountType selectedType;
  final ValueChanged<AccountType> onChanged;
  final bool disabled;

  const AccountTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.disabled = false,
  });

  static const _typeDefaults = <AccountType, ({String emoji, String color})>{
    AccountType.courant: (emoji: '\u{1F3E6}', color: '#3b82f6'),
    AccountType.epargne: (emoji: '\u{1F437}', color: '#22c55e'),
    AccountType.especes: (emoji: '\u{1F4B5}', color: '#f59e0b'),
  };

  static String defaultEmoji(AccountType type) =>
      _typeDefaults[type]?.emoji ?? '\u{1F3E6}';
  static String defaultColor(AccountType type) =>
      _typeDefaults[type]?.color ?? '#3b82f6';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final labels = {
      AccountType.courant: l10n.accountTypeCourant,
      AccountType.epargne: l10n.accountTypeEpargne,
      AccountType.especes: l10n.accountTypeEspeces,
    };

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Row(
        spacing: AppSpacing.space2,
        children: AccountType.values.map((type) {
          final isSelected = type == selectedType;
          final defaults = _typeDefaults[type]!;

          return Expanded(
            child: _TypeCard(
              emoji: defaults.emoji,
              label: labels[type]!,
              isSelected: isSelected,
              onTap: disabled ? null : () => onChanged(type),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TypeCard({
    required this.emoji,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.space1,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight:
                    isSelected ? AppTypography.semiBold : AppTypography.medium,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
