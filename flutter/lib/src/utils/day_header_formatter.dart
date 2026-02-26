import 'package:intl/intl.dart';

class DayHeaderFormatter {
  DayHeaderFormatter._();

  static DateFormat? _fullFormatCache;
  static DateFormat get _fullFormat =>
      _fullFormatCache ??= DateFormat('EEEE d MMMM', 'fr');

  static String format(DateTime date, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';

    final raw = _fullFormat.format(date);
    return raw[0].toUpperCase() + raw.substring(1);
  }
}
