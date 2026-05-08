import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_list_state.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:k_budget/src/utils/next_renewal_date.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class SubscriptionListScreen extends ConsumerStatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  ConsumerState<SubscriptionListScreen> createState() =>
      _SubscriptionListScreenState();
}

class _SubscriptionListScreenState
    extends ConsumerState<SubscriptionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subState = ref.read(subscriptionNotifierProvider);
      if (subState.items.isEmpty && !subState.isLoading) {
        ref.read(subscriptionNotifierProvider.notifier).loadItems();
      }

      final catState = ref.read(categoryNotifierProvider);
      if (catState.items.isEmpty && !catState.isLoading) {
        ref.read(categoryNotifierProvider.notifier).loadItems();
      }

      final accState = ref.read(accountNotifierProvider);
      if (accState.items.isEmpty && !accState.isLoading) {
        ref.read(accountNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionNotifierProvider);
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
          await ref.read(subscriptionNotifierProvider.notifier).refresh();
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
            exchangeRates: exchangeRateState.items,
            primaryCurrency: primaryCurrency,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    SubscriptionListState state,
    Map<String, Category> categoryMap,
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    List<ExchangeRate> exchangeRates = const [],
    Currency? primaryCurrency,
  }) {
    // Loading
    if (state.isLoading) {
      return [
        SliverToBoxAdapter(
          child: _SubscriptionSummaryCard(
            monthlyTotals: state.monthlyTotals,
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
                    onPressed: () => ref
                        .read(subscriptionNotifierProvider.notifier)
                        .refresh(),
                    icon: const PhosphorIcon(PhosphorIconsRegular.arrowClockwise, size: 20),
                    label: Text(l10n.subscriptionsRetry),
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
      final emptyMessage = switch (state.activeFilter) {
        SubscriptionStatusFilter.all => l10n.subscriptionsEmpty,
        SubscriptionStatusFilter.actif => l10n.subscriptionsEmptyActifs,
        SubscriptionStatusFilter.inactif => l10n.subscriptionsEmptyInactifs,
      };

      return [
        SliverToBoxAdapter(
          child: _SubscriptionSummaryCard(
            monthlyTotals: state.monthlyTotals,
            isLoading: false,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            // TODO KKS-240 : remplacer par groupement + sections (DESIGN.md anti-pattern segmented control)
            child: Wrap(
              spacing: AppSpacing.space2,
              children: [
                ChoiceChip(
                  label: Text(l10n.subscriptionsFilterAll),
                  selected:
                      state.activeFilter == SubscriptionStatusFilter.all,
                  onSelected: (_) => ref
                      .read(subscriptionNotifierProvider.notifier)
                      .setFilter(SubscriptionStatusFilter.all),
                ),
                ChoiceChip(
                  label: Text(l10n.subscriptionsFilterActifs),
                  selected:
                      state.activeFilter == SubscriptionStatusFilter.actif,
                  onSelected: (_) => ref
                      .read(subscriptionNotifierProvider.notifier)
                      .setFilter(SubscriptionStatusFilter.actif),
                ),
                ChoiceChip(
                  label: Text(l10n.subscriptionsFilterInactifs),
                  selected:
                      state.activeFilter == SubscriptionStatusFilter.inactif,
                  onSelected: (_) => ref
                      .read(subscriptionNotifierProvider.notifier)
                      .setFilter(SubscriptionStatusFilter.inactif),
                ),
              ],
            ),
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
                    PhosphorIconsRegular.arrowsClockwise,
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
        child: _SubscriptionSummaryCard(
          monthlyTotals: state.monthlyTotals,
          isLoading: false,
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space2,
          ),
          // TODO KKS-240 : remplacer par groupement + sections (DESIGN.md anti-pattern segmented control)
          child: Wrap(
            spacing: AppSpacing.space2,
            children: [
              ChoiceChip(
                label: Text(l10n.subscriptionsFilterAll),
                selected:
                    state.activeFilter == SubscriptionStatusFilter.all,
                onSelected: (_) => ref
                    .read(subscriptionNotifierProvider.notifier)
                    .setFilter(SubscriptionStatusFilter.all),
              ),
              ChoiceChip(
                label: Text(l10n.subscriptionsFilterActifs),
                selected:
                    state.activeFilter == SubscriptionStatusFilter.actif,
                onSelected: (_) => ref
                    .read(subscriptionNotifierProvider.notifier)
                    .setFilter(SubscriptionStatusFilter.actif),
              ),
              ChoiceChip(
                label: Text(l10n.subscriptionsFilterInactifs),
                selected:
                    state.activeFilter == SubscriptionStatusFilter.inactif,
                onSelected: (_) => ref
                    .read(subscriptionNotifierProvider.notifier)
                    .setFilter(SubscriptionStatusFilter.inactif),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.only(top: AppSpacing.space2),
        sliver: SliverList.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final sub = state.items[index];
            final cat = sub.categoryId != null
                ? categoryMap[sub.categoryId]
                : null;

            final frequencySuffix = sub.frequence == Frequency.mensuel
                ? l10n.subscriptionFrequencyMensuel
                : l10n.subscriptionFrequencyAnnuel;

            final formattedAmount = AmountFormatter.format(
              sub.montant,
              currency: sub.currency,
            );

            final renewal = nextRenewalDate(sub.dateDebut, sub.frequence);
            final renewalLabel =
                l10n.subscriptionNextRenewal(dateFormat.format(renewal));

            // Sous-texte montant converti si devise étrangère
            String? convertedSubtitle;
            if (primaryCurrency != null &&
                sub.currency != primaryCurrency &&
                exchangeRates.isNotEmpty) {
              final converted = CurrencyConverter.convert(
                amount: sub.montant,
                fromCurrency: sub.currency,
                toCurrency: primaryCurrency,
                rates: exchangeRates,
              );
              if (converted != null) {
                convertedSubtitle =
                    '~ ${AmountFormatter.format(converted, currency: primaryCurrency)}';
              }
            }

            return ListItem(
              icon: cat?.icone ?? '📅',
              iconBackgroundColor: cat != null
                  ? parseHexColor(cat.couleur)
                  : colorScheme.surfaceContainerHighest,
              title: sub.nom,
              subtitle: renewalLabel,
              value: '$formattedAmount$frequencySuffix',
              rightSubtitle: convertedSubtitle ??
                  (sub.actif ? null : l10n.subscriptionBadgeInactif),
              onPressed: () {
                context.push(
                  '${RouteNames.subscriptions}/${sub.id}',
                  extra: sub,
                );
              },
            );
          },
        ),
      ),
      // Padding for FAB
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    ];
  }
}

class _SubscriptionSummaryCard extends StatelessWidget {
  const _SubscriptionSummaryCard({
    required this.monthlyTotals,
    required this.isLoading,
  });

  final Map<Currency, double> monthlyTotals;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _SummaryCardSkeleton();
    if (monthlyTotals.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final entries = monthlyTotals.entries.toList();

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
            Text(
              l10n.subscriptionsTotalMensuel,
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            ...entries.map(
              (e) => Text(
                AmountFormatter.format(e.value, currency: e.key),
                style: TextStyle(
                  fontSize: AppTypography.sizeLg,
                  fontWeight: AppTypography.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
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
          height: 64,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
