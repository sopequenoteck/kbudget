import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/section_header_sticky.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/enums/modal_type.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/budgets/presentation/budget_month_helpers.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_hero_widget.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_item.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/unbudgeted_detail_sheet.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
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
  Currency _activeCurrency = Currency.eur;
  Timer? _debounceTimer;

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
        ref.read(budgetNotifierProvider.notifier).loadItems(includeInactive: true);
      }
      ref.read(budgetNotifierProvider.notifier).loadOverview();

      final dashState = ref.read(dashboardNotifierProvider);
      if (dashState.currencies.isNotEmpty) {
        setState(() => _activeCurrency = dashState.currencies.first);
      }

      final catState = ref.read(categoryNotifierProvider);
      if (catState.items.isEmpty && !catState.isLoading) {
        ref.read(categoryNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  void dispose() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      final dashState = ref.read(dashboardNotifierProvider);
      _persistCurrencyChange([
        _activeCurrency,
        ...dashState.currencies.where((c) => c != _activeCurrency),
      ]);
    }
    super.dispose();
  }

  void _onMonthChanged(int month, int year) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
    });
    if (isCurrentMonth) {
      ref.read(budgetNotifierProvider.notifier).loadOverview();
    } else {
      ref.read(budgetNotifierProvider.notifier).loadHistory(historyMonth);
    }
  }

  void _onCurrencyChanged(Currency currency) {
    setState(() => _activeCurrency = currency);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      final dashState = ref.read(dashboardNotifierProvider);
      final reordered = [
        currency,
        ...dashState.currencies.where((c) => c != currency),
      ];
      await _persistCurrencyChange(reordered);
      if (!mounted) return;
      // ignore: unawaited_futures
      ref.read(exchangeRateListProvider.notifier).loadItems();
      if (isCurrentMonth) {
        // ignore: unawaited_futures
        ref.read(budgetNotifierProvider.notifier).loadOverview();
      } else {
        // ignore: unawaited_futures
        ref.read(budgetNotifierProvider.notifier).loadHistory(historyMonth);
      }
    });
  }

  Future<void> _persistCurrencyChange(List<Currency> currencies) async {
    try {
      final dataSource = await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      await dataSource.updatePreferences(
        UserPreferenceRequest(
          enabledFeatures: prefs.enabledFeatures,
          navOrder: prefs.navOrder,
          currencies: currencies.map((c) => c.name.toUpperCase()).toList(),
        ),
      );
    } catch (_) {}
  }

  double _convertAmount(double amount, String fromCurrencyStr) {
    final fromCurrency = Currency.values.firstWhereOrNull(
      (c) => c.name.toUpperCase() == fromCurrencyStr.toUpperCase(),
    );
    if (fromCurrency == null || fromCurrency == _activeCurrency) return amount;
    return CurrencyConverter.convert(
          amount: amount,
          fromCurrency: fromCurrency,
          toCurrency: _activeCurrency,
          rates: ref.read(exchangeRateListProvider).items,
        ) ??
        amount;
  }

  void _openUnbudgetedSheet(BuildContext context, BudgetOverview overview) {
    UnbudgetedDetailSheet.show(
      context,
      items: overview.unbudgetedItems,
      total: overview.unbudgetedTotal,
      currency: overview.currency,
    );
  }

  void _openUnbudgetedSheetHistory(BuildContext context, BudgetHistory history) {
    UnbudgetedDetailSheet.show(
      context,
      items: history.unbudgetedItems,
      total: history.unbudgetedTotal,
      currency: history.currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetNotifierProvider);
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final ListState<Category> categoryState = ref.watch(categoryNotifierProvider);
    // Watched for reactive rebuilds when exchange rates change.
    ref.watch(exchangeRateListProvider);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
        slivers: _buildSlivers(
          state: state,
          dashboardState: dashboardState,
          categoryState: categoryState,
          l10n: l10n,
          colorScheme: colorScheme,
        ),
      ),
    );
  }

  List<Widget> _buildSlivers({
    required BudgetListState state,
    required DashboardState dashboardState,
    required ListState<Category> categoryState,
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
  }) {
    // Loading
    if (state.isLoading && state.overview == null && state.history == null) {
      return [
        const SliverToBoxAdapter(child: BudgetHeroSkeleton()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => const BudgetItem.skeleton(),
            childCount: 5,
          ),
        ),
      ];
    }

    // Error
    if (state.error != null && state.overview == null && state.history == null) {
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
                    onPressed: () => isCurrentMonth
                        ? ref.read(budgetNotifierProvider.notifier).loadOverview()
                        : ref.read(budgetNotifierProvider.notifier).loadHistory(historyMonth),
                    icon: const PhosphorIcon(PhosphorIconsRegular.arrowClockwise, size: 20),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (isCurrentMonth) {
      return _buildCurrentMonthSlivers(
        state: state,
        dashboardState: dashboardState,
        categoryState: categoryState,
        l10n: l10n,
        colorScheme: colorScheme,
      );
    } else {
      return _buildHistorySlivers(
        state: state,
        dashboardState: dashboardState,
        l10n: l10n,
        colorScheme: colorScheme,
      );
    }
  }

  List<Widget> _buildCurrentMonthSlivers({
    required BudgetListState state,
    required DashboardState dashboardState,
    required ListState<Category> categoryState,
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
  }) {
    final overview = state.overview;
    final overviewItems = overview?.items ?? <BudgetOverviewItem>[];

    // Calculs conversions actifs
    final convertedItems = overviewItems.map((item) {
      final depense = _convertAmount(item.montantDepense, item.currency);
      final budget = _convertAmount(item.montantBudgetNormalise, item.currency);
      return (item: item, depense: depense, budget: budget);
    }).toList();

    // Items inactifs — uniquement mois courant
    final inactiveItems = state.items.where((b) => !b.actif).toList();

    // Hero data
    final budgetedSpent = overview != null
        ? _convertAmount(overview.totalSpent - overview.unbudgetedTotal, overview.currency)
        : 0.0;
    final convertedUnbudgeted = overview != null
        ? _convertAmount(overview.unbudgetedTotal, overview.currency)
        : 0.0;

    // Ligne secondaire devise2
    final currencies = List<Currency>.from(dashboardState.currencies);
    final devise2 = currencies.length >= 2
        ? currencies.firstWhereOrNull((c) => c != _activeCurrency)
        : null;
    final heroConverted = (devise2 != null && overview != null)
        ? CurrencyConverter.convert(
            amount: budgetedSpent,
            fromCurrency: _activeCurrency,
            toCurrency: devise2,
            rates: ref.read(exchangeRateListProvider).items,
          )
        : null;

    // DoughnutMini segments
    final doughnutSegments = convertedItems
        .where((e) => e.depense > 0)
        .map((e) => DoughnutSegment(value: e.depense, color: e.item.categoryCouleur))
        .toList();

    // Dépassements
    final overBudgetCount = overviewItems.where((i) => i.percentage > 100).length;

    // allCategoriesHaveBudget
    final categoryItems = categoryState.items;
    final nonSystemCats = categoryItems.where((c) => !c.isSystem).toList();
    final budgetedIds = state.items.where((b) => b.actif).map((b) => b.categoryId).toSet();
    final allCategoriesHaveBudget = nonSystemCats.isNotEmpty &&
        nonSystemCats.every((c) => budgetedIds.contains(c.id));

    // Hero widget
    final heroSliver = SliverToBoxAdapter(
      child: BudgetHeroWidget(
        budgetedSpent: budgetedSpent,
        activeCurrency: _activeCurrency,
        heroConverted: heroConverted,
        heroConvertedCurrency: devise2,
        overBudgetCount: overBudgetCount,
        budgetCount: overviewItems.length,
        unbudgetedTotal: convertedUnbudgeted,
        doughnutSegments: doughnutSegments,
        currencies: currencies,
        onCurrencyChanged: _onCurrencyChanged,
        onUnbudgetedTap: overview != null ? () => _openUnbudgetedSheet(context, overview) : null,
        selectedMonth: _selectedMonth,
        selectedYear: _selectedYear,
        isCurrentMonth: isCurrentMonth,
        onPrevNextMonth: (m, y) {
          if (!isPastMonthLimit(m, y)) _onMonthChanged(m, y);
        },
        onChartsTap: () => context.push(RouteNames.budgetDetails),
      ),
    );

    // Section header actions
    final sectionActions = <Widget>[
      if (overview != null && overview.unbudgetedTotal > 0)
        IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.tray, size: 20),
          onPressed: () => _openUnbudgetedSheet(context, overview),
          tooltip: 'Non budgété',
        ),
      IconButton(
        icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
        onPressed: allCategoriesHaveBudget
            ? null
            : () => ref.read(modalNotifierProvider.notifier).open(ModalType.budget),
        tooltip: 'Ajouter un budget',
      ),
    ];

    if (convertedItems.isEmpty && convertedUnbudgeted == 0) {
      return [
        heroSliver,
        SectionHeaderSticky(title: 'Budgets', count: 0, actions: sectionActions),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(colorScheme),
        ),
      ];
    }

    return [
      heroSliver,
      SectionHeaderSticky(
        title: 'Budgets',
        count: convertedItems.length,
        actions: sectionActions,
      ),
      // Items actifs
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final e = convertedItems[i];
            final budget = state.items.firstWhereOrNull((b) => b.id == e.item.budgetId);
            return BudgetItem(
              categoryNom: e.item.categoryNom,
              categoryIcone: e.item.categoryIcone,
              categoryCouleur: e.item.categoryCouleur,
              montantBudget: e.budget,
              montantDepense: e.depense,
              percentage: e.item.percentage,
              currency: _activeCurrency.name,
              onTap: budget != null
                  ? () => ref.read(modalNotifierProvider.notifier).open(
                        ModalType.budget,
                        entity: budget,
                      )
                  : null,
            );
          },
          childCount: convertedItems.length,
        ),
      ),
      // Label + items inactifs (mois courant uniquement)
      if (inactiveItems.isNotEmpty) ...[
        const SliverToBoxAdapter(child: _InactiveLabel()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final b = inactiveItems[i];
              final Category? cat = categoryItems.firstWhereOrNull(
                (c) => c.id == b.categoryId,
              );
              final convertedMontant = _convertAmount(b.montant, b.currency.name);
              return Opacity(
                opacity: 0.5,
                child: BudgetItem(
                  categoryNom: cat?.nom ?? b.categoryNom ?? b.categoryId,
                  categoryIcone: cat?.icone ?? b.categoryIcone ?? '',
                  categoryCouleur: cat?.couleur ?? b.categoryCouleur ?? '',
                  montantBudget: convertedMontant,
                  montantDepense: 0,
                  percentage: 0,
                  currency: _activeCurrency.name,
                  onTap: null,
                  showProgressBar: false,
                ),
              );
            },
            childCount: inactiveItems.length,
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space12 * 2)),
    ];
  }

  List<Widget> _buildHistorySlivers({
    required BudgetListState state,
    required DashboardState dashboardState,
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
  }) {
    final history = state.history;
    final historyItems = history?.items ?? <BudgetHistoryItem>[];

    final convertedItems = historyItems.map((item) {
      final depense = _convertAmount(item.montantDepense, item.currency);
      final budget = _convertAmount(item.montantBudget, item.currency);
      return (item: item, depense: depense, budget: budget);
    }).toList();

    final budgetedSpent = history != null
        ? _convertAmount(history.totalSpent - history.unbudgetedTotal, history.currency)
        : 0.0;
    final convertedUnbudgeted = history != null
        ? _convertAmount(history.unbudgetedTotal, history.currency)
        : 0.0;

    final currencies = List<Currency>.from(dashboardState.currencies);
    final devise2 = currencies.length >= 2
        ? currencies.firstWhereOrNull((c) => c != _activeCurrency)
        : null;
    final heroConverted = (devise2 != null && history != null)
        ? CurrencyConverter.convert(
            amount: budgetedSpent,
            fromCurrency: _activeCurrency,
            toCurrency: devise2,
            rates: ref.read(exchangeRateListProvider).items,
          )
        : null;

    final doughnutSegments = convertedItems
        .where((e) => e.depense > 0)
        .map((e) => DoughnutSegment(value: e.depense, color: e.item.categoryCouleur))
        .toList();

    final overBudgetCount = historyItems.where((i) => i.percentage > 100).length;

    final heroSliver = SliverToBoxAdapter(
      child: BudgetHeroWidget(
        budgetedSpent: budgetedSpent,
        activeCurrency: _activeCurrency,
        heroConverted: heroConverted,
        heroConvertedCurrency: devise2,
        overBudgetCount: overBudgetCount,
        budgetCount: historyItems.length,
        unbudgetedTotal: convertedUnbudgeted,
        doughnutSegments: doughnutSegments,
        currencies: currencies,
        onCurrencyChanged: _onCurrencyChanged,
        onUnbudgetedTap: history != null && history.unbudgetedTotal > 0
            ? () => _openUnbudgetedSheetHistory(context, history)
            : null,
        selectedMonth: _selectedMonth,
        selectedYear: _selectedYear,
        isCurrentMonth: false,
        onPrevNextMonth: (m, y) {
          if (!isPastMonthLimit(m, y)) _onMonthChanged(m, y);
        },
        onChartsTap: () => context.push(RouteNames.budgetDetails),
      ),
    );

    if (convertedItems.isEmpty) {
      return [
        heroSliver,
        const SectionHeaderSticky(title: 'Budgets', count: 0),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(colorScheme),
        ),
      ];
    }

    return [
      heroSliver,
      SectionHeaderSticky(title: 'Budgets', count: convertedItems.length),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final e = convertedItems[i];
            return BudgetItem(
              categoryNom: e.item.categoryNom,
              categoryIcone: e.item.categoryIcone,
              categoryCouleur: e.item.categoryCouleur,
              montantBudget: e.budget,
              montantDepense: e.depense,
              percentage: e.item.percentage,
              currency: _activeCurrency.name,
            );
          },
          childCount: convertedItems.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space12 * 2)),
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
          ],
        ),
      ),
    );
  }
}

// ─── Label Inactifs ──────────────────────────────────────────────────────────

class _InactiveLabel extends StatelessWidget {
  const _InactiveLabel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space2,
      ),
      child: Text(
        'Inactifs',
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          fontWeight: AppTypography.semiBold,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: AppTypography.labelLetterSpacingForSize12,
        ),
      ),
    );
  }
}

