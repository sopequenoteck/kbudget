// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:intl/intl.dart';

class RelativeDateFormatter {
  RelativeDateFormatter._();

  static DateFormat? _longDateFormatter;
  static DateFormat? _shortDateFormatter;

  static DateFormat get _formatter =>
      _longDateFormatter ??= DateFormat.yMMMMd('fr');

  static DateFormat get _shortFormatter =>
      _shortDateFormatter ??= DateFormat('dd MMM', 'fr');

  /// Formate une date en texte relatif francais.
  ///
  /// Regles :
  /// - Aujourd'hui, Hier, Demain
  /// - il y a X jours (2-7j)
  /// - il y a X semaine(s) (8-30j)
  /// - Format long (ex: "15 janvier 2026") au-dela
  static String format(DateTime? value, {DateTime? now}) {
    if (value == null) return '';

    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(value.year, value.month, value.day);

    final diffDays = todayDate.difference(targetDate).inDays;

    if (diffDays == 0) return "Aujourd'hui";
    if (diffDays == 1) return 'Hier';
    if (diffDays == -1) return 'Demain';

    if (diffDays >= 2 && diffDays <= 7) {
      return 'il y a $diffDays jours';
    }

    if (diffDays >= 8 && diffDays <= 30) {
      final weeks = diffDays ~/ 7;
      return 'il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    }

    return _formatter.format(value);
  }

  /// Formate une date en texte relatif compact pour les sous-titres d'items.
  ///
  /// - aujourd'hui, hier, demain (minuscule)
  /// - il y a N j. (2-7j passés)
  /// - dans N j. (1-30j futurs)
  /// - dd MMM (au-delà)
  static String formatCompact(DateTime value, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(value.year, value.month, value.day);

    final diffDays = todayDate.difference(targetDate).inDays;

    if (diffDays == 0) return "aujourd'hui";
    if (diffDays == 1) return 'hier';
    if (diffDays == -1) return 'demain';

    if (diffDays >= 2 && diffDays <= 7) return 'il y a $diffDays j.';
    if (diffDays < -1 && diffDays >= -30) return 'dans ${-diffDays} j.';

    return _shortFormatter.format(value);
  }
}
