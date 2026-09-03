// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/color_utils.dart';

/// Retourne le chemin d'asset SVG ou le data URI du logo bancaire du compte,
/// ou null si aucun logo n'est disponible (fallback emoji).
String? resolveBankAssetPath(Account account) {
  if (account.bankCode != 'OTHER' && account.bankCode.isNotEmpty) {
    return 'assets/banks/${account.bankCode.toLowerCase()}.svg';
  }
  if (account.bankCustomLogo != null && account.bankCustomLogo!.isNotEmpty) {
    return account.bankCustomLogo;
  }
  return null;
}

class AccountBankIcon extends StatelessWidget {
  const AccountBankIcon({
    super.key,
    required this.account,
    this.size = 24,
  });

  final Account account;

  /// Diamètre du conteneur extérieur en pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final bgColor = parseHexColor(account.bankBrandColor) ??
        parseHexColor(account.couleur) ??
        colors.iconCircleBg;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor.withValues(alpha: 0.1),
      ),
      alignment: Alignment.center,
      child: _resolveIcon(),
    );
  }

  Widget _resolveIcon() {
    final fallback = Text(
      account.icone,
      style: TextStyle(fontSize: size * 0.55),
    );

    if (account.bankCode != 'OTHER' && account.bankCode.isNotEmpty) {
      return SvgPicture.asset(
        'assets/banks/${account.bankCode.toLowerCase()}.svg',
        width: size * (2 / 3),
        height: size * (2 / 3),
        placeholderBuilder: (_) => fallback,
      );
    }

    if (account.bankCode == 'OTHER' &&
        account.bankCustomLogo != null &&
        account.bankCustomLogo!.isNotEmpty) {
      try {
        final dataUri = account.bankCustomLogo!;
        final commaIndex = dataUri.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(dataUri.substring(commaIndex + 1));
          return Image.memory(
            bytes,
            width: size * (2 / 3),
            height: size * (2 / 3),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => fallback,
          );
        }
      } catch (_) {
        // fall through to emoji fallback
      }
    }

    return fallback;
  }
}
