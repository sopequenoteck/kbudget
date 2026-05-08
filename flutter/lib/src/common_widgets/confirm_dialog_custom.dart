import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Variantes du bouton de confirmation.
enum ConfirmVariant {
  /// Variante par défaut — bouton confirmer en `colorScheme.primary` (amber),
  /// icône `PhosphorIcons.check`.
  primary,

  /// Variante danger — bouton confirmer en `colorScheme.error` (rouge),
  /// icône `PhosphorIcons.trash`.
  danger,
}

/// Dialog de confirmation modal centré avec icône métier, titre, message
/// optionnel et variantes default / danger.
///
/// Utilise `showDialog` Material en interne avec un child custom conforme
/// au DESIGN.md (pas `AlertDialog` standard).
///
/// Retourne :
/// - `true` si l'utilisateur tape sur le bouton confirmer
/// - `false` si l'utilisateur tape sur le bouton annuler
/// - `null` si l'utilisateur tape hors du dialog (barrier dismiss)
///   ou utilise le back button Android
///
/// Exemple d'usage :
/// ```dart
/// final confirmed = await ConfirmDialogCustom.show(
///   context: context,
///   icon: PhosphorIconsRegular.trash,
///   title: 'Supprimer Courses 42 €',
///   message: 'Cette action est irréversible.',
///   variant: ConfirmVariant.danger,
/// ) ?? false;
/// ```
class ConfirmDialogCustom {
  ConfirmDialogCustom._();

  /// Affiche un dialog modal de confirmation.
  ///
  /// [context] — contexte parent pour `showDialog`.
  /// [icon] — icône métier optionnelle 20px affichée dans le header.
  /// [title] — titre concret (ex : `'Supprimer Courses 42 €'`).
  /// [message] — description optionnelle (ex : `'Cette action est irréversible.'`).
  /// [confirmLabel] — label du bouton de confirmation (défaut : `'Confirmer'`).
  /// [cancelLabel] — label du bouton d'annulation (défaut : `'Annuler'`).
  /// [variant] — style du bouton confirmer : [ConfirmVariant.primary] (amber)
  ///   ou [ConfirmVariant.danger] (rouge avec icône Trash).
  static Future<bool?> show({
    required BuildContext context,
    IconData? icon,
    required String title,
    String? message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    ConfirmVariant variant = ConfirmVariant.primary,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        child: _ConfirmDialogContent(
          icon: icon,
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          variant: variant,
        ),
      ),
    );
  }
}

class _ConfirmDialogContent extends StatelessWidget {
  const _ConfirmDialogContent({
    this.icon,
    required this.title,
    this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.variant,
  });

  final IconData? icon;
  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmColor = variant == ConfirmVariant.danger
        ? colorScheme.error
        : colorScheme.primary;

    final confirmIcon = variant == ConfirmVariant.danger
        ? PhosphorIconsRegular.trash
        : PhosphorIconsRegular.check;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header : icône optionnelle + titre
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.space2),
              ],
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          // Message optionnel
          if (message != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              message!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                icon: const PhosphorIcon(
                  PhosphorIconsRegular.x,
                  size: AppTypography.sizeSm,
                ),
                label: Text(cancelLabel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              FilledButton.icon(
                icon: PhosphorIcon(
                  confirmIcon,
                  size: AppTypography.sizeSm,
                ),
                label: Text(confirmLabel),
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: confirmColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
