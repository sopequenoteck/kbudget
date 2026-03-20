import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';

class RecurringListItem extends ConsumerWidget {
  const RecurringListItem({
    super.key,
    required this.item,
    required this.onValidate,
    required this.onSkip,
    required this.onDeactivate,
  });

  final RecurringTransaction item;
  final VoidCallback onValidate;
  final VoidCallback onSkip;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutatingIds = ref.watch(
      recurringListNotifierProvider.select((s) => s.mutatingIds),
    );
    final isMutating = mutatingIds.contains(item.id);
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: ValueKey('recurring-${item.id}'),
      background: const _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.success,
        icon: PhosphorIconsRegular.check,
      ),
      secondaryBackground: const _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.warning,
        icon: PhosphorIconsRegular.skipForward,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onValidate();
        } else {
          onSkip();
        }
        return false;
      },
      child: GestureDetector(
        onLongPress: () => _showActionsSheet(context, l10n),
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
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.libelle,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeMd,
                        fontWeight: AppTypography.medium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.accountName != null)
                      Text(
                        item.accountName!,
                        style: TextStyle(
                          fontSize: AppTypography.sizeXs,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              if (isMutating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(status: item.status, l10n: l10n),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      _formatAmount(),
                      style: const TextStyle(
                        fontSize: AppTypography.sizeSm,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    Text(
                      _frequencyLabel(l10n),
                      style: TextStyle(
                        fontSize: AppTypography.sizeXs,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount() {
    return AmountFormatter.format(
      item.montant,
      currency: item.accountCurrency ?? Currency.eur,
    );
  }

  String _frequencyLabel(AppLocalizations l10n) {
    return switch (item.frequency) {
      Frequency.hebdomadaire => l10n.frequencyHebdomadaire,
      Frequency.mensuel => l10n.frequencyMensuel,
      Frequency.annuel => l10n.frequencyAnnuel,
    };
  }

  void _showActionsSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const PhosphorIcon(
                PhosphorIconsRegular.check,
                color: AppColors.success,
              ),
              title: Text(l10n.recurringValidate),
              onTap: () {
                Navigator.of(ctx).pop();
                onValidate();
              },
            ),
            ListTile(
              leading: const PhosphorIcon(
                PhosphorIconsRegular.skipForward,
                color: AppColors.warning,
              ),
              title: Text(l10n.recurringSkip),
              onTap: () {
                Navigator.of(ctx).pop();
                onSkip();
              },
            ),
            ListTile(
              leading: const PhosphorIcon(
                PhosphorIconsRegular.x,
                color: AppColors.error,
              ),
              title: Text(
                l10n.recurringDeactivate,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                onDeactivate();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.icon,
    required this.color,
  });

  final String? icon;
  final String? color;

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(color) ??
        Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        icon ?? '🔄',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});

  final RecurringStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      RecurringStatus.overdue => (
        l10n.recurringOverdue,
        AppColors.errorLight,
        AppColors.textError,
      ),
      RecurringStatus.today => (
        l10n.recurringToday,
        AppColors.warningLight,
        AppColors.textWarning,
      ),
      RecurringStatus.upcoming => (
        l10n.recurringUpcoming,
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          fontWeight: AppTypography.semiBold,
          color: fg,
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
      child: PhosphorIcon(icon, color: color, size: 24),
    );
  }
}
