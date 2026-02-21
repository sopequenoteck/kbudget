import 'package:intl/intl.dart';

class RelativeDateFormatter {
  RelativeDateFormatter._();

  static DateFormat? _longDateFormatter;

  static DateFormat get _formatter =>
      _longDateFormatter ??= DateFormat.yMMMMd('fr_FR');

  /// Formate une date en texte relatif francais.
  ///
  /// Regles :
  /// - Aujourd'hui, Hier, Demain
  /// - il y a X jours (2-7j)
  /// - il y a X semaine(s) (8-30j)
  /// - Format long (ex: "15 janvier 2026") au-dela
  static String format(DateTime? value) {
    if (value == null) return '';

    final today = DateTime.now();
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
}
