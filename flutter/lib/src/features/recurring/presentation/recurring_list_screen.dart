import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/features/recurring/presentation/widgets/recurring_list_item.dart';
import 'package:k_budget/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

class RecurringListScreen extends ConsumerStatefulWidget {
  const RecurringListScreen({super.key});

  @override
  ConsumerState<RecurringListScreen> createState() =>
      _RecurringListScreenState();
}

class _RecurringListScreenState extends ConsumerState<RecurringListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(recurringListNotifierProvider);
      if (s.items.isEmpty && !s.isLoading) {
        ref.read(recurringListNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringListNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringTitle),
      ),
      body: _buildBody(context, state, l10n, colorScheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ListState<RecurringTransaction> state,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    // Loading
    if (state.isLoading && state.items.isEmpty) {
      return const RecurringListSkeleton();
    }

    // Error
    if (state.error != null && state.items.isEmpty) {
      return Center(
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space4),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(recurringListNotifierProvider.notifier).loadItems(),
                icon: const PhosphorIcon(
                  PhosphorIconsRegular.arrowClockwise,
                  size: 20,
                ),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    // Empty
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.repeat,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                l10n.recurringEmpty,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // List
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(recurringListNotifierProvider.notifier).loadItems(),
      child: ListView.builder(
        itemCount: state.items.length,
        padding: const EdgeInsets.only(bottom: AppSpacing.space12 * 2),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return RecurringListItem(
            item: item,
            onValidate: () => _handleValidate(context, item.id, l10n),
            onSkip: () => _handleSkip(context, item.id, l10n),
            onDeactivate: () =>
                _showDeactivateConfirm(context, item.id, l10n),
          );
        },
      ),
    );
  }

  Future<void> _handleValidate(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    await ref.read(recurringListNotifierProvider.notifier).validate(id);

    if (!context.mounted) return;
    final error = ref.read(recurringListNotifierProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringValidateSuccess)),
      );
    }
  }

  Future<void> _handleSkip(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    await ref.read(recurringListNotifierProvider.notifier).skip(id);

    if (!context.mounted) return;
    final error = ref.read(recurringListNotifierProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringSkipSuccess)),
      );
    }
  }

  void _showDeactivateConfirm(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recurringDeactivate),
        content: Text(l10n.recurringDeactivateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _handleDeactivate(context, id, l10n);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeactivate(
    BuildContext context,
    String id,
    AppLocalizations l10n,
  ) async {
    await ref.read(recurringListNotifierProvider.notifier).deactivate(id);

    if (!context.mounted) return;
    final error = ref.read(recurringListNotifierProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recurringDeactivateSuccess)),
      );
    }
  }
}
