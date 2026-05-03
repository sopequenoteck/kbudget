import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/settings/domain/settings_section.dart';
import 'package:k_budget/src/features/settings/presentation/widgets/settings_item.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final grouped = groupedSettingsSections;
    final userAsync = ref.watch(userProfileNotifierProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;

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
            // Tuile Utilisateurs — visible uniquement pour les admins
            if (group == SettingsGroup.management && isAdmin)
              SettingsItem(
                icon: PhosphorIconsRegular.users,
                iconColor: Colors.indigo,
                title: 'Utilisateurs',
                description: 'Invitations et gestion des comptes',
                onTap: () => context.push(RouteNames.adminUsers),
              ),
          ],
        ],
      ),
    );
  }
}
