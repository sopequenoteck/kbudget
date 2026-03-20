import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _timezones = [
    'Europe/Paris',
    'Europe/London',
    'Europe/Berlin',
    'Europe/Madrid',
    'Europe/Rome',
    'Europe/Brussels',
    'Africa/Casablanca',
    'Africa/Tunis',
    'Africa/Lagos',
    'Africa/Abidjan',
    'America/New_York',
    'America/Chicago',
    'America/Los_Angeles',
    'Asia/Tokyo',
    'Asia/Shanghai',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configState = ref.watch(featureConfigNotifierProvider);
    final notifier = ref.read(featureConfigNotifierProvider.notifier);

    if (configState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          Text(
            'TYPES DE NOTIFICATIONS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          ...NotificationType.values.map(
            (type) => SwitchListTile(
              title: Text(type.label),
              secondary: PhosphorIcon(type.icon, size: 22),
              value: configState.enabledNotificationTypes.contains(type),
              onChanged: (value) {
                final updated = List<NotificationType>.of(
                  configState.enabledNotificationTypes,
                );
                if (value) {
                  updated.add(type);
                } else {
                  updated.remove(type);
                }
                notifier.updateNotificationTypes(updated);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            'FUSEAU HORAIRE',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          DropdownButtonFormField<String>(
            initialValue: configState.timezone,
            decoration: const InputDecoration(
              labelText: 'Fuseau horaire',
              helperText: 'Pour le calcul des rappels J-1',
            ),
            items: _timezones
                .map(
                  (tz) => DropdownMenuItem(value: tz, child: Text(tz)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                notifier.updateTimezone(value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }
}
