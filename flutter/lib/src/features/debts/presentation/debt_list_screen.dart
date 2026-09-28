// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/common_widgets/section_header_sticky.dart';
import 'package:k_budget/src/constants/app_colors.dart';
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
import 'package:k_budget/src/features/debts/presentation/widgets/debt_hero_widget.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

    final kEnCours = state.items.where((d) => !d.rembourse).length;

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(debtNotifierProvider.notifier).refresh();
        } on Exception {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorsClientGeneric)),
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
            kEnCours: kEnCours,
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
    int kEnCours = 0,
  }) {
    // Loading
    if (state.isLoading) {
      return [
        SliverToBoxAdapter(
          child: DebtHeroWidget(
            summary: state.summary,
            primaryCurrency: primaryCurrency,
            enCours: kEnCours,
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
                    l10n.errorsClientGeneric,
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
                    label: Text(l10n.commonActionRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Empty
    if (state.items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: DebtHeroWidget(
            summary: state.summary,
            primaryCurrency: primaryCurrency,
            enCours: 0,
            isLoading: false,
          ),
        ),
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
                    l10n.debtsEmptyTitle,
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

    // Data — groupement temporel
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final groups = _groupByDueDate(state.items, todayDate);
    final themeExt = theme.extension<AppThemeExtension>();
    final dateFormat = DateFormat('d MMMM', ref.watch(intlLocaleProvider));

    final widgets = <Widget>[
      SliverToBoxAdapter(
        child: DebtHeroWidget(
          summary: state.summary,
          primaryCurrency: primaryCurrency,
          enCours: kEnCours,
          isLoading: false,
        ),
      ),
      SectionHeaderSticky(
        title: '${l10n.commonNavDebts} · '
            '${l10n.debtsSummaryOutstandingCount(kEnCours)}',
      ),
    ];

    for (final entry in groups.entries) {
      final bucket = entry.key;
      final bucketDebts = entry.value;

      // Couleur du date-label
      final Color labelColor;
      if (bucket == _DueBucket.overdue) {
        labelColor = themeExt?.expenseColor ?? colorScheme.error;
      } else if (bucket == _DueBucket.today) {
        labelColor = AppColors.amber500;
      } else {
        labelColor = colorScheme.onSurfaceVariant;
      }

      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            child: Text(
              _bucketLabel(bucket, l10n),
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                color: labelColor,
              ),
            ),
          ),
        ),
      );

      widgets.add(
        SliverList.builder(
          itemCount: bucketDebts.length,
          itemBuilder: (context, index) => _buildDebtItem(
            bucketDebts[index],
            categoryMap,
            colorScheme,
            dateFormat,
            l10n,
            themeExt,
            exchangeRates: exchangeRates,
            primaryCurrency: primaryCurrency,
          ),
        ),
      );
    }

    widgets.add(
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    );

    return widgets;
  }

  Map<_DueBucket, List<Debt>> _groupByDueDate(
    List<Debt> items,
    DateTime today,
  ) {
    final raw = <_DueBucket, List<Debt>>{};
    for (final debt in items) {
      final _DueBucket bucket;
      if (debt.rembourse) {
        bucket = _DueBucket.repaid;
      } else if (debt.dueDate == null) {
        bucket = _DueBucket.noDueDate;
      } else {
        final dueDay = DateTime(
          debt.dueDate!.year,
          debt.dueDate!.month,
          debt.dueDate!.day,
        );
        if (dueDay.isBefore(today)) {
          bucket = _DueBucket.overdue;
        } else if (dueDay == today) {
          bucket = _DueBucket.today;
        } else if (!dueDay.isAfter(today.add(const Duration(days: 7)))) {
          bucket = _DueBucket.thisWeek;
        } else if (dueDay.year == today.year && dueDay.month == today.month) {
          bucket = _DueBucket.thisMonth;
        } else {
          bucket = _DueBucket.later;
        }
      }
      raw.putIfAbsent(bucket, () => []).add(debt);
    }

    // Tri dans chaque bucket : dueDate ASC (null après), puis date DESC
    for (final list in raw.values) {
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) {
          return b.date.compareTo(a.date);
        }
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        final dueCmp = a.dueDate!.compareTo(b.dueDate!);
        if (dueCmp != 0) return dueCmp;
        return b.date.compareTo(a.date);
      });
    }

    return {
      for (final bucket in _DueBucket.values)
        if (raw.containsKey(bucket)) bucket: raw[bucket]!,
    };
  }

  String _bucketLabel(_DueBucket bucket, AppLocalizations l10n) =>
      switch (bucket) {
        _DueBucket.overdue => l10n.debtsListOverdue,
        _DueBucket.today => l10n.commonValueToday,
        _DueBucket.thisWeek => l10n.debtsListThisWeek,
        _DueBucket.thisMonth => l10n.debtsListThisMonth,
        _DueBucket.later => l10n.debtsListLater,
        _DueBucket.noDueDate => l10n.debtsListNoDueDate,
        _DueBucket.repaid => l10n.debtsListRepaid,
      };

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
      locale: ref.watch(intlLocaleProvider));

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
        final formattedConverted = AmountFormatter.format(
          converted,
          currency: primaryCurrency,
          locale: ref.watch(intlLocaleProvider),
        );
        convertedSubtitle = '~ $formattedConverted';
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
          convertedSubtitle ?? (debt.rembourse ? l10n.debtsValueRepaid : null),
      onPressed: () {
        context.push('/debts/${debt.id}', extra: debt);
      },
    );
  }
}

/// Groupes de la liste, dans leur ordre d'affichage.
enum _DueBucket {
  overdue,
  today,
  thisWeek,
  thisMonth,
  later,
  noDueDate,
  repaid,
}
