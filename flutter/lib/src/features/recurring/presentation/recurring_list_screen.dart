// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/common_widgets/empty_state_widget.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/features/recurring/presentation/widgets/recurring_list_item.dart';
import 'package:k_budget/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:k_budget/src/utils/relative_date_formatter.dart';

class RecurringListScreen extends ConsumerStatefulWidget {
  const RecurringListScreen({super.key});

  @override
  ConsumerState<RecurringListScreen> createState() =>
      _RecurringListScreenState();
}

class _RecurringListScreenState extends ConsumerState<RecurringListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(recurringListNotifierProvider);
      if (s.items.isEmpty && !s.isLoading) {
        ref.read(recurringListNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringListNotifierProvider);
    final exchangeRateState = ref.watch(exchangeRateListProvider);
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;

    final primaryCurrency = dashboardState.currencies.isNotEmpty
        ? dashboardState.currencies.first
        : null;

    Widget body;

    if (state.isLoading && state.items.isEmpty) {
      body = const RecurringListSkeleton();
    } else if (state.error != null && state.items.isEmpty) {
      body = EmptyStateWidget(
        icon: PhosphorIconsRegular.warning,
        message: l10n.errorGeneric,
        ctaLabel: l10n.retry,
        onCtaTap: () =>
            ref.read(recurringListNotifierProvider.notifier).loadItems(),
      );
    } else if (state.items.isEmpty) {
      body = EmptyStateWidget(
        icon: PhosphorIconsRegular.repeat,
        message: l10n.recurringEmpty,
      );
    } else {
      final isValidatingAll = state.mutatingIds.contains('__all__');
      final overdue = state.items
          .where((i) => i.status == RecurringStatus.overdue)
          .toList();
      final today = state.items
          .where((i) => i.status == RecurringStatus.today)
          .toList();
      final upcoming = state.items
          .where((i) => i.status == RecurringStatus.upcoming)
          .toList();

      body = RefreshIndicator(
        onRefresh: () =>
            ref.read(recurringListNotifierProvider.notifier).loadItems(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4,
                  AppSpacing.space4,
                  AppSpacing.space4,
                  AppSpacing.space2,
                ),
                child: _MonthlySummaryCard(
                  items: state.items,
                  exchangeRates: exchangeRateState.items,
                  primaryCurrency: primaryCurrency,
                ),
              ),
            ),
            if (overdue.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space2,
                    AppSpacing.space4,
                    AppSpacing.space2,
                  ),
                  child: _StatusGroupSection(
                    label: l10n.recurringOverdue.toUpperCase(),
                    labelColor: themeExt.expenseColor,
                    items: overdue,
                    showValidateAll: true,
                    isValidatingAll: isValidatingAll,
                    onValidateAll: () => _handleValidateAll(
                      context,
                      overdue.map((i) => i.id).toList(),
                      l10n,
                    ),
                    onItemTap: (item) =>
                        _showActionSheet(context, item, l10n, themeExt),
                  ),
                ),
              ),
            if (today.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space2,
                    AppSpacing.space4,
                    AppSpacing.space2,
                  ),
                  child: _StatusGroupSection(
                    label: l10n.recurringToday.toUpperCase(),
                    labelColor: colorScheme.primary,
                    items: today,
                    showValidateAll: false,
                    isValidatingAll: false,
                    onValidateAll: () {},
                    onItemTap: (item) =>
                        _showActionSheet(context, item, l10n, themeExt),
                  ),
                ),
              ),
            if (upcoming.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space2,
                    AppSpacing.space4,
                    AppSpacing.space2,
                  ),
                  child: _StatusGroupSection(
                    label: l10n.recurringUpcoming.toUpperCase(),
                    labelColor: colorScheme.onSurfaceVariant,
                    items: upcoming,
                    showValidateAll: false,
                    isValidatingAll: false,
                    onValidateAll: () {},
                    onItemTap: (item) =>
                        _showActionSheet(context, item, l10n, themeExt),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.space12 * 2),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      body: body,
    );
  }

  void _showActionSheet(
    BuildContext context,
    RecurringTransaction item,
    AppLocalizations l10n,
    AppThemeExtension themeExt,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final amountColor = item.type == TransactionType.depense
        ? themeExt.expenseColor
        : themeExt.incomeColor;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.frequency.name.toUpperCase(),
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.semiBold,
                  letterSpacing: AppTypography.labelLetterSpacingForSize12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                AmountFormatter.format(
                  item.montant,
                  currency: item.accountCurrency ?? Currency.eur,
                ),
                style: TextStyle(
                  fontSize: AppTypography.sizeXl,
                  fontWeight: AppTypography.semiBold,
                  color: amountColor,
                ),
              ),
              Text(
                l10n.recurringNextOccurrence(
                  RelativeDateFormatter.formatCompact(item.nextOccurrence),
                ),
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              _ActionButton(
                label: l10n.recurringValidate,
                icon: PhosphorIconsRegular.check,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                isMutating: false,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleValidate(context, item.id, l10n);
                },
              ),
              const SizedBox(height: AppSpacing.space2),
              _ActionButton(
                label: l10n.recurringSkip,
                icon: PhosphorIconsRegular.skipForward,
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
                isMutating: false,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleSkip(context, item.id, l10n);
                },
              ),
              const SizedBox(height: AppSpacing.space2),
              _ActionButton(
                label: l10n.recurringDeactivate,
                icon: PhosphorIconsRegular.pause,
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: themeExt.expenseColor,
                isMutating: false,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleDeactivate(context, item.id, l10n);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleValidateAll(
    BuildContext context,
    List<String> ids,
    AppLocalizations l10n,
  ) async {
    await ref.read(recurringListNotifierProvider.notifier).validateAll(ids);
    if (!context.mounted) return;
    final error = ref.read(recurringListNotifierProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringValidateSuccess)),
      );
    }
  }

  Future<void> _handleValidate(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    await ref.read(recurringListNotifierProvider.notifier).validate(id);
    if (!context.mounted) return;
    final error = ref.read(recurringListNotifierProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringValidateSuccess)),
      );
    }
  }

  Future<void> _handleSkip(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    await ref.read(recurringListNotifierProvider.notifier).skip(id);
    if (!context.mounted) return;
    final error = ref.read(recurringListNotifierProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringSkipSuccess)),
      );
    }
  }

  Future<void> _handleDeactivate(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    await ref.read(recurringListNotifierProvider.notifier).deactivate(id);
    if (!context.mounted) return;
    final error = ref.read(recurringListNotifierProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringDeactivateSuccess)),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isMutating,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isMutating;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
        onPressed: onPressed,
        icon: isMutating
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : PhosphorIcon(icon, size: 20, color: foregroundColor),
        label: Text(label),
      ),
    );
  }
}

