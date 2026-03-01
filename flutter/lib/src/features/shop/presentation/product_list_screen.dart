import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/list_item.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/features/shop/application/product_list_state.dart';
import 'package:k_budget/src/features/shop/application/product_notifier.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(productNotifierProvider);
      if (state.items.isEmpty && !state.isLoading) {
        ref.read(productNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(productNotifierProvider.notifier).refresh();
        } on Exception {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur lors du rafraîchissement')),
            );
          }
        }
      },
      child: CustomScrollView(
        slivers: [
          ..._buildContent(state, colorScheme),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    ProductListState state,
    ColorScheme colorScheme,
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
                    'Impossible de charger les produits',
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      fontWeight: AppTypography.medium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(productNotifierProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
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
                    Icons.storefront_outlined,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    'Aucun produit',
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton.icon(
                    onPressed: () {
                      // No-op — formulaire non implémenté
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un produit'),
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
        padding: const EdgeInsets.only(top: AppSpacing.space2),
        sliver: SliverList.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final product = state.items[index];

            final listItem = ListItem(
              icon: product.icone ?? '📦',
              title: product.nom,
              value: AmountFormatter.format(product.prixVente),
              subtitle: 'Stock: ${product.stock}',
              rightSubtitle: product.stock == 0
                  ? 'Rupture'
                  : '${product.totalVendu} ventes',
              onPressed: () {
                // No-op — navigation vers détail (KKS-125)
              },
            );

            if (product.stock == 0) {
              return Opacity(
                opacity: 0.5,
                child: listItem,
              );
            }

            return listItem;
          },
        ),
      ),
      // Padding for FAB
      const SliverToBoxAdapter(
        child: SizedBox(height: 96),
      ),
    ];
  }
}
