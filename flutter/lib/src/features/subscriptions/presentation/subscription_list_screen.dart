import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final categoryMap = <String, Category>{
      for (final c in catState.items) c.id: c,
    };

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
          ..._buildContent(state, categoryMap, colorScheme, l10n),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    ListState<Subscription> state,
    Map<String, Category> categoryMap,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    // Loading
    if (state.isLoading) {
      return [
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
                    onPressed: () => ref
                        .read(subscriptionNotifierProvider.notifier)
                        .refresh(),
                    icon: const Icon(Icons.refresh),
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
                    Icons.repeat_outlined,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.subscriptionsEmpty,
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
    return [
      SliverPadding(
        padding: const EdgeInsets.only(top: AppSpacing.space4),
        sliver: SliverList.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final sub = state.items[index];
            final cat = sub.categoryId != null
                ? categoryMap[sub.categoryId]
                : null;

            final frequencyLabel =
                sub.frequence == Frequency.mensuel ? 'Mensuel' : 'Annuel';

            return ListItem(
              icon: cat?.icone ?? '📅',
              iconBackgroundColor:
                  cat != null ? parseHexColor(cat.couleur) : null,
              title: sub.nom,
              subtitle: frequencyLabel,
              value: AmountFormatter.format(
                sub.montant,
                currency: sub.currency,
              ),
              rightSubtitle: sub.actif ? null : 'Inactif',
              onPressed: () {
                ref.read(modalNotifierProvider.notifier).open(
                      ModalType.subscription,
                      entity: sub,
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
