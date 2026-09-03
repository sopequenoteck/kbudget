// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:shimmer/shimmer.dart';

/// Widget ListItem réutilisable pour afficher un élément dans une liste.
///
/// Affiche une icône dans un cercle coloré, un titre, un sous-titre optionnel,
/// une valeur formatée avec couleur dynamique et un sous-titre droit optionnel.
/// Utilisé dans les 4 contextes métier : dashboard, transactions, abonnements, dettes.
///
/// Le widget ne contient aucune logique métier — il reçoit des données pré-formatées.
class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.rightSubtitle,
    this.valueColor,
    this.iconBackgroundColor,
    this.onPressed,
  })  : _isSkeleton = false,
        assert(icon.length > 0, 'icon must not be empty'),
        assert(title.length > 0, 'title must not be empty'),
        assert(value.length > 0, 'value must not be empty');

  /// Constructeur nommé pour l'état de chargement shimmer.
  const ListItem.skeleton({super.key})
      : icon = '',
        title = '',
        value = '',
        subtitle = null,
        rightSubtitle = null,
        valueColor = null,
        iconBackgroundColor = null,
        onPressed = null,
        _isSkeleton = true;

  final String icon;
  final String title;
  final String value;
  final String? subtitle;
  final String? rightSubtitle;
  final Color? valueColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onPressed;
  final bool _isSkeleton;

  @override
  Widget build(BuildContext context) {
    if (_isSkeleton) {
      return _buildSkeleton(context);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space3,
        horizontal: AppSpacing.space4,
      ),
      child: Row(
        spacing: AppSpacing.space3,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Zone icône
          Container(
            width: AppSpacing.space10,
            height: AppSpacing.space10,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppColors.amber100,
              borderRadius: BorderRadius.circular(AppRadius.round),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: AppTypography.sizeLg),
              ),
            ),
          ),
          // Zone contenu central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.space1,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTypography.sizeMd,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: AppTypography.sizeSm,
                      fontWeight: AppTypography.regular,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Zone valeur droite
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.space1,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  fontWeight: AppTypography.semiBold,
                  color: valueColor ?? colorScheme.onSurface,
                ),
              ),
              if (rightSubtitle != null)
                Text(
                  rightSubtitle!,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight: AppTypography.regular,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    final semanticLabel = '$title, $value';

    if (onPressed != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: InkWell(
          onTap: onPressed,
          child: content,
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: content,
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space4,
        ),
        child: Row(
          spacing: AppSpacing.space3,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cercle icône
            Container(
              width: AppSpacing.space10,
              height: AppSpacing.space10,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
            ),
            // Contenu central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.space1,
                children: [
                  Container(
                    width: 120,
                    height: AppTypography.sizeSm,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: AppTypography.sizeXs,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ],
              ),
            ),
            // Valeur droite
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.space1,
              children: [
                Container(
                  width: 60,
                  height: AppTypography.sizeSm,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                Container(
                  width: 40,
                  height: AppTypography.sizeXs,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
