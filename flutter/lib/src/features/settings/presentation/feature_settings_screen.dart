import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';

class FeatureSettingsScreen extends ConsumerWidget {
  const FeatureSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final featureState = ref.watch(featureConfigNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fonctionnalités')),
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
                child: Icon(
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
        ],
      ),
    );
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
