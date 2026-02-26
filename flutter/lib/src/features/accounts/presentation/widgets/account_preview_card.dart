import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/color_utils.dart';

class AccountPreviewCard extends StatelessWidget {
  final String? emoji;
  final String? name;
  final String? colorHex;

  const AccountPreviewCard({
    super.key,
    this.emoji,
    this.name,
    this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final borderColor = parseHexColor(colorHex) ?? colorScheme.outline;
    final hasContent =
        (emoji != null && emoji!.isNotEmpty) ||
        (name != null && name!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space3,
        horizontal: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        spacing: AppSpacing.space3,
        children: [
          if (emoji != null && emoji!.isNotEmpty)
            Text(emoji!, style: const TextStyle(fontSize: 28)),
          Expanded(
            child: Text(
              hasContent && name != null && name!.isNotEmpty
                  ? name!
                  : l10n.accountFormPreviewPlaceholder,
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.medium,
                color: hasContent && name != null && name!.isNotEmpty
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
