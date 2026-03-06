import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/common_widgets/segmented_filter.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/debts/application/debt_list_state.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final debtState = ref.read(debtNotifierProvider);
      if (debtState.items.isEmpty && !debtState.isLoading) {
        ref.read(debtNotifierProvider.notifier).loadItems();
      }

      final catState = ref.read(categoryNotifierProvider);
      if (catState.items.isEmpty && !catState.isLoading) {
        ref.read(categoryNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtNotifierProvider);
    final catState = ref.watch(categoryNotifierProvider);
    final exchangeRateState = ref.watch(exchangeRateListProvider);
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final categoryMap = <String, Category>{
      for (final c in catState.items) c.id: c,
    };

    // Devise principale : première devise de la config utilisateur
    final primaryCurrency = dashboardState.currencies.isNotEmpty
        ? dashboardState.currencies.first
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(debtNotifierProvider.notifier).refresh();
        } on Exception {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorGeneric)),
            );
          }
        }
      },
      child: CustomScrollView(
        slivers: [
          ..._buildContent(
            state,
            categoryMap,
            colorScheme,
            l10n,
            theme,
            exchangeRates: exchangeRateState.items,
            primaryCurrency: primaryCurrency,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    DebtListState state,
    Map<String, Category> categoryMap,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    ThemeData theme, {
    List<ExchangeRate> exchangeRates = const [],
    Currency? primaryCurrency,
  }) {
    final themeExt = theme.extension<AppThemeExtension>();

    // Loading
    if (state.isLoading) {
      return [
        SliverToBoxAdapter(
          child: _DebtSummaryCard(
            summary: state.summary,
            isLoading: true,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space4),
            child: Column(
              children: List.generate(5, (_) => const ListItem.skeleton()),
            ),
          ),
        ),
      ];
    }

    // Error
    if (state.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.warning,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.errorGeneric,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      fontWeight: AppTypography.medium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(debtNotifierProvider.notifier).refresh(),
                    icon: const PhosphorIcon(PhosphorIconsRegular.arrowClockwise, size: 20),
                    label: Text(l10n.transactionsRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Partition items into prêts and emprunts
    final prets = state.items.where((d) => d.sens == DebtType.pret).toList();
    final emprunts =
        state.items.where((d) => d.sens == DebtType.emprunt).toList();

    // Empty
    if (state.items.isEmpty) {
      final emptyMessage = switch (state.activeFilter) {
        DebtStatusFilter.all => l10n.debtsEmpty,
        DebtStatusFilter.enCours => l10n.debtsEmptyEnCours,
        DebtStatusFilter.rembourse => l10n.debtsEmptyRembourse,
      };

      return [
        SliverToBoxAdapter(
          child: _DebtSummaryCard(
            summary: state.summary,
            isLoading: false,
          ),
        ),
        _buildFilter(state, l10n),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.wallet,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    emptyMessage,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Data
    final dateFormat = DateFormat('d MMMM', 'fr_FR');

    return [
      SliverToBoxAdapter(
        child: _DebtSummaryCard(
          summary: state.summary,
          isLoading: false,
        ),
      ),
      _buildFilter(state, l10n),
      // Prêts section
      if (prets.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: l10n.debtsSectionPrets,
            items: prets,
          ),
        ),
        SliverList.builder(
          itemCount: prets.length,
          itemBuilder: (context, index) => _buildDebtItem(
            prets[index],
            categoryMap,
            colorScheme,
            dateFormat,
            l10n,
            themeExt,
            exchangeRates: exchangeRates,
            primaryCurrency: primaryCurrency,
          ),
        ),
      ],
      // Emprunts section
      if (emprunts.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: l10n.debtsSectionEmprunts,
            items: emprunts,
          ),
        ),
        SliverList.builder(
          itemCount: emprunts.length,
          itemBuilder: (context, index) => _buildDebtItem(
            emprunts[index],
            categoryMap,
            colorScheme,
            dateFormat,
            l10n,
            themeExt,
            exchangeRates: exchangeRates,
            primaryCurrency: primaryCurrency,
          ),
        ),
      ],
      // FAB padding
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    ];
  }

  SliverToBoxAdapter _buildFilter(
    DebtListState state,
    AppLocalizations l10n,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        child: SegmentedFilter<DebtStatusFilter>(
          items: [
            SegmentedFilterItem(
              value: DebtStatusFilter.all,
              label: l10n.debtsFilterAll,
            ),
            SegmentedFilterItem(
              value: DebtStatusFilter.enCours,
              label: l10n.debtsFilterEnCours,
            ),
            SegmentedFilterItem(
              value: DebtStatusFilter.rembourse,
              label: l10n.debtsFilterRembourse,
            ),
          ],
          selectedValue: state.activeFilter,
          onChanged: (f) =>
              ref.read(debtNotifierProvider.notifier).setFilter(f),
        ),
      ),
    );
  }

  Widget _buildDebtItem(
    Debt debt,
    Map<String, Category> categoryMap,
    ColorScheme colorScheme,
    DateFormat dateFormat,
    AppLocalizations l10n,
    AppThemeExtension? themeExt, {
    List<ExchangeRate> exchangeRates = const [],
    Currency? primaryCurrency,
  }) {
    final cat =
        debt.categoryId != null ? categoryMap[debt.categoryId] : null;

    final formattedAmount = AmountFormatter.format(
      debt.montant,
      currency: debt.currency,
    );

    // Sous-texte montant converti si devise étrangère
    String? convertedSubtitle;
    if (primaryCurrency != null &&
        debt.currency != primaryCurrency &&
        exchangeRates.isNotEmpty) {
      final converted = CurrencyConverter.convert(
        amount: debt.montant,
        fromCurrency: debt.currency,
        toCurrency: primaryCurrency,
        rates: exchangeRates,
      );
      if (converted != null) {
        convertedSubtitle =
            '~ ${AmountFormatter.format(converted, currency: primaryCurrency)}';
      }
    }

    return ListItem(
      icon: cat?.icone ?? '💰',
      iconBackgroundColor: cat != null
          ? parseHexColor(cat.couleur)
          : colorScheme.surfaceContainerHighest,
      title: debt.personne,
      subtitle: dateFormat.format(debt.date),
      value: formattedAmount,
      rightSubtitle:
          convertedSubtitle ?? (debt.rembourse ? l10n.debtBadgeRembourse : null),
      onPressed: () {
        ref.read(modalNotifierProvider.notifier).open(
              ModalType.debt,
              entity: debt,
            );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.items,
  });

  final String title;
  final List<Debt> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Compute sub-totals per currency
    final totals = <Currency, double>{};
    for (final debt in items) {
      totals[debt.currency] = (totals[debt.currency] ?? 0) + debt.montant;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: colorScheme.onSurface,
            ),
          ),
          Row(
            spacing: AppSpacing.space2,
            children: totals.entries
                .map(
                  (e) => Text(
                    AmountFormatter.format(e.value, currency: e.key),
                    style: TextStyle(
                      fontSize: AppTypography.sizeSm,
                      fontWeight: AppTypography.medium,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({
    required this.summary,
    required this.isLoading,
  });

  final Map<Currency, DebtCurrencySummary> summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _SummaryCardSkeleton();
    if (summary.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeExt = theme.extension<AppThemeExtension>();
    final l10n = AppLocalizations.of(context)!;

    final entries = summary.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in entries) ...[
              if (entries.indexOf(entry) > 0)
                const SizedBox(height: AppSpacing.space3),
              // Emprunts row
              _SummaryRow(
                label: l10n.debtsSummaryEmprunts,
                amount: entry.value.totalEmprunts,
                currency: entry.key,
                color: themeExt?.debtOweColor ?? colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.space1),
              // Prêts row
              _SummaryRow(
                label: l10n.debtsSummaryPrets,
                amount: entry.value.totalPrets,
                currency: entry.key,
                color: themeExt?.debtOwedColor ?? colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.space1),
              // Solde net row
              Builder(
                builder: (context) {
                  final net =
                      entry.value.totalPrets - entry.value.totalEmprunts;
                  final netColor = net > 0
                      ? themeExt?.incomeColor ?? colorScheme.primary
                      : net < 0
                          ? themeExt?.expenseColor ?? colorScheme.error
                          : colorScheme.onSurfaceVariant;
                  return _SummaryRow(
                    label: l10n.debtsSummaryNet,
                    amount: net.abs(),
                    currency: entry.key,
                    color: netColor,
                    prefix: net > 0
                        ? '+'
                        : net < 0
                            ? '-'
                            : '',
                    isBold: true,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    this.prefix = '',
    this.isBold = false,
  });

  final String label;
  final double amount;
  final Currency currency;
  final Color color;
  final String prefix;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatted = AmountFormatter.format(amount, currency: currency);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? AppTypography.sizeSm : AppTypography.sizeXs,
            fontWeight:
                isBold ? AppTypography.semiBold : AppTypography.medium,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '$prefix$formatted',
          style: TextStyle(
            fontSize: isBold ? AppTypography.sizeMd : AppTypography.sizeSm,
            fontWeight:
                isBold ? AppTypography.bold : AppTypography.semiBold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
