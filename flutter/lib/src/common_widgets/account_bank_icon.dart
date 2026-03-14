import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_budget/src/domain/models/account.dart';
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
  final double size;

  @override
  Widget build(BuildContext context) {
    final bgColor = parseHexColor(account.bankBrandColor) ??
        parseHexColor(account.couleur) ??
        Colors.grey;

    return Container(
      width: size * 1.5,
      height: size * 1.5,
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
      style: TextStyle(fontSize: size * 0.8),
    );

    if (account.bankCode != 'OTHER' && account.bankCode.isNotEmpty) {
      return SvgPicture.asset(
        'assets/banks/${account.bankCode.toLowerCase()}.svg',
        width: size,
        height: size,
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
            width: size,
            height: size,
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
