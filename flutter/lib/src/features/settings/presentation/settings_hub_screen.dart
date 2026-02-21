import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/settings/domain/settings_section.dart';
import 'package:k_budget/src/features/settings/presentation/widgets/settings_item.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final grouped = groupedSettingsSections;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          for (final group in SettingsGroup.values) ...[
            if (group != SettingsGroup.values.first)
              const SizedBox(height: AppSpacing.space6),
            Text(
              group.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            for (final section in grouped[group]!)
              SettingsItem(
                icon: section.icon,
                iconColor: section.iconColor,
                title: section.title,
                description: section.description,
                isPlaceholder: section.isPlaceholder,
                onTap: section.isPlaceholder || section.route == null
                    ? null
                    : () => context.push(section.route!),
              ),
          ],
        ],
      ),
    );
  }
}