class _StatusGroupSection extends StatelessWidget {
  const _StatusGroupSection({
    required this.label,
    required this.labelColor,
    required this.items,
    required this.showValidateAll,
    required this.isValidatingAll,
    required this.onValidateAll,
    required this.onItemTap,
  });

  final String label;
  final Color labelColor;
  final List<RecurringTransaction> items;
  final bool showValidateAll;
  final bool isValidatingAll;
  final VoidCallback onValidateAll;
  final void Function(RecurringTransaction) onItemTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.semiBold,
                letterSpacing: AppTypography.labelLetterSpacingForSize12,
                color: labelColor,
              ),
            ),
            const Spacer(),
            if (showValidateAll)
              if (isValidatingAll)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                      ),
                      shape: const StadiumBorder(),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: onValidateAll,
                    child: Text(
                      l10n.recurringValidateAll,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeXs,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  RecurringListItem(
                    item: items[i],
                    onTap: () => onItemTap(items[i]),
                  ),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppSpacing.space4 + 36 + AppSpacing.space3,
                      color: colorScheme.outlineVariant,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.items,
    required this.exchangeRates,
    required this.primaryCurrency,
  });

  final List<RecurringTransaction> items;
  final List<ExchangeRate> exchangeRates;
  final Currency? primaryCurrency;

  double _toMonthly(RecurringTransaction item) {
    return switch (item.frequency) {
      Frequency.hebdomadaire => item.montant * 4.33,
      Frequency.mensuel => item.montant,
      Frequency.annuel => item.montant / 12,
    };
  }

  double _toPrimary(double monthly, Currency fromCurrency) {
    final target = primaryCurrency;
    if (target == null) return monthly;
    return CurrencyConverter.convert(
          amount: monthly,
          fromCurrency: fromCurrency,
          toCurrency: target,
          rates: exchangeRates,
        ) ??
        monthly;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    double net = 0;
    double totalExpenses = 0;
    int expenseCount = 0;

    for (final item in items) {
      final monthly = _toMonthly(item);
      final fromCurrency = item.accountCurrency ?? Currency.eur;
      final converted = _toPrimary(monthly, fromCurrency);

      if (item.type == TransactionType.depense) {
        net -= converted;
        totalExpenses += converted;
        expenseCount++;
      } else {
        net += converted;
      }
    }

    final displayCurrency = primaryCurrency ?? Currency.eur;
    final netFormatted =
        AmountFormatter.format(net.abs(), currency: displayCurrency);
    final totalFormatted =
        AmountFormatter.format(totalExpenses, currency: displayCurrency);
    final netColor = net >= 0 ? themeExt.incomeColor : themeExt.expenseColor;
    final netPrefix = net >= 0 ? '+' : '−';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recurringMonthlySummaryTitle,
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    fontWeight: AppTypography.semiBold,
                    letterSpacing: AppTypography.labelLetterSpacingForSize12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$netPrefix$netFormatted',
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.semiBold,
                    color: netColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.recurringChargesCount(expenseCount),
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.semiBold,
                  letterSpacing: AppTypography.labelLetterSpacingForSize12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '~$totalFormatted/mois',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.semiBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
