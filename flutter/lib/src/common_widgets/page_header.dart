// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme_extension.dart';

/// Header standardisé pour les sous-pages de l'application.
///
/// Layout : `[← back rond 36×36] [Spacer] [icon optionnel rond 32×32] [titre flex-end bold]`.
/// Pas de trailing actions — suit strictement le pattern Angular `.page-header`.
///
/// Exemple d'usage :
/// ```dart
/// PageHeader(
///   title: 'Mon compte',
///   onBack: () => context.pop(),
///   icon: PhosphorIcon(PhosphorIconsRegular.user, size: 16),
/// )
/// ```
class PageHeader extends StatelessWidget {
  /// Crée un header de sous-page avec flèche retour et titre aligné à droite.
  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.icon,
  });

  /// Titre de la page, affiché à droite avec le style `titleLarge` bold.
  final String title;

  /// Callback déclenché au tap sur le bouton retour rond.
  ///
  /// Si `null`, le bouton est rendu désactivé.
  final VoidCallback? onBack;

  /// Icône métier optionnelle affichée dans un cercle 32×32 `iconCircleBg`,
  /// juste avant le titre.
  ///
  /// Passer directement le widget child (ex : `PhosphorIcon(...)`, `Text('💰')`).
  /// Le wrapper cercle est appliqué automatiquement.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bouton retour rond 36×36
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.transparent,
              ),
              icon: PhosphorIcon(
                PhosphorIconsRegular.arrowLeft,
                size: 20,
                color: colorScheme.onSurface,
              ),
              onPressed: onBack,
            ),
          ),
          const Spacer(),
          // Icône métier optionnelle dans cercle 32×32
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeExt.iconCircleBg,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.round),
                ),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: AppSpacing.space2),
          ],
          // Titre aligné à droite (flex-end)
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
