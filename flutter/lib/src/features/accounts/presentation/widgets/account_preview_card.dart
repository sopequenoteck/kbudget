// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/color_utils.dart';

class AccountPreviewCard extends StatelessWidget {
  final String? emoji;
  final String? name;
  final String? colorHex;
  final String? bankCode;
  final AccountType? accountType;

  const AccountPreviewCard({
    super.key,
    this.emoji,
    this.name,
    this.colorHex,
    this.bankCode,
    this.accountType,
  });

  String _typeLabel(AppLocalizations l10n) => switch (accountType!) {
    AccountType.courant => l10n.accountTypeCourant.toUpperCase(),
    AccountType.epargne => l10n.accountTypeEpargne.toUpperCase(),
    AccountType.especes => l10n.accountTypeEspeces.toUpperCase(),
  };

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
          if (bankCode != null && bankCode!.isNotEmpty && bankCode != 'OTHER')
            SvgPicture.asset(
              'assets/banks/${bankCode!.toLowerCase()}.svg',
              width: 32,
              height: 32,
            )
          else if (emoji != null && emoji!.isNotEmpty)
            Text(emoji!, style: const TextStyle(fontSize: 28)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
                if (accountType != null)
                  Text(
                    _typeLabel(l10n),
                    style: TextStyle(
                      fontSize: AppTypography.sizeXs,
                      fontWeight: AppTypography.semiBold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
