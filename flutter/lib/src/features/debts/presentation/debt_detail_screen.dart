// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/debt_payment.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/repay_bottom_sheet.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/snooze_dialog.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class DebtDetailScreen extends ConsumerStatefulWidget {
  final String debtId;
  final Debt? initialDebt;

  const DebtDetailScreen({
    super.key,
    required this.debtId,
    this.initialDebt,
  });

  @override
  ConsumerState<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends ConsumerState<DebtDetailScreen> {
  Debt? _debt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _debt = widget.initialDebt;
    _loadDebt();
  }

  Future<void> _loadDebt() async {
    setState(() => _isLoading = true);
    try {
      // Try from cache first
      final cached =
          ref.read(debtNotifierProvider.notifier).getDebtById(widget.debtId);
      if (cached != null) {
        setState(() {
          _debt = cached;
          _isLoading = false;
        });
      } else {
        // Load from API
        final repo = ref.read(debtRepositoryProvider);
        final debt = await repo.getById(widget.debtId);
        if (mounted) {
          setState(() {
            _debt = debt;
            _isLoading = false;
          });
        }
      }
    } on Exception {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeExt = theme.extension<AppThemeExtension>();
    final l10n = AppLocalizations.of(context)!;

    // Listen for changes from notifier
    ref.watch(debtNotifierProvider); // trigger rebuild on state change
    final updatedDebt =
        ref.read(debtNotifierProvider.notifier).getDebtById(widget.debtId);
    if (updatedDebt != null && updatedDebt != _debt) {
      _debt = updatedDebt;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_debt?.personne ?? ''),
        actions: [
          if (_debt != null)
            IconButton(
              onPressed: () {
                ref.read(modalNotifierProvider.notifier).open(
                      ModalType.debt,
                      entity: _debt,
                    );
              },
              icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple,
                  size: 20),
              tooltip: l10n.edit,
            ),
        ],
      ),
      body: _isLoading && _debt == null
          ? _buildSkeleton(colorScheme)
          : _debt == null
              ? Center(child: Text(l10n.errorGeneric))
              : _buildContent(context, _debt!, colorScheme, themeExt, l10n),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Debt debt,
    ColorScheme colorScheme,
    AppThemeExtension? themeExt,
    AppLocalizations l10n,
  ) {
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');
    final typeColor = debt.sens == DebtType.emprunt
        ? (themeExt?.debtOweColor ?? colorScheme.error)
        : (themeExt?.debtOwedColor ?? colorScheme.primary);

    // Résoudre le nom de catégorie depuis le provider
    final categories = ref.watch(categoryNotifierProvider).items;
    final categoryName = debt.categoryId != null
        ? categories
            .where((c) => c.id == debt.categoryId)
            .firstOrNull
            ?.nom
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: badges
          Row(
            children: [
              _Badge(
                label: debt.sens == DebtType.emprunt ? l10n.debtDetailBadgeEmprunt : l10n.debtDetailBadgePret,
                color: typeColor,
              ),
              if (debt.rembourse) ...[
                const SizedBox(width: AppSpacing.space2),
                _Badge(
                  label: l10n.debtDetailBadgeRepaid,
                  color: themeExt?.incomeColor ?? Colors.green,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          // Section progression (seulement si remainingAmount est connu)
          if (debt.remainingAmount != null) ...[
            _ProgressSection(
                debt: debt, colorScheme: colorScheme, themeExt: themeExt),
            const SizedBox(height: AppSpacing.space4),
          ],

          // Montants
          _AmountSection(debt: debt, colorScheme: colorScheme, themeExt: themeExt),
          const SizedBox(height: AppSpacing.space4),

          // Bouton Rembourser
          if (!debt.rembourse)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showRepaySheet(debt),
                icon: const PhosphorIcon(
                    PhosphorIconsRegular.currencyCircleDollar,
                    size: 20),
                label: Text(l10n.debtDetailRepayButton),
              ),
            ),
          if (!debt.rembourse) const SizedBox(height: AppSpacing.space4),

          // Bouton Reporter le rappel
          if (debt.reminderDate != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showSnoozeDialog(debt),
                icon: const PhosphorIcon(PhosphorIconsRegular.bellSlash,
                    size: 20),
                label: Text(l10n.debtDetailSnoozeButton),
              ),
            ),
          if (debt.reminderDate != null) const SizedBox(height: AppSpacing.space4),

          // Infos section enrichie
          _InfoSection(
            debt: debt,
            colorScheme: colorScheme,
            dateFormat: dateFormat,
            categoryName: categoryName,
          ),
          const SizedBox(height: AppSpacing.space4),

          // Section historique des paiements
          _PaymentsSection(debt: debt, colorScheme: colorScheme),
        ],
      ),
    );
  }

  void _showRepaySheet(Debt debt) {
    RepayBottomSheet.show(
      context: context,
      debt: debt,
      onRepaid: _loadDebt,
    );
  }

  void _showSnoozeDialog(Debt debt) {
    SnoozeDialog.show(
      context: context,
      debt: debt,
      onSnoozed: () {
        _loadDebt();
      },
    );
  }

  Widget _buildSkeleton(ColorScheme colorScheme) {
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 28,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ],
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
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          fontWeight: AppTypography.semiBold,
          color: color,
        ),
      ),
    );
  }
}

