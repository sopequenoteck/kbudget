// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/common_widgets/confirm_dialog_custom.dart';
import 'package:k_budget/src/common_widgets/empty_state_widget.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/enums/modal_type.dart';
import 'package:k_budget/src/domain/enums/transaction_type.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/budgets/application/budget_transactions_provider.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class BudgetDetailScreen extends ConsumerStatefulWidget {
  const BudgetDetailScreen({super.key, required this.categoryId, this.month});

  final String categoryId;
  final String? month; // format YYYY-MM, null = mois courant

  @override
  ConsumerState<BudgetDetailScreen> createState() =>
      _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen> {
  late int _selectedMonth;
  late int _selectedYear;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth == now.month && _selectedYear == now.year;
  }

  String get _historyMonth =>
      '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _parseMonth();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _parseMonth() {
    if (widget.month == null) {
      final now = DateTime.now();
      _selectedMonth = now.month;
      _selectedYear = now.year;
      return;
    }
    final parts = widget.month!.split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && month != null && month >= 1 && month <= 12) {
        _selectedMonth = month;
        _selectedYear = year;
        return;
      }
    }
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  void _loadData() {
    if (_isCurrentMonth) {
      ref.read(budgetNotifierProvider.notifier).loadOverview();
    } else {
      ref.read(budgetNotifierProvider.notifier).loadHistory(_historyMonth);
    }
    final accountState = ref.read(accountNotifierProvider);
    if (accountState.items.isEmpty && !accountState.isLoading) {
      ref.read(accountNotifierProvider.notifier).loadItems();
    }
  }

  BudgetOverviewItem? _findOverviewItem(BudgetListState state) =>
      state.overview?.items.firstWhereOrNull(
          (i) => i.categoryId == widget.categoryId);

  Budget? _findFallbackBudget(BudgetListState state) =>
      state.items.firstWhereOrNull(
          (b) => b.categoryId == widget.categoryId);

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<void> _onDelete(String budgetId) async {
    final confirmed = await ConfirmDialogCustom.show(
      context: context,
      icon: PhosphorIconsRegular.trash,
      title: 'Supprimer ce budget ?',
      message: 'Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      variant: ConfirmVariant.danger,
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await ref.read(budgetNotifierProvider.notifier).delete(budgetId);
    if (!mounted) return;
    context.go(RouteNames.budgets);
  }

  // ── Toggle actif ─────────────────────────────────────────────────────────

  Future<void> _onToggle(String budgetId) async {
    final repo = ref.read(budgetRepositoryProvider);
    final budget = await repo.getById(budgetId);
    if (!mounted) return;
    await ref.read(budgetNotifierProvider.notifier).update(
          budget.copyWith(actif: !budget.actif),
        );
    if (!mounted) return;
    context.go(RouteNames.budgets);
  }

  // ── Edit ─────────────────────────────────────────────────────────────────

  Future<void> _onEdit(String budgetId) async {
    final repo = ref.read(budgetRepositoryProvider);
    final budget = await repo.getById(budgetId);
    if (!mounted) return;
    ref.read(modalNotifierProvider.notifier).open(
          ModalType.budget,
          entity: budget,
        );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetNotifierProvider);
    final accounts = ref.watch(accountNotifierProvider).items;

    final overviewItem = _findOverviewItem(state);
    final fallbackBudget = _findFallbackBudget(state);

    // Données du hero (depuis overview ou fallback)
    final String categoryNom = overviewItem?.categoryNom ??
        fallbackBudget?.categoryNom ??
        fallbackBudget?.categoryId ??
        'Budget';
    final String categoryIcone =
        overviewItem?.categoryIcone ?? fallbackBudget?.categoryIcone ?? '';
    final String categoryCouleur =
        overviewItem?.categoryCouleur ?? fallbackBudget?.categoryCouleur ?? '';
    final double montantDepense = overviewItem?.montantDepense ?? 0;
    final double montantBudget = overviewItem?.montantBudgetNormalise ??
        fallbackBudget?.montant ?? 0;
    final double percentage = overviewItem?.percentage ?? 0;
    final Currency currency = overviewItem != null
        ? Currency.values.byNameOrDefault(
            overviewItem.currency.toLowerCase(), Currency.eur)
        : (fallbackBudget?.currency ?? Currency.eur);

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(categoryNom, categoryIcone, categoryCouleur),
      ),
      body: state.isLoading
          ? _buildHeroSkeleton()
          : state.error != null
              ? _buildErrorState(state.error!)
              : _buildBody(
                  overviewItem: overviewItem,
                  fallbackBudget: fallbackBudget,
                  categoryNom: categoryNom,
                  categoryIcone: categoryIcone,
                  categoryCouleur: categoryCouleur,
                  montantDepense: montantDepense,
                  montantBudget: montantBudget,
                  percentage: percentage,
                  currency: currency,
                  accounts: accounts,
                ),
    );
  }

  // ── Title ────────────────────────────────────────────────────────────────

  Widget _buildTitle(
      String categoryNom, String categoryIcone, String categoryCouleur) {
    if (categoryNom == 'Budget' && categoryIcone.isEmpty) {
      return const Text('Budget');
    }
    final bgColor = parseHexColor(categoryCouleur);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (categoryIcone.isNotEmpty) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor?.withValues(alpha: 0.15) ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(categoryIcone, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: AppSpacing.space2),
        ],
        Text(categoryNom),
      ],
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody({
    required BudgetOverviewItem? overviewItem,
    required Budget? fallbackBudget,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantDepense,
    required double montantBudget,
    required double percentage,
    required Currency currency,
    required List<Account> accounts,
  }) {
    final txAsync = ref.watch(budgetTransactionsProvider(
      (month: _selectedMonth, year: _selectedYear),
    ));

    final filteredTx = txAsync.valueOrNull
        ?.where((tx) =>
            tx.categoryId == widget.categoryId &&
            tx.type == TransactionType.depense)
        .toList()
      ?..sort((a, b) => b.date.compareTo(a.date));

    final txCount = filteredTx?.length ?? 0;

    final transactionSlivers = txAsync.when(
      loading: () => [_buildTransactionSkeletons()],
      error: (e, _) => [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('Erreur de chargement des transactions')),
        ),
      ],
      data: (_) {
        if (filteredTx == null || filteredTx.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: PhosphorIconsRegular.receipt,
                message: 'Aucune transaction ce mois',
              ),
            ),
          ];
        }
        final groups = _groupByDate(filteredTx);
        return groups
            .expand((group) => [
                  SliverToBoxAdapter(child: _DateLabel(label: group.label)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TransactionRow(
                        tx: group.transactions[i],
                        accounts: accounts,
                        budgetCurrency: currency,
                      ),
                      childCount: group.transactions.length,
                    ),
                  ),
                ])
            .toList();
      },
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space2,
            ),
            child: _buildHero(
              categoryNom: categoryNom,
              categoryCouleur: categoryCouleur,
              montantDepense: montantDepense,
              montantBudget: montantBudget,
              percentage: percentage,
              currency: currency,
            ),
          ),
        ),
        if (_isCurrentMonth &&
            overviewItem != null &&
            overviewItem.budgetId.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              child: _buildActionPills(overviewItem.budgetId),
            ),
          ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyTransactionHeader(count: txCount),
        ),
        ...transactionSlivers,
      ],
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────

  Widget _buildHero({
    required String categoryNom,
    required String categoryCouleur,
    required double montantDepense,
    required double montantBudget,
    required double percentage,
    required Currency currency,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;
    final isExceeded = percentage > 100;
    final isWarning = percentage > 80 && percentage <= 100;

    final formattedSpent =
        AmountFormatter.format(montantDepense, currency: currency);
    final formattedBudget =
        AmountFormatter.format(montantBudget, currency: currency);
    final reste = montantBudget - montantDepense;
    final formattedReste =
        AmountFormatter.format(reste.abs(), currency: currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DÉPENSÉ',
          style: TextStyle(
            fontSize: AppTypography.sizeXs,
            fontWeight: AppTypography.medium,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          formattedSpent,
          style: TextStyle(
            fontSize: AppTypography.size2xl,
            fontWeight: AppTypography.bold,
            color:
                isExceeded ? themeExt.expenseColor : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        // Méta-ligne
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(PhosphorIconsRegular.target,
                size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              formattedBudget,
              style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: colorScheme.onSurfaceVariant),
            ),
            Text(
              ' · ',
              style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: colorScheme.onSurfaceVariant),
            ),
            PhosphorIcon(
              isExceeded
                  ? PhosphorIconsRegular.warning
                  : PhosphorIconsRegular.chartPie,
              size: 14,
              color: isExceeded
                  ? themeExt.expenseColor
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              isExceeded
                  ? 'dépassement de $formattedReste'
                  : 'reste $formattedReste',
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                color: isExceeded
                    ? themeExt.expenseColor
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (percentage > 0) ...[
          const SizedBox(height: AppSpacing.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded
                    ? themeExt.expenseColor
                    : isWarning
                        ? themeExt.textWarning
                        : parseHexColor(categoryCouleur) ??
                            colorScheme.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  // ── Action pills ─────────────────────────────────────────────────────────

  Widget _buildActionPills(String budgetId) {
    return Row(
      children: [
        _ActionPill(
          icon: PhosphorIconsRegular.trash,
          label: 'Supprimer',
          isDanger: true,
          onTap: () => _onDelete(budgetId),
        ),
        const Spacer(),
        _ActionPill(
          icon: PhosphorIconsRegular.pause,
          label: 'Désactiver',
          onTap: () => _onToggle(budgetId),
        ),
        const SizedBox(width: AppSpacing.space2),
        _ActionPill(
          icon: PhosphorIconsRegular.pencilSimple,
          label: 'Modifier',
          onTap: () => _onEdit(budgetId),
        ),
      ],
    );
  }

  // ── Skeleton / Error ──────────────────────────────────────────────────────

  Widget _buildHeroSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 12, width: 60, color: Colors.white),
            const SizedBox(height: AppSpacing.space2),
            Container(height: 28, width: 120, color: Colors.white),
            const SizedBox(height: AppSpacing.space2),
            Container(height: 12, width: 200, color: Colors.white),
            const SizedBox(height: AppSpacing.space3),
            Container(
                height: 6, width: double.infinity, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(PhosphorIconsRegular.warning,
                size: 48, color: colorScheme.error),
            const SizedBox(height: AppSpacing.space3),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const PhosphorIcon(PhosphorIconsRegular.arrowClockwise,
                  size: 20),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSkeletons() {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHighest,
          highlightColor: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 120, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(height: 10, width: 80, color: Colors.white),
                    ],
                  ),
                ),
                Container(height: 12, width: 60, color: Colors.white),
              ],
            ),
          ),
        ),
        childCount: 4,
      ),
    );
  }
}

