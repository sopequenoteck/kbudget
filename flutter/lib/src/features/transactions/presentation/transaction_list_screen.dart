import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/common_widgets/month_selector.dart';
import 'package:k_budget/src/common_widgets/section_header_sticky.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/features/transactions/application/transaction_list_notifier.dart';
import 'package:k_budget/src/features/transactions/application/transaction_list_state.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_day_group.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_hero_widget.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
      // Charger les transactions si pas encore chargées
      final txState = ref.read(transactionListNotifierProvider);
      if (txState.allMonthTransactions.isEmpty && !txState.isLoading) {
        ref.read(transactionListNotifierProvider.notifier)
            .loadMonth(txState.selectedMonth, txState.selectedYear);
      }

      // Charger les catégories si pas encore chargées
      final catState = ref.read(categoryNotifierProvider);
      if (catState.items.isEmpty && !catState.isLoading) {
        ref.read(categoryNotifierProvider.notifier).loadItems();
      }

      // Charger les comptes si pas encore chargés (pour le formulaire)
      final accState = ref.read(accountNotifierProvider);
      if (accState.items.isEmpty && !accState.isLoading) {
        ref.read(accountNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListNotifierProvider);
    final catState = ref.watch(categoryNotifierProvider);
    final accState = ref.watch(accountNotifierProvider);
    final exchangeRateState = ref.watch(exchangeRateListProvider);
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Map catégories par id
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
          await ref.read(transactionListNotifierProvider.notifier).refresh();
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
                  onChanged: (m, y) => ref.read(transactionListNotifierProvider.notifier).changeMonth(m, y),
                ),
              ),
            ),
          ),

          // Hero solde mensuel
          SliverToBoxAdapter(
            child: TransactionHeroWidget(
              summary: state.summary,
              primaryCurrency: primaryCurrency,
              isLoading: state.isLoading,
            ),
          ),

          // SectionHeaderSticky
          const SectionHeaderSticky(title: 'Transactions'),

          // Contenu principal (groupement sémantique)
          ..._buildContent(
            state,
            categoryMap,
            colorScheme,
            l10n,
            accounts: accState.items,
            exchangeRates: exchangeRateState.items,
            primaryCurrency: primaryCurrency,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    TransactionListState state,
    Map<String, Category> categoryMap,
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    List<Account> accounts = const [],
    List<ExchangeRate> exchangeRates = const [],
    Currency? primaryCurrency,
  }) {
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
                    onPressed: () => ref.read(transactionListNotifierProvider.notifier).refresh(),
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

    // Groupement sémantique
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final semanticGroups = _groupBySemantics(state.allMonthTransactions, todayDate);

    // Vide
    if (semanticGroups.isEmpty) {
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
                    PhosphorIconsRegular.receipt,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.transactionsEmptyMonth,
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

    // Données
    final widgets = <Widget>[];
    for (final entry in semanticGroups.entries) {
      final bucketLabel = entry.key;
      final bucketTxs = entry.value;
      final labelColor = bucketLabel == "Aujourd'hui"
          ? AppColors.amber500
          : colorScheme.onSurfaceVariant;

      // Date-label header
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            child: Text(
              bucketLabel,
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                color: labelColor,
              ),
            ),
          ),
        ),
      );

      // Sub-grouper par jour
      final grouped = <DateTime, List<Transaction>>{};
      for (final tx in bucketTxs) {
        final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
        grouped.putIfAbsent(day, () => []).add(tx);
      }
      final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      widgets.add(
        SliverList.builder(
          itemCount: sortedDays.length,
          itemBuilder: (context, index) {
            final dayTxs = grouped[sortedDays[index]]!;
            return TransactionDayGroup(
              transactions: dayTxs,
              categories: categoryMap,
              accounts: accounts,
              exchangeRates: exchangeRates,
              primaryCurrency: primaryCurrency,
              onTransactionTap: (tx) {
                if (tx.type == TransactionType.ajustement) return;
                ref.read(modalNotifierProvider.notifier).open(
                  ModalType.transaction,
                  entity: tx,
                );
              },
            );
          },
        ),
      );
    }

    widgets.add(const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space12 * 2)));
    return widgets;
  }

  Map<String, List<Transaction>> _groupBySemantics(
    List<Transaction> items,
    DateTime today,
  ) {
    const kSemanticGroups = [
      "Aujourd'hui",
      'Hier',
      'Cette semaine',
      'Semaine dernière',
      'Plus ancien',
    ];

    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));

    final raw = <String, List<Transaction>>{};
    for (final tx in items) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final String bucket;
      if (txDate == today) {
        bucket = "Aujourd'hui";
      } else if (txDate == yesterday) {
        bucket = 'Hier';
      } else if (!txDate.isBefore(startOfWeek)) {
        bucket = 'Cette semaine';
      } else if (!txDate.isBefore(startOfLastWeek)) {
        bucket = 'Semaine dernière';
      } else {
        bucket = 'Plus ancien';
      }
      raw.putIfAbsent(bucket, () => []).add(tx);
    }

    final ordered = <String, List<Transaction>>{};
    for (final key in kSemanticGroups) {
      if (raw.containsKey(key)) ordered[key] = raw[key]!;
    }
    return ordered;
  }
}
