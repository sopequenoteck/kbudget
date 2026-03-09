import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/month_selector.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/enums/modal_type.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_item.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_summary_bar.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/unbudgeted_detail_sheet.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/features/budgets/presentation/budget_month_helpers.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BudgetListScreen extends ConsumerStatefulWidget {
  const BudgetListScreen({super.key});

  @override
  ConsumerState<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends ConsumerState<BudgetListScreen>
    with BudgetMonthHelpers {
  late int _selectedMonth;
  late int _selectedYear;
  bool _showInactive = false;

  @override
  int get selectedMonth => _selectedMonth;
  @override
  int get selectedYear => _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budgetState = ref.read(budgetNotifierProvider);
      if (budgetState.items.isEmpty && !budgetState.isLoading) {
        ref
            .read(budgetNotifierProvider.notifier)
            .loadItems(includeInactive: _showInactive);
      }
      ref.read(budgetNotifierProvider.notifier).loadOverview();
    });
  }

  void _onMonthChanged(int month, int year) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
    });
    ref.read(budgetNotifierProvider.notifier).setMonth(month, year);

    if (isCurrentMonth) {
      ref.read(budgetNotifierProvider.notifier).loadOverview();
    } else {
      ref.read(budgetNotifierProvider.notifier).loadHistory(historyMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BudgetListState state = ref.watch(budgetNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(budgetNotifierProvider.notifier).refresh();
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
          // Sélecteur de mois
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: PhosphorIcon(
                      _showInactive
                          ? PhosphorIconsFill.eye
                          : PhosphorIconsRegular.eye,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() => _showInactive = !_showInactive);
                      ref
                          .read(budgetNotifierProvider.notifier)
                          .loadItems(includeInactive: _showInactive);
                    },
                    tooltip: l10n.budgetShowInactive,
                  ),
                  Flexible(
                    child: MonthSelector(
                      initialMonth: _selectedMonth,
                      initialYear: _selectedYear,
                      onChanged: (month, year) {
                        if (!isPastMonthLimit(month, year)) {
                          _onMonthChanged(month, year);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.chartBar,
                      size: 24,
                    ),
                    onPressed: () => context.push(RouteNames.budgetDetails),
                    tooltip: l10n.budgetViewCharts,
                  ),
                ],
              ),
            ),
          ),
          ..._buildContent(state, colorScheme, l10n),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    BudgetListState state,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    // Loading
    if (state.isLoading) {
      return [
        const SliverToBoxAdapter(
          child: BudgetSummaryBar.skeleton(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Column(
              children: List.generate(5, (_) => const BudgetItem.skeleton()),
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
                        ref.read(budgetNotifierProvider.notifier).refresh(),
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.arrowClockwise,
                      size: 20,
                    ),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Données du mois courant ou historique
    if (isCurrentMonth) {
      return _buildCurrentMonth(state, colorScheme);
    } else {
      return _buildHistoryMonth(state, colorScheme);
    }
  }

  List<Widget> _buildCurrentMonth(
    BudgetListState state,
    ColorScheme colorScheme,
  ) {
    final overview = state.overview;

    // Résumé global
    final summaryBar = overview != null
        ? SliverToBoxAdapter(
            child: BudgetSummaryBar(
              totalBudget: overview.totalBudget,
              totalSpent: overview.totalSpent,
              percentage: overview.percentage,
              currency: overview.currency,
            ),
          )
        : const SliverToBoxAdapter(child: SizedBox.shrink());

    final items = overview?.items ?? <BudgetOverviewItem>[];

    if (items.isEmpty) {
      return [
        summaryBar,
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(colorScheme),
        ),
      ];
    }

    return [
      summaryBar,
      SliverPadding(
        padding: const EdgeInsets.only(top: AppSpacing.space2),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final budget = _findBudget(state.items, item.budgetId);
            final isInactive = budget != null && !budget.actif;
            final budgetItem = BudgetItem(
              categoryNom: item.categoryNom,
              categoryIcone: item.categoryIcone,
              categoryCouleur: item.categoryCouleur,
              montantBudget: item.montantBudgetNormalise,
              montantDepense: item.montantDepense,
              percentage: item.percentage,
              currency: item.currency,
              onTap: budget != null
                  ? () => ref.read(modalNotifierProvider.notifier).open(
                        ModalType.budget,
                        entity: budget,
                      )
                  : null,
            );
            return isInactive
                ? Opacity(opacity: 0.5, child: budgetItem)
                : budgetItem;
          },
        ),
      ),
      // Section "Autre" — dépenses hors budget
      if (overview != null && overview.unbudgetedTotal > 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: InkWell(
              onTap: () => UnbudgetedDetailSheet.show(
                context,
                items: overview.unbudgetedItems,
                total: overview.unbudgetedTotal,
                currency: overview.currency,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: _buildOtherRow(overview.unbudgetedTotal, overview.currency),
            ),
          ),
        ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    ];
  }

  List<Widget> _buildHistoryMonth(
    BudgetListState state,
    ColorScheme colorScheme,
  ) {
    final history = state.history;

    // Résumé global
    final summaryBar = history != null
        ? SliverToBoxAdapter(
            child: BudgetSummaryBar(
              totalBudget: history.totalBudget,
              totalSpent: history.totalSpent,
              percentage: history.percentage,
              currency: history.currency,
            ),
          )
        : const SliverToBoxAdapter(child: SizedBox.shrink());

    final items = history?.items ?? <BudgetHistoryItem>[];

    if (items.isEmpty) {
      return [
        summaryBar,
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(colorScheme),
        ),
      ];
    }

    return [
      summaryBar,
      SliverPadding(
        padding: const EdgeInsets.only(top: AppSpacing.space2),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return BudgetItem(
              categoryNom: item.categoryNom,
              categoryIcone: item.categoryIcone,
              categoryCouleur: item.categoryCouleur,
              montantBudget: item.montantBudget,
              montantDepense: item.montantDepense,
              percentage: item.percentage,
              currency: item.currency,
            );
          },
        ),
      ),
      // Section "Autre" — dépenses hors budget
      if (history != null && history.unbudgetedTotal > 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: InkWell(
              onTap: () => UnbudgetedDetailSheet.show(
                context,
                items: history.unbudgetedItems,
                total: history.unbudgetedTotal,
                currency: history.currency,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: _buildOtherRow(history.unbudgetedTotal, history.currency),
            ),
          ),
        ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    ];
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.chartBar,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              l10n.emptyBudgetList,
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              l10n.emptyBudgetCreateHint,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherRow(double total, String currency) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyEnum = Currency.values.byNameOrDefault(
      currency.toLowerCase(),
      Currency.eur,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space3,
        horizontal: AppSpacing.space2,
      ),
      child: Row(
        spacing: AppSpacing.space3,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF9ca3af),
              shape: BoxShape.circle,
            ),
          ),
          const Text(
            '📦',
            style: TextStyle(fontSize: AppTypography.sizeMd),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.budgetOtherCategory,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            AmountFormatter.format(total, currency: currencyEnum),
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          PhosphorIcon(
            PhosphorIconsRegular.caretRight,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Budget? _findBudget(List<Budget> budgets, String budgetId) {
    try {
      return budgets.firstWhere((b) => b.id == budgetId);
    } catch (_) {
      return null;
    }
  }
}