// ── Groupement par date ────────────────────────────────────────────────────

class _TxGroup {
  const _TxGroup({required this.label, required this.transactions});
  final String label;
  final List<Transaction> transactions;
}

List<_TxGroup> _groupByDate(List<Transaction> transactions) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final yesterdayDate = todayDate.subtract(const Duration(days: 1));

  final Map<String, List<Transaction>> grouped = {};

  for (final tx in transactions) {
    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
    final String label;
    if (txDate == todayDate) {
      label = "Aujourd'hui";
    } else if (txDate == yesterdayDate) {
      label = 'Hier';
    } else {
      label = DateFormat('d MMMM', 'fr_FR').format(tx.date);
    }
    grouped.putIfAbsent(label, () => []).add(tx);
  }

  final keys = grouped.keys.toList();
  keys.sort((a, b) {
    if (a == "Aujourd'hui") return -1;
    if (b == "Aujourd'hui") return 1;
    if (a == 'Hier') return -1;
    if (b == 'Hier') return 1;
    final aFirst = grouped[a]!.first.date;
    final bFirst = grouped[b]!.first.date;
    return bFirst.compareTo(aFirst);
  });

  return keys
      .map((k) => _TxGroup(label: k, transactions: grouped[k]!))
      .toList();
}

// ── Widgets privés ─────────────────────────────────────────────────────────

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDanger ? colorScheme.error : colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.space1),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                color: color,
                fontWeight: AppTypography.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.label});
  final String label;

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
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          fontWeight: AppTypography.semiBold,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.tx,
    required this.accounts,
    required this.budgetCurrency,
  });

  final Transaction tx;
  final List<Account> accounts;
  final Currency budgetCurrency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final account = accounts.firstWhereOrNull((a) => a.id == tx.accountId);
    final currency = account?.currency ?? budgetCurrency;
    final formatted = AmountFormatter.format(tx.montant, currency: currency);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              tx.categoryId != null ? '' : '?',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.libelle,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('d MMM', 'fr_FR').format(tx.date),
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatted,
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

class _StickyTransactionHeader extends SliverPersistentHeaderDelegate {
  const _StickyTransactionHeader({required this.count});
  final int count;

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      alignment: Alignment.centerLeft,
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: Row(
        children: [
          Text(
            'Transactions',
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: colorScheme.onSurface,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTransactionHeader old) => count != old.count;
}
