import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/settings/application/text_scale_notifier.dart';
import 'package:k_budget/src/features/settings/application/theme_notifier.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final textScale = ref.watch(textScaleNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apparence')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          // --- Theme section ---
          Text(
            'Thème',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _ThemeTile(
                  icon: Icons.light_mode,
                  label: 'Clair',
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeNotifierProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _ThemeTile(
                  icon: Icons.dark_mode,
                  label: 'Sombre',
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeNotifierProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),

          // --- Text size section ---
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Taille du texte',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              for (final scale in TextScale.values) ...[
                if (scale != TextScale.values.first)
                  const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: _TextScaleTile(
                    scale: scale,
                    isSelected: textScale == scale,
                    onTap: () => ref
                        .read(textScaleNotifierProvider.notifier)
                        .setTextScale(scale),
                  ),
                ),
              ],
            ],
          ),

          // --- Preview ---
          const SizedBox(height: AppSpacing.space4),
          _TextPreview(textScale: textScale),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space4,
          horizontal: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.space1),
              Icon(
                Icons.check_circle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextScaleTile extends StatelessWidget {
  final TextScale scale;
  final bool isSelected;
  final VoidCallback onTap;

  const _TextScaleTile({
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space4,
          horizontal: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          children: [
            Text(
              'Aa',
              style: TextStyle(
                fontSize: 20 * scale.scaleFactor,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              scale.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.space1),
              Icon(
                Icons.check_circle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  final TextScale textScale;

  const _TextPreview({required this.textScale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Text(
          'Voici un aperçu de la taille du texte choisie.',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize:
                (theme.textTheme.bodyLarge?.fontSize ?? 16) *
                textScale.scaleFactor,
          ),
        ),
      ),
    );
  }
}
