import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FeatureSettingsScreen extends ConsumerStatefulWidget {
  const FeatureSettingsScreen({super.key});

  @override
  ConsumerState<FeatureSettingsScreen> createState() =>
      _FeatureSettingsScreenState();
}

class _FeatureSettingsScreenState extends ConsumerState<FeatureSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featureState = ref.watch(featureConfigNotifierProvider);

    ref.listen(featureConfigNotifierProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final enabledOrdered = featureState.navOrder
        .where((f) => featureState.enabledFeatures.contains(f))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Fonctionnalités & Navigation')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          Text(
            'Modules',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          ...Feature.values.map((feature) {
            final isEnabled = featureState.enabledFeatures.contains(feature);
            return SwitchListTile(
              secondary: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: PhosphorIcon(
                  feature.icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: Text(feature.label),
              subtitle: Text(feature.description),
              value: isEnabled,
              onChanged: (_) => _onToggle(context, ref, feature, isEnabled),
            );
          }),
          const SizedBox(height: AppSpacing.space6),
          Text(
            'Navigation',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: PhosphorIcon(
                PhosphorIconsRegular.house,
                color: theme.colorScheme.outline,
                size: 20,
              ),
            ),
            title: Text(
              'Accueil',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            trailing: PhosphorIcon(
              PhosphorIconsRegular.lock,
              color: theme.colorScheme.outline,
              size: 18,
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: PhosphorIcon(
                PhosphorIconsRegular.receipt,
                color: theme.colorScheme.outline,
                size: 20,
              ),
            ),
            title: Text(
              'Transactions',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            trailing: PhosphorIcon(
              PhosphorIconsRegular.lock,
              color: theme.colorScheme.outline,
              size: 18,
            ),
          ),
          if (enabledOrdered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              child: Text(
                'Activez des fonctionnalités pour personnaliser la navigation',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                );
              },
              itemCount: enabledOrdered.length,
              itemBuilder: (context, index) {
                final feature = enabledOrdered[index];
                return ListTile(
                  key: ValueKey(feature),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: PhosphorIcon(
                      feature.icon,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  title: Text(feature.label),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: PhosphorIcon(
                      PhosphorIconsRegular.dotsSixVertical,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) =>
                  _onReorder(oldIndex, newIndex, ref, featureState),
            ),
          const SizedBox(height: AppSpacing.space6),
          _BottomNavPreview(orderedEnabledFeatures: enabledOrdered),
        ],
      ),
    );
  }

  void _onReorder(
    int oldIndex,
    int newIndex,
    WidgetRef ref,
    FeatureConfigState state,
  ) {
    final enabledOrdered = state.navOrder
        .where((f) => state.enabledFeatures.contains(f))
        .toList();
    if (oldIndex < newIndex) newIndex -= 1;
    final item = enabledOrdered.removeAt(oldIndex);
    enabledOrdered.insert(newIndex, item);

    final newNavOrder = <Feature>[];
    var enabledIdx = 0;
    for (final f in state.navOrder) {
      if (state.enabledFeatures.contains(f)) {
        newNavOrder.add(enabledOrdered[enabledIdx++]);
      } else {
        newNavOrder.add(f);
      }
    }
    ref
        .read(featureConfigNotifierProvider.notifier)
        .reorderNavigation(newNavOrder);
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    Feature feature,
    bool isCurrentlyEnabled,
  ) async {
    if (isCurrentlyEnabled && _hasExistingData(ref, feature)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Désactiver ${feature.label} ?'),
          content: const Text(
            'Vos données seront masquées mais pas supprimées. '
            'Vous pourrez les retrouver en réactivant cette fonctionnalité.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Désactiver'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref
        .read(featureConfigNotifierProvider.notifier)
        .toggleFeature(feature);
  }

  bool _hasExistingData(WidgetRef ref, Feature feature) {
    return switch (feature) {
      Feature.subscriptions =>
        ref.read(subscriptionNotifierProvider).items.isNotEmpty,
      Feature.debts => ref.read(debtNotifierProvider).items.isNotEmpty,
      Feature.shop => false,
    };
  }
}

class _BottomNavPreview extends StatelessWidget {
  const _BottomNavPreview({required this.orderedEnabledFeatures});

  final List<Feature> orderedEnabledFeatures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <({PhosphorIconData icon, String label})>[
      (icon: PhosphorIconsRegular.house, label: 'Accueil'),
      (icon: PhosphorIconsRegular.receipt, label: 'Transactions'),
      ...orderedEnabledFeatures.map((f) => (icon: f.outlinedIcon, label: f.label)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  item.icon,
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