class _AmountSection extends StatelessWidget {
  final Debt debt;
  final ColorScheme colorScheme;
  final AppThemeExtension? themeExt;

  const _AmountSection({
    required this.debt,
    required this.colorScheme,
    this.themeExt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedTotal =
        AmountFormatter.format(debt.montant, currency: debt.currency);
    final remaining = debt.remainingAmount ?? debt.montant;
    final formattedRemaining =
        AmountFormatter.format(remaining, currency: debt.currency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.debtDetailInitialAmount,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formattedTotal,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  fontWeight: AppTypography.semiBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.debtDetailRemainingAmount,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formattedRemaining,
                style: TextStyle(
                  fontSize: AppTypography.sizeLg,
                  fontWeight: AppTypography.bold,
                  color: debt.rembourse
                      ? (themeExt?.incomeColor ?? Colors.green)
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Debt debt;
  final ColorScheme colorScheme;
  final DateFormat dateFormat;
  final String? categoryName;

  const _InfoSection({
    required this.debt,
    required this.colorScheme,
    required this.dateFormat,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? reminderValue;
    if (debt.reminderDate != null) {
      final dateStr = dateFormat.format(debt.reminderDate!);
      reminderValue = debt.reminderTime != null
          ? '$dateStr à ${debt.reminderTime}'
          : dateStr;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: PhosphorIconsRegular.calendarBlank,
            label: l10n.debtDetailDate,
            value: dateFormat.format(debt.date),
            colorScheme: colorScheme,
          ),
          _InfoRow(
            icon: PhosphorIconsRegular.currencyEur,
            label: l10n.debtDetailCurrency,
            value: debt.currency.name.toUpperCase(),
            colorScheme: colorScheme,
          ),
          if (debt.accountName != null || debt.accountId != null)
            _InfoRow(
              icon: PhosphorIconsRegular.bank,
              label: l10n.debtDetailAccount,
              value: debt.accountName ?? l10n.debtDetailAccountDeleted,
              colorScheme: colorScheme,
            ),
          if (debt.dueDate != null)
            _InfoRow(
              icon: PhosphorIconsRegular.calendarCheck,
              label: l10n.debtDetailDueDate,
              value: dateFormat.format(debt.dueDate!),
              colorScheme: colorScheme,
            ),
          if (categoryName != null)
            _InfoRow(
              icon: PhosphorIconsRegular.tag,
              label: l10n.debtDetailCategory,
              value: categoryName!,
              colorScheme: colorScheme,
            ),
          _InfoRow(
            icon: PhosphorIconsRegular.scales,
            label: l10n.debtDetailIncludedInBalance,
            value: debt.includeInBalance ? l10n.yes : l10n.no,
            colorScheme: colorScheme,
          ),
          if (reminderValue != null)
            _InfoRow(
              icon: PhosphorIconsRegular.bell,
              label: l10n.debtDetailReminder,
              value: reminderValue,
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.space3),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.medium,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Debt debt;
  final ColorScheme colorScheme;
  final AppThemeExtension? themeExt;

  const _ProgressSection({
    required this.debt,
    required this.colorScheme,
    this.themeExt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = debt.remainingAmount ?? debt.montant;
    final paid = debt.montant - remaining;
    final progress =
        debt.montant > 0 ? (paid / debt.montant).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();

    final progressColor = debt.sens == DebtType.emprunt
        ? (themeExt?.debtOweColor ?? colorScheme.error)
        : (themeExt?.debtOwedColor ?? colorScheme.primary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.debtDetailProgress,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.semiBold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsSection extends ConsumerWidget {
  final Debt debt;
  final ColorScheme colorScheme;

  const _PaymentsSection({
    required this.debt,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final paymentsAsync = ref.watch(debtPaymentsProvider(debt.id));
    final dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.debtDetailPayments,
          style: TextStyle(
            fontSize: AppTypography.sizeMd,
            fontWeight: AppTypography.semiBold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        paymentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, e) => Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Text(
              l10n.debtDetailPaymentsError,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                color: colorScheme.error,
              ),
            ),
          ),
          data: (List<DebtPayment> payments) {
            if (payments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space4),
                child: Center(
                  child: Text(
                    l10n.debtDetailNoPayments,
                    style: TextStyle(
                      fontSize: AppTypography.sizeSm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            final total =
                payments.fold<double>(0, (sum, p) => sum + p.montant);

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.debtDetailTotalRepaid,
                          style: TextStyle(
                            fontSize: AppTypography.sizeSm,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          AmountFormatter.format(total,
                              currency: debt.currency),
                          style: TextStyle(
                            fontSize: AppTypography.sizeSm,
                            fontWeight: AppTypography.semiBold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                        vertical: AppSpacing.space3,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(payment.date),
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeSm,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (payment.accountName != null)
                                  Text(
                                    payment.accountName!,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeXs,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            AmountFormatter.format(payment.montant,
                                currency: debt.currency),
                            style: TextStyle(
                              fontSize: AppTypography.sizeSm,
                              fontWeight: AppTypography.medium,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
