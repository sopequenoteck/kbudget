import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/settings/application/theme_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          // Theme section
          Text(
            'Apparence',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Card(
            child: SwitchListTile(
              title: const Text('Thème sombre'),
              subtitle: Text(
                themeMode == ThemeMode.dark
                    ? 'Thème sombre activé'
                    : 'Thème clair activé',
              ),
              value: themeMode == ThemeMode.dark,
              onChanged: (_) {
                ref.read(themeNotifierProvider.notifier).toggleTheme();
              },
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),

          // Data mode section
          Text(
            'Données',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Mode de données'),
              subtitle: const Text('Changer le mode de données'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Changement de mode (à venir)'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.space6),

          // Security section
          Text(
            'Sécurité',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Verrouillage'),
              subtitle: const Text('Configurer la biométrie ou le PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuration du verrouillage (à venir)'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
