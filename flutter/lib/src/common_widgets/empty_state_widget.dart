import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

/// Widget d'état vide unifié pour les écrans liste de l'application.
///
/// Affiche une icône optionnelle centrée à 50% d'opacité, un message principal,
/// un hint secondaire optionnel, et un CTA text-link amber optionnel.
///
/// Aligné sur le composant Angular `<app-empty-state>` :
/// - Paramètres `message` / `hint` (pas `title` / `subtitle`)
/// - CTA = text-link souligné (pas un bouton plein)
///
/// Exemple d'usage :
/// ```dart
/// EmptyStateWidget(
///   icon: PhosphorIconsRegular.folder,
///   message: 'Aucune transaction',
///   hint: 'Tapez + pour ajouter',
///   ctaLabel: '+ Créer',
///   onCtaTap: () => context.push('/transactions/new'),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  /// Crée un état vide avec icône, message, hint et CTA optionnels.
  const EmptyStateWidget({
    super.key,
    this.icon,
    required this.message,
    this.hint,
    this.ctaLabel,
    this.onCtaTap,
  });

  /// Icône Phosphor optionnelle, rendue en 48px à 50% d'opacité.
  final IconData? icon;

  /// Message principal de l'état vide (ex : « Aucune transaction »).
  final String message;

  /// Hint secondaire optionnel en style `bodySmall` (ex : « Tapez + pour ajouter »).
  final String? hint;

  /// Label du CTA text-link optionnel (ex : « + Créer »).
  ///
  /// Doit être passé conjointement à [onCtaTap].
  final String? ctaLabel;

  /// Callback déclenché au tap sur le CTA text-link.
  ///
  /// Doit être passé conjointement à [ctaLabel].
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space10,
          horizontal: AppSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                hint!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: onCtaTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  ctaLabel!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
