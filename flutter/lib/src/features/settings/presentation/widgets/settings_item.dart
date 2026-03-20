import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsItem extends StatelessWidget {
  final PhosphorIconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.isPlaceholder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          // Icon circle
          ExcludeSemantics(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
              child: PhosphorIcon(icon, color: iconColor, size: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          // Title + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          // Trailing: chevron or badge
          if (isPlaceholder)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'À venir',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              color: colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (isPlaceholder) {
      return Semantics(
        label: '$title, $description, À venir',
        child: Opacity(
          opacity: 0.5,
          child: content,
        ),
      );
    }

    return Semantics(
      button: true,
      label: '$title, $description',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
      ),
    );
  }
}
