// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/locale_format.dart';

import '../theme/app_theme_extension.dart';

/// Texte coloré compact affichant la variation d'un montant par rapport
/// à une période précédente (le mois courant).
///
/// Pas un pill — aucun fond, aucune bordure. Simple texte coloré `bodySmall`
/// medium, aligné sur le pattern Angular `.variation-badge`.
///
/// Masqué (`SizedBox.shrink()`) si `delta == 0 && percentage == null`.
///
/// Couleurs :
/// - `delta > 0` → `AppThemeExtension.incomeColor` (vert)
/// - `delta < 0` → `AppThemeExtension.expenseColor` (rouge)
/// - `delta == 0` (avec `percentage`) → `colorScheme.onSurfaceVariant` (text-secondary)
///
/// Le montant fait partie de la phrase traduite
/// ([AppLocalizations.dashboardSummaryMonthVariation]) ; le pourcentage entre
/// parenthèses est ajouté à part, comme côté Angular
/// (`dashboard.html`) — une notation numérique entre parenthèses n'a pas de
/// mot à traduire.
///
/// Exemple (français) : `+150,50 € ce mois (+12,5%)`
///
/// Exemple d'usage :
/// ```dart
/// VariationBadge(
///   delta: 20.0,
///   currency: '€',
///   percentage: 20.0,
/// )
/// ```
class VariationBadge extends StatelessWidget {
  /// Crée un badge de variation textuel coloré.
  const VariationBadge({
    super.key,
    required this.delta,
    this.currency,
    this.percentage,
  });

  /// Variation absolue du montant (ex : `+150.5` ou `-8.0`).
  ///
  /// Si `delta == 0` et [percentage] est `null`, le widget est masqué.
  final num delta;

  /// Symbole monétaire affiché après le montant (défaut : `'€'`).
  final String? currency;

  /// Pourcentage de variation optionnel (ex : `12.5`).
  ///
  /// Si fourni, affiché entre parenthèses avec une décimale.
  final num? percentage;

  @override
  Widget build(BuildContext context) {
    // Masquer si delta == 0 et pas de pourcentage
    if (delta == 0 && percentage == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    final Color color;
    if (delta > 0) {
      color = themeExt.incomeColor;
    } else if (delta < 0) {
      color = themeExt.expenseColor;
    } else {
      color = colorScheme.onSurfaceVariant;
    }

    final locale = intlLocaleFor(Localizations.localeOf(context));
    final amountFormat = NumberFormat.currency(
      locale: locale,
      symbol: currency ?? '€',
      decimalDigits: 2,
    );

    final signe = delta > 0 ? '+' : '';
    final montantFormatted = amountFormat.format(delta);

    final buffer = StringBuffer()
      ..write(l10n.dashboardSummaryMonthVariation('$signe$montantFormatted'));

    if (percentage != null) {
      final pctSigne = percentage! >= 0 ? '+' : '';
      final pctFormat = NumberFormat('#,##0.0', locale);
      final pctFormatted = pctFormat.format(percentage!.abs());
      final pctSignedFormatted = percentage! < 0 ? '-$pctFormatted' : pctFormatted;
      buffer.write(' ($pctSigne$pctSignedFormatted%)');
    }

    return Text(
      buffer.toString(),
      style: textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
