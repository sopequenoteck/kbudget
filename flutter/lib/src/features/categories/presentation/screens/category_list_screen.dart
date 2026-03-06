import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_list_skeleton.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_list_tile.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() =>
      _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(categoryNotifierProvider);
      if (state.items.isEmpty && !state.isLoading) {
        ref.read(categoryNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 24),
            onPressed: () => context.push(
              '${RouteNames.settings}/${RouteNames.settingsCategories}/${RouteNames.settingsCategoriesNew}',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(categoryNotifierProvider.notifier).refresh();
          } on Exception {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.errorGeneric)),
              );
            }
          }
        },
        child: CustomScrollView(
          slivers: _buildContent(state, l10n),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    ListState<Category> state,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final userCategories =
        state.items.where((c) => !c.isSystem).toList();

    // Loading
    if (state.isLoading && state.items.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: CategoryListSkeleton(),
        ),
      ];
    }

    // Error
    if (state.error != null && state.items.isEmpty) {
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
                    l10n.categoryErrorLoad,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      fontWeight: AppTypography.medium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(categoryNotifierProvider.notifier).refresh(),
                    icon: const PhosphorIcon(PhosphorIconsRegular.arrowClockwise, size: 20),
                    label: Text(l10n.categoriesRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Empty
    if (userCategories.isEmpty) {
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
                    PhosphorIconsRegular.tag,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.categoriesEmpty,
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
      SliverList.builder(
        itemCount: userCategories.length,
        itemBuilder: (context, index) {
          final category = userCategories[index];
          return CategoryListTile(
            category: category,
            onTap: () => context.push(
              '${RouteNames.settings}/${RouteNames.settingsCategories}/${category.id}',
              extra: category,
            ),
          );
        },
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.space12 * 2),
      ),
    ];
  }
}
