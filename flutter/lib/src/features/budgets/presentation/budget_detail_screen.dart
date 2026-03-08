import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/month_selector.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_category_detail_sheet.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_pie_chart.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:k_budget/src/features/budgets/presentation/budget_month_helpers.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BudgetDetailScreen extends ConsumerStatefulWidget {
  const BudgetDetailScreen({super.key, this.month});

  final String? month;

  @override
  ConsumerState<BudgetDetailScreen> createState() =>
      _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen>
    with BudgetMonthHelpers {
  late int _selectedMonth;
  late int _selectedYear;

  @override
  int get selectedMonth => _selectedMonth;
  @override
  int get selectedYear => _selectedYear;

  @override
  void initState() {
    super.initState();
    final parsed = _parseMonth(widget.month);
    _selectedMonth = parsed.$1;
    _selectedYear = parsed.$2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForSelectedMonth();
    });
  }

  (int, int) _parseMonth(String? raw) {
    if (raw == null) {
      final now = DateTime.now();
      return (now.month, now.year);
    }
    final parts = raw.split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && month != null && month >= 1 && month <= 12) {
        return (month, year);
      }
    }
    final now = DateTime.now();
    return (now.month, now.year);
  }

  void _loadDataForSelectedMonth() {
    if (isCurrentMonth) {
      ref.read(budgetNotifierProvider.notifier).loadOverview();
    } else {
      ref.read(budgetNotifierProvider.notifier).loadHistory(historyMonth);
    }
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
    final state = ref.watch(budgetNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.budgetDetails),
      ),
      body: CustomScrollView(
        slivers: [
          // Sélecteur de mois
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              child: Center(
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
            ),
          ),
          // Contenu principal
          if (state.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorState(state.error!, colorScheme),
            )
          else if (isCurrentMonth)
            ..._buildCurrentMonthContent(state.overview, colorScheme)
          else
            ..._buildHistoryContent(state.history, colorScheme),
        ],
      ),
    );
  }

  List<Widget> _buildCurrentMonthContent(
    BudgetOverview? overview,
    ColorScheme colorScheme,
  ) {
    final items = overview?.items ?? <BudgetOverviewItem>[];

    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(colorScheme),
        ),
      ];
    }

    final pieItems = items
        .where((item) => item.montantDepense > 0)
        .map((item) {
          final color = parseHexColor(item.categoryCouleur) ??
              colorScheme.primary;
          return PieChartItem(
            label: item.categoryNom,
            value: item.montantDepense,
            color: color,
          );
        })
        .toList();

    final allPieItems = items.asMap().entries.map((entry) {
      final item = entry.value;
      final color = parseHexColor(item.categoryCouleur) ?? colorScheme.primary;
      return PieChartItem(
        label: item.categoryNom,
        value: item.montantDepense > 0 ? item.montantDepense : 0.01,
        color: item.montantDepense > 0
            ? color
            : color.withValues(alpha: 0.3),
      );
    }).toList();

    final displayItems =
        pieItems.isNotEmpty ? allPieItems : <PieChartItem>[];

    return [
      // Graphique camembert
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: BudgetPieChart(
            items: displayItems,
            size: 220,
            onSectionTapped: (index) {
              if (index < items.length) {
                final item = items[index];
                BudgetCategoryDetailSheet.show(
                  context,
                  categoryNom: item.categoryNom,
                  categoryIcone: item.categoryIcone,
                  categoryCouleur: item.categoryCouleur,
                  montantDepense: item.montantDepense,
                  montantBudget: item.montantBudgetNormalise,
                  percentage: item.percentage,
                  currency: item.currency,
                );
              }
            },
          ),
        ),
      ),
      // Liste des catégories
      SliverPadding(
        padding: const EdgeInsets.only(
          left: AppSpacing.space4,
          right: AppSpacing.space4,
          top: AppSpacing.space2,
        ),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _BudgetItemRow(
              categoryIcone: item.categoryIcone,
              categoryNom: item.categoryNom,
              categoryCouleur: item.categoryCouleur,
              montantDepense: item.montantDepense,
              montantBudget: item.montantBudgetNormalise,
              percentage: item.percentage,
              currency: item.currency,
              onTap: () => BudgetCategoryDetailSheet.show(
                context,
                categoryNom: item.categoryNom,
                categoryIcone: item.categoryIcone,
                categoryCouleur: item.categoryCouleur,
                montantDepense: item.montantDepense,
                montantBudget: item.montantBudgetNormalise,
                percentage: item.percentage,
                currency: item.currency,
              ),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    ];
  }

  List<Widget> _buildHistoryContent(
    BudgetHistory? history,
    ColorScheme colorScheme,
  ) {
    final items = history?.items ?? <BudgetHistoryItem>[];

    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(colorScheme),
        ),
      ];
    }

    final allPieItems = items.asMap().entries.map((entry) {
      final item = entry.value;
      final color = parseHexColor(item.categoryCouleur) ?? colorScheme.primary;
      return PieChartItem(
        label: item.categoryNom,
        value: item.montantDepense > 0 ? item.montantDepense : 0.01,
        color: item.montantDepense > 0
            ? color
            : color.withValues(alpha: 0.3),
      );
    }).toList();

    return [
      // Graphique camembert
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: BudgetPieChart(
            items: allPieItems,
            size: 220,
            onSectionTapped: (index) {
              if (index < items.length) {
                final item = items[index];
                BudgetCategoryDetailSheet.show(
                  context,
                  categoryNom: item.categoryNom,
                  categoryIcone: item.categoryIcone,
                  categoryCouleur: item.categoryCouleur,
                  montantDepense: item.montantDepense,
                  montantBudget: item.montantBudget,
                  percentage: item.percentage,
                  currency: item.currency,
                );
              }
            },
          ),
        ),
      ),
      // Liste des catégories
      SliverPadding(
        padding: const EdgeInsets.only(
          left: AppSpacing.space4,
          right: AppSpacing.space4,
          top: AppSpacing.space2,
        ),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _BudgetItemRow(
              categoryIcone: item.categoryIcone,
              categoryNom: item.categoryNom,
              categoryCouleur: item.categoryCouleur,
              montantDepense: item.montantDepense,
              montantBudget: item.montantBudget,
              percentage: item.percentage,
              currency: item.currency,
              onTap: () => BudgetCategoryDetailSheet.show(
                context,
                categoryNom: item.categoryNom,
                categoryIcone: item.categoryIcone,
                categoryCouleur: item.categoryCouleur,
                montantDepense: item.montantDepense,
                montantBudget: item.montantBudget,
                percentage: item.percentage,
                currency: item.currency,
              ),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    ];
  }

  Widget _buildErrorState(String error, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
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
              l10n.errorLoadingData,
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            FilledButton.icon(
              onPressed: _loadDataForSelectedMonth,
              icon: const PhosphorIcon(
                PhosphorIconsRegular.arrowClockwise,
                size: 20,
              ),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
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
              PhosphorIconsRegular.chartPie,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              l10n.emptyBudgetData,
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

// ── Ligne item générique (overview et historique) ────────────────────────────

class _BudgetItemRow extends StatelessWidget {
  const _BudgetItemRow({
    required this.categoryIcone,
    required this.categoryNom,
    required this.categoryCouleur,
    required this.montantDepense,
    required this.montantBudget,
    required this.percentage,
    required this.currency,
    required this.onTap,
  });

  final String categoryIcone;
  final String categoryNom;
  final String categoryCouleur;
  final double montantDepense;
  final double montantBudget;
  final double percentage;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = parseHexColor(categoryCouleur);
    final isOverBudget = percentage > 100;

    final currencyEnum = Currency.values.byNameOrDefault(
      currency.toLowerCase(),
      Currency.eur,
    );

    final formattedSpent =
        AmountFormatter.format(montantDepense, currency: currencyEnum);
    final formattedBudget =
        AmountFormatter.format(montantBudget, currency: currencyEnum);
    final percentageText = '${percentage.toStringAsFixed(0)} %';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
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
              decoration: BoxDecoration(
                color: categoryColor ?? colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              categoryIcone,
              style: const TextStyle(fontSize: AppTypography.sizeMd),
            ),
            Expanded(
              child: Text(
                categoryNom,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$formattedSpent / $formattedBudget',
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isOverBudget
                    ? AppColors.errorLight
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                percentageText,
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.semiBold,
                  color: isOverBudget
                      ? AppColors.textError
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
