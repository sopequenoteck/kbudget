// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:intl/intl.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

class RelativeDateFormatter {
  RelativeDateFormatter._();

  static final _longDateFormatters = <String, DateFormat>{};
  static final _shortDateFormatters = <String, DateFormat>{};

  static DateFormat _formatter(String locale) =>
      _longDateFormatters.putIfAbsent(locale, () => DateFormat.yMMMMd(locale));

  static DateFormat _shortFormatter(String locale) => _shortDateFormatters
      .putIfAbsent(locale, () => DateFormat('dd MMM', locale));

  /// Formate une date en texte relatif dans la langue de [l10n].
  ///
  /// Regles :
  /// - Aujourd'hui, Hier, Demain
  /// - il y a X jours (2-7j)
  /// - il y a X semaine(s) (8-30j)
  /// - Format long (ex: "15 janvier 2026") au-dela
  static String format(
    DateTime? value, {
    required String locale,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    if (value == null) return '';

    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(value.year, value.month, value.day);

    final diffDays = todayDate.difference(targetDate).inDays;

    if (diffDays == 0) {
      return l10n.commonValueToday;
    }
    if (diffDays == 1) {
      return l10n.commonValueYesterday;
    }
    if (diffDays == -1) {
      return l10n.commonValueTomorrow;
    }

    if (diffDays >= 2 && diffDays <= 7) {
      return l10n.commonValueDaysAgo(diffDays);
    }

    if (diffDays >= 8 && diffDays <= 30) {
      final weeks = diffDays ~/ 7;
      return l10n.commonValueWeeksAgo(weeks);
    }

    return _formatter(locale).format(value);
  }

  /// Formate une date en texte relatif compact pour les sous-titres d'items.
  ///
  /// - aujourd'hui, hier, demain (minuscule)
  /// - il y a N j. (2-7j passés)
  /// - dans N j. (1-30j futurs)
  /// - dd MMM (au-delà)
  static String formatCompact(
    DateTime value, {
    required String locale,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(value.year, value.month, value.day);

    final diffDays = todayDate.difference(targetDate).inDays;

    if (diffDays == 0) {
      return l10n.commonValueToday.toLowerCase();
    }
    if (diffDays == 1) {
      return l10n.commonValueYesterday.toLowerCase();
    }
    if (diffDays == -1) {
      return l10n.commonValueTomorrow.toLowerCase();
    }

    if (diffDays >= 2 && diffDays <= 7) {
      return l10n.commonValueDaysAgoShort(diffDays);
    }
    if (diffDays < -1 && diffDays >= -30) {
      return l10n.commonValueInDaysShort(-diffDays);
    }

    return _shortFormatter(locale).format(value);
  }
}
