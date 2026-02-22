import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/common_widgets/month_selector.dart';
import 'package:k_budget/src/common_widgets/segmented_filter.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/transactions/application/transaction_list_notifier.dart';
import 'package:k_budget/src/features/transactions/application/transaction_list_state.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_day_group.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_summary_card.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      ref
          .read(transactionListNotifierProvider.notifier)
          .loadMonth(now.month, now.year);
      // Charger les catégories si pas encore chargées
      final catState = ref.read(categoryNotifierProvider);
      if (catState.items.isEmpty && !catState.isLoading) {
        ref.read(categoryNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListNotifierProvider);
    final notifier = ref.read(transactionListNotifierProvider.notifier);
    final catState = ref.watch(categoryNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Map catégories par id
    final categoryMap = <String, Category>{
      for (final c in catState.items) c.id: c,
    };

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await notifier.refresh();
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
          // MonthSelector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.space4,
                bottom: AppSpacing.space3,
              ),
              child: Center(
                child: MonthSelector(
                  initialMonth: state.selectedMonth,
                  initialYear: state.selectedYear,
                  onChanged: notifier.changeMonth,
                ),
              ),
            ),
          ),

          // Résumé mensuel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: TransactionSummaryCard(
                summary: state.summary,
                isLoading: state.isLoading,
              ),
            ),
          ),

          // Filtre segmenté
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              child: SegmentedFilter<TransactionTypeFilter>(
                items: [
                  SegmentedFilterItem(
                    value: TransactionTypeFilter.all,
                    label: l10n.transactionsFilterAll,
                  ),
                  SegmentedFilterItem(
                    value: TransactionTypeFilter.depense,
                    label: l10n.transactionsFilterDepenses,
                  ),
                  SegmentedFilterItem(
                    value: TransactionTypeFilter.recette,
                    label: l10n.transactionsFilterRecettes,
                  ),
                ],
                selectedValue: state.activeFilter,
                onChanged: notifier.setFilter,
              ),
            ),
          ),

          // Contenu principal
          ..._buildContent(state, notifier, categoryMap, colorScheme, l10n),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    TransactionListState state,
    TransactionListNotifier notifier,
    Map<String, Category> categoryMap,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    // Loading
    if (state.isLoading) {
      return [
        SliverToBoxAdapter(
          child: Column(
            children: List.generate(5, (_) => const ListItem.skeleton()),
          ),
        ),
      ];
    }

    // Erreur
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
                  Icon(
                    Icons.error_outline,
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
                    onPressed: () => notifier.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.transactionsRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Vide
    if (state.filteredTransactions.isEmpty) {
      final message = switch (state.activeFilter) {
        TransactionTypeFilter.all => l10n.transactionsEmptyMonth,
        TransactionTypeFilter.depense => l10n.transactionsEmptyDepenses,
        TransactionTypeFilter.recette => l10n.transactionsEmptyRecettes,
      };

      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    message,
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

    // Données — grouper par jour
    final grouped = groupBy(
      state.filteredTransactions,
      (tx) => DateTime(tx.date.year, tx.date.month, tx.date.day),
    );
    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return [
      SliverList.builder(
        itemCount: sortedDays.length,
        itemBuilder: (context, index) {
          final day = sortedDays[index];
          final dayTxs = grouped[day]!;
          return TransactionDayGroup(
            date: day,
            transactions: dayTxs,
            categories: categoryMap,
            onTransactionTap: (tx) => _onTransactionTap(tx.id),
          );
        },
      ),
      // Padding en bas pour le FAB
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    ];
  }

  void _onTransactionTap(String id) {
    // Navigation préparée — no-op tant que le formulaire d'édition n'existe pas.
    // Sera activé quand la route /transactions/:id sera ajoutée au router.
  }
}
