import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/utils/image_utils.dart';
import 'package:k_budget/src/domain/enums/modal_type.dart';
import 'package:k_budget/src/domain/enums/transaction_type.dart';
import 'package:k_budget/src/domain/models/product.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/features/shop/application/product_notifier.dart';
import 'package:k_budget/src/features/shop/presentation/widgets/restock_dialog.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    required this.productId,
    this.initialProduct,
    super.key,
  });

  final String productId;
  final Product? initialProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productNotifierProvider);
    final product =
        state.items.where((e) => e.id == productId).firstOrNull ??
            initialProduct;
    final isMutating = state.mutatingIds.contains(productId);

    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(product?.nom ?? 'Produit'),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple, size: 20),
            onPressed: product == null || isMutating
                ? null
                : () {
                    ref
                        .read(modalNotifierProvider.notifier)
                        .open(ModalType.product, entity: product);
                  },
          ),
        ],
      ),
      body: product == null
          ? const Center(child: Text('Produit introuvable'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, product),
                  const SizedBox(height: AppSpacing.space6),
                  _buildStats(context, product, colorScheme),
                  const SizedBox(height: AppSpacing.space6),
                  _buildActions(context, ref, product, colorScheme, isMutating),
                  const SizedBox(height: AppSpacing.space6),
                  _buildHistory(context, ref, product.id, colorScheme, themeExt),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = product.imageUrl;
    final isBase64 = ImageUtils.isBase64DataUri(imageUrl);
    final isLocalFile =
        imageUrl != null && !isBase64 && File(imageUrl).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isBase64)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.memory(
              ImageUtils.base64DataUriToBytes(imageUrl!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else if (isLocalFile)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.file(
              File(imageUrl),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.amber100,
              borderRadius: BorderRadius.circular(AppRadius.round),
            ),
            child: Center(
              child: Text(
                product.icone ?? '📦',
                style: const TextStyle(fontSize: AppTypography.size3xl),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          product.nom,
          style: TextStyle(
            fontSize: AppTypography.size2xl,
            fontWeight: AppTypography.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (product.description != null && product.description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            product.description!,
            style: TextStyle(
              fontSize: AppTypography.sizeMd,
              fontWeight: AppTypography.regular,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats(
    BuildContext context,
    Product product,
    ColorScheme colorScheme,
  ) {
    final marge = product.prixAchat == 0
        ? product.prixVente
        : product.prixVente - product.prixAchat;
    final margeTotal = (product.prixVente - product.prixAchat) * product.totalVendu;
    final chiffreAffaires = product.prixVente * product.totalVendu;

    final stats = [
      ('Prix d\'achat', AmountFormatter.format(product.prixAchat)),
      ('Prix de vente', AmountFormatter.format(product.prixVente)),
      ('Marge unitaire', AmountFormatter.format(marge)),
      ('Stock', '${product.stock}'),
      ('Total vendu', '${product.totalVendu}'),
      ('Chiffre d\'affaires', AmountFormatter.format(chiffreAffaires)),
      ('Marge totale', AmountFormatter.format(margeTotal)),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - AppSpacing.space4 * 2 - AppSpacing.space3) / 2;

    return Wrap(
      spacing: AppSpacing.space3,
      runSpacing: AppSpacing.space3,
      children: stats.map((stat) {
        final (label, value) = stat;
        return SizedBox(
          width: cardWidth,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    fontWeight: AppTypography.regular,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTypography.sizeMd,
                    fontWeight: AppTypography.semiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    Product product,
    ColorScheme colorScheme,
    bool isMutating,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: AppSpacing.space3,
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: isMutating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const PhosphorIcon(PhosphorIconsRegular.tag, size: 20),
                label: const Text('Vendre'),
                onPressed: product.stock == 0 || !product.actif || isMutating
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(productNotifierProvider.notifier)
                              .sellProduct(product.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vente enregistrée'),
                              ),
                            );
                          }
                        } on Exception {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Erreur lors de la vente'),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
              ),
            ),
            Expanded(
              child: OutlinedButton.icon(
                icon: const PhosphorIcon(PhosphorIconsRegular.shoppingCartSimple, size: 20),
                label: const Text('Ajouter stock'),
                onPressed: !product.actif || isMutating
                    ? null
                    : () async {
                        final quantity = await showDialog<int>(
                          context: context,
                          builder: (_) => const RestockDialog(),
                        );
                        if (quantity != null && context.mounted) {
                          try {
                            await ref
                                .read(productNotifierProvider.notifier)
                                .restockProduct(product.id, quantity);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Stock ajouté: +$quantity'),
                                ),
                              );
                            }
                          } on Exception {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Erreur lors du réapprovisionnement',
                                  ),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        }
                      },
              ),
            ),
          ],
        ),
        if (!product.actif) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Produit inactif',
            style: TextStyle(
              fontSize: AppTypography.sizeXs,
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistory(
    BuildContext context,
    WidgetRef ref,
    String id,
    ColorScheme colorScheme,
    AppThemeExtension themeExt,
  ) {
    final salesAsync = ref.watch(productSalesProvider(id));
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique',
          style: TextStyle(
            fontSize: AppTypography.sizeLg,
            fontWeight: AppTypography.semiBold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        salesAsync.when(
          loading: () => _buildHistorySkeleton(),
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Impossible de charger l\'historique',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              OutlinedButton.icon(
                icon: const PhosphorIcon(PhosphorIconsRegular.arrowClockwise, size: 20),
                label: const Text('Réessayer'),
                onPressed: () => ref.invalidate(productSalesProvider(id)),
              ),
            ],
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Text(
                'Aucune transaction',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: transactions
                  .map(
                    (t) => _buildTransactionItem(
                      context,
                      t,
                      colorScheme,
                      themeExt,
                      dateFormatter,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Transaction t,
    ColorScheme colorScheme,
    AppThemeExtension themeExt,
    DateFormat dateFormatter,
  ) {
    final isRecette = t.type == TransactionType.recette;
    final iconColor =
        isRecette ? themeExt.incomeColor : themeExt.expenseColor;
    final iconBg = iconColor.withValues(alpha: 0.1);
    final amountColor =
        AmountFormatter.amountColor(t.type.name, themeExt) ??
            colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        spacing: AppSpacing.space3,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.round),
            ),
            child: PhosphorIcon(
              isRecette ? PhosphorIconsRegular.trendUp : PhosphorIconsRegular.trendDown,
              color: iconColor,
              size: 18,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.libelle,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateFormatter.format(t.date),
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AmountFormatter.format(t.montant, type: t.type.name),
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space3),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Row(
              spacing: AppSpacing.space3,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.space1,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 14,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
