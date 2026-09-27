// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:intl/intl.dart';

class DayHeaderFormatter {
  DayHeaderFormatter._();

  static final _fullFormatCache = <String, DateFormat>{};
  static DateFormat _fullFormat(String locale) => _fullFormatCache.putIfAbsent(
        locale,
        () => DateFormat('EEEE d MMMM', locale),
      );

  static String format(DateTime date, {DateTime? now, required String locale}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';

    final raw = _fullFormat(locale).format(date);
    return raw[0].toUpperCase() + raw.substring(1);
  }
}
