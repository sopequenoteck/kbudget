// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/color_utils.dart';

class CategoryListTile extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryListTile({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>();
    final iconColor = parseHexColor(category.couleur);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space4,
        ),
        child: Row(
          spacing: AppSpacing.space3,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Emoji circle
            Container(
              width: AppSpacing.space10,
              height: AppSpacing.space10,
              decoration: BoxDecoration(
                color: iconColor?.withValues(alpha: 0.15) ??
                    themeExt?.iconCircleBg ?? colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
              child: Center(
                child: Text(
                  category.icone,
                  style: const TextStyle(fontSize: AppTypography.sizeLg),
                ),
              ),
            ),
            // Name
            Expanded(
              child: Text(
                category.nom,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Color dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: iconColor ?? colorScheme.outline,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
