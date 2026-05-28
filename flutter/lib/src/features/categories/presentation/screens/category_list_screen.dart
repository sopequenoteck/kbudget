import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/empty_state_widget.dart';
import 'package:k_budget/src/common_widgets/page_header.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          '${RouteNames.settings}/${RouteNames.settingsCategories}/${RouteNames.settingsCategoriesNew}',
        ),
        child: const PhosphorIcon(PhosphorIconsRegular.plus, size: 24),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: PageHeader(
                title: l10n.categoriesTitle,
                onBack: () => context.pop(),
                icon: const PhosphorIcon(PhosphorIconsRegular.tag, size: 16),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
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
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    ListState<Category> state,
    AppLocalizations l10n,
  ) {
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
          child: EmptyStateWidget(
            icon: PhosphorIconsRegular.warning,
            message: l10n.categoryErrorLoad,
            ctaLabel: l10n.categoriesRetry,
            onCtaTap: () => ref.read(categoryNotifierProvider.notifier).refresh(),
          ),
        ),
      ];
    }

    // Empty
    if (userCategories.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: PhosphorIconsRegular.tag,
            message: l10n.categoriesEmpty,
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
